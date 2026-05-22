DEFINE TABLE prompt_context_requirements SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_context_requirements TYPE option<record<tenants>>;
DEFINE FIELD key ON prompt_context_requirements TYPE string;
DEFINE FIELD task_kind ON prompt_context_requirements TYPE string;
DEFINE FIELD required_fields ON prompt_context_requirements TYPE array<string> DEFAULT ['environment', 'tool', 'actions_requested', 'expected_outcome', 'target_audience', 'necessary_data'];
DEFINE FIELD min_completeness_score ON prompt_context_requirements TYPE number DEFAULT 0.85 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD require_user_confirmation ON prompt_context_requirements TYPE bool DEFAULT true;
DEFINE FIELD check_memory_before_asking ON prompt_context_requirements TYPE bool DEFAULT true;
DEFINE FIELD enabled ON prompt_context_requirements TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON prompt_context_requirements TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON prompt_context_requirements TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:PromptContextRequirement'];
DEFINE FIELD created_at ON prompt_context_requirements TYPE datetime DEFAULT time::now();
DEFINE INDEX prompt_context_requirements_key_unique ON prompt_context_requirements FIELDS tenant_id, key UNIQUE;

DEFINE TABLE execution_contexts SCHEMAFULL;
DEFINE FIELD tenant_id ON execution_contexts TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON execution_contexts TYPE string;
DEFINE FIELD conversation_id ON execution_contexts TYPE option<string>;
DEFINE FIELD message_id ON execution_contexts TYPE option<string>;
DEFINE FIELD task_kind ON execution_contexts TYPE string;
DEFINE FIELD environment ON execution_contexts TYPE option<object>;
DEFINE FIELD tool ON execution_contexts TYPE option<object>;
DEFINE FIELD actions_requested ON execution_contexts TYPE option<array<object>>;
DEFINE FIELD expected_outcome ON execution_contexts TYPE option<object>;
DEFINE FIELD target_audience ON execution_contexts TYPE option<object>;
DEFINE FIELD necessary_data ON execution_contexts TYPE option<object>;
DEFINE FIELD constraints ON execution_contexts TYPE array<object> DEFAULT [];
DEFINE FIELD source ON execution_contexts TYPE string DEFAULT 'user_or_memory';
DEFINE FIELD confirmed_by_user ON execution_contexts TYPE bool DEFAULT false;
DEFINE FIELD confirmation_response_id ON execution_contexts TYPE option<record<human_decision_responses>>;
DEFINE FIELD completeness_score ON execution_contexts TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD missing_fields ON execution_contexts TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON execution_contexts TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON execution_contexts TYPE array<string> DEFAULT ['schema:Action', 'agx:ExecutionContext'];
DEFINE FIELD created_at ON execution_contexts TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON execution_contexts TYPE datetime DEFAULT time::now();

DEFINE TABLE memory_nodes SCHEMAFULL;
DEFINE FIELD tenant_id ON memory_nodes TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON memory_nodes TYPE string;
DEFINE FIELD memory_kind ON memory_nodes TYPE string;
DEFINE FIELD content ON memory_nodes TYPE object;
DEFINE FIELD content_summary ON memory_nodes TYPE string;
DEFINE FIELD context_fields ON memory_nodes TYPE array<string> DEFAULT [];
DEFINE FIELD importance_score ON memory_nodes TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD trust_score ON memory_nodes TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD reliability_score ON memory_nodes TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD recency_score ON memory_nodes TYPE number DEFAULT 1 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD gnn_embedding_ref ON memory_nodes TYPE option<string>;
DEFINE FIELD gnn_rank_score ON memory_nodes TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD source_ref ON memory_nodes TYPE option<record>;
DEFINE FIELD jsonld_context ON memory_nodes TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON memory_nodes TYPE array<string> DEFAULT ['schema:Thing', 'agx:MemoryNode'];
DEFINE FIELD created_at ON memory_nodes TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON memory_nodes TYPE datetime DEFAULT time::now();

DEFINE TABLE memory_edges SCHEMAFULL TYPE RELATION IN memory_nodes OUT memory_nodes;
DEFINE FIELD tenant_id ON memory_edges TYPE option<record<tenants>>;
DEFINE FIELD relation_kind ON memory_edges TYPE string;
DEFINE FIELD weight ON memory_edges TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD evidence_ids ON memory_edges TYPE array<record> DEFAULT [];
DEFINE FIELD created_at ON memory_edges TYPE datetime DEFAULT time::now();

DEFINE TABLE memory_retrieval_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON memory_retrieval_runs TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON memory_retrieval_runs TYPE string;
DEFINE FIELD task_kind ON memory_retrieval_runs TYPE string;
DEFINE FIELD query_context ON memory_retrieval_runs TYPE object DEFAULT {};
DEFINE FIELD required_fields ON memory_retrieval_runs TYPE array<string> DEFAULT [];
DEFINE FIELD status ON memory_retrieval_runs TYPE string DEFAULT 'running';
DEFINE FIELD selected_memory_ids ON memory_retrieval_runs TYPE array<record<memory_nodes>> DEFAULT [];
DEFINE FIELD observation_run_id ON memory_retrieval_runs TYPE option<record<observation_runs>>;
DEFINE FIELD jsonld_context ON memory_retrieval_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON memory_retrieval_runs TYPE array<string> DEFAULT ['schema:SearchAction', 'agx:MemoryRetrievalRun'];
DEFINE FIELD created_at ON memory_retrieval_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON memory_retrieval_runs TYPE option<datetime>;

UPSERT prompt_context_requirements:default CONTENT {
  tenant_id: NONE,
  key: 'default',
  task_kind: '*',
  required_fields: ['environment', 'tool', 'actions_requested', 'expected_outcome', 'target_audience', 'necessary_data'],
  min_completeness_score: 0.85,
  require_user_confirmation: true,
  check_memory_before_asking: true,
  enabled: true
};

DEFINE FUNCTION fn::select_prompt_context_requirement($tenant_id, $task_kind) {
  LET $tenant_specific = SELECT * FROM prompt_context_requirements WHERE tenant_id = $tenant_id AND task_kind = $task_kind AND enabled = true LIMIT 1;
  IF count($tenant_specific) > 0 THEN { RETURN $tenant_specific[0]; };
  LET $global_specific = SELECT * FROM prompt_context_requirements WHERE tenant_id = NONE AND task_kind = $task_kind AND enabled = true LIMIT 1;
  IF count($global_specific) > 0 THEN { RETURN $global_specific[0]; };
  RETURN prompt_context_requirements:default;
};

DEFINE FUNCTION fn::context_field_present($context, $field) {
  RETURN IF $field = 'environment' THEN $context.environment != NONE ELSE IF $field = 'tool' THEN $context.tool != NONE ELSE IF $field = 'actions_requested' THEN $context.actions_requested != NONE AND count($context.actions_requested) > 0 ELSE IF $field = 'expected_outcome' THEN $context.expected_outcome != NONE ELSE IF $field = 'target_audience' THEN $context.target_audience != NONE ELSE IF $field = 'necessary_data' THEN $context.necessary_data != NONE ELSE false END END END END END END;
};

DEFINE FUNCTION fn::compute_context_completeness($context, $required_fields) {
  LET $present = [];
  LET $missing = [];
  FOR $field IN $required_fields {
    IF fn::context_field_present($context, $field) THEN { LET $present += [$field]; } ELSE { LET $missing += [$field]; };
  };
  LET $score = IF count($required_fields) = 0 THEN 1 ELSE fn::clamp01(count($present) / count($required_fields)) END;
  RETURN { score: $score, present_fields: $present, missing_fields: $missing };
};

DEFINE FUNCTION fn::store_memory_node($tenant_id, $subject_id, $memory_kind, $content, $content_summary, $context_fields, $importance_score, $trust_score, $reliability_score, $source_ref) {
  RETURN CREATE memory_nodes CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    memory_kind: $memory_kind,
    content: $content,
    content_summary: $content_summary,
    context_fields: $context_fields,
    importance_score: fn::clamp01($importance_score),
    trust_score: fn::clamp01($trust_score),
    reliability_score: fn::clamp01($reliability_score),
    recency_score: 1,
    gnn_rank_score: fn::clamp01((0.30 * $importance_score) + (0.25 * $trust_score) + (0.25 * $reliability_score) + 0.20),
    source_ref: $source_ref,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::link_memory_nodes($tenant_id, $from_memory_id, $to_memory_id, $relation_kind, $weight, $evidence_ids) {
  LET $from = SELECT * FROM $from_memory_id;
  LET $to = SELECT * FROM $to_memory_id;
  IF count($from) = 0 OR count($to) = 0 THEN { THROW 'memory_node_not_found'; };
  IF $from[0].tenant_id != $tenant_id OR $to[0].tenant_id != $tenant_id THEN { THROW 'cross_tenant_memory_edge_rejected'; };
  RETURN RELATE $from_memory_id->memory_edges->$to_memory_id SET tenant_id = $tenant_id, relation_kind = $relation_kind, weight = fn::clamp01($weight), evidence_ids = $evidence_ids, created_at = time::now();
};

DEFINE FUNCTION fn::gnn_rank_memory($memory, $required_fields) {
  LET $coverage = IF count($required_fields) = 0 THEN 1 ELSE fn::clamp01(count(array::intersect($memory.context_fields, $required_fields)) / count($required_fields)) END;
  RETURN fn::clamp01((0.28 * $memory.importance_score) + (0.22 * $memory.trust_score) + (0.22 * $memory.reliability_score) + (0.18 * $coverage) + (0.10 * $memory.recency_score));
};

DEFINE FUNCTION fn::retrieve_memory_for_context($tenant_id, $subject_id, $task_kind, $query_context, $required_fields, $limit) {
  LET $obs = fn::create_observation_run($tenant_id, NONE, 'memory_retrieval', 'agx:memory-gnn-context-v1');
  LET $run = CREATE memory_retrieval_runs CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, task_kind: $task_kind, query_context: $query_context, required_fields: $required_fields, status: 'running', observation_run_id: $obs.id, created_at: time::now() };
  LET $memories = SELECT *, fn::gnn_rank_memory($this, $required_fields) AS dynamic_rank FROM memory_nodes WHERE subject_id = $subject_id AND (tenant_id = $tenant_id OR tenant_id = NONE) ORDER BY dynamic_rank DESC LIMIT $limit;
  UPDATE $run.id SET status = 'completed', selected_memory_ids = $memories[*].id, completed_at = time::now();
  fn::add_observation_step($obs.id, 1, 'retrieve_memory_for_context', { subject_id: $subject_id, task_kind: $task_kind, required_fields: $required_fields }, { selected_memory_ids: $memories[*].id, selected_count: count($memories) }, 'completed', 'agx:memory-gnn-context-v1');
  fn::finish_observation_run($obs.id, 'completed', { selected_count: count($memories) });
  RETURN { run_id: $run.id, memories: $memories };
};

DEFINE FUNCTION fn::merge_context_from_memory($base_context, $memories) {
  LET $ctx = $base_context;
  FOR $memory IN $memories {
    IF $ctx.environment = NONE AND $memory.content.environment != NONE THEN { LET $ctx.environment = $memory.content.environment; };
    IF $ctx.tool = NONE AND $memory.content.tool != NONE THEN { LET $ctx.tool = $memory.content.tool; };
    IF ($ctx.actions_requested = NONE OR count($ctx.actions_requested) = 0) AND $memory.content.actions_requested != NONE THEN { LET $ctx.actions_requested = $memory.content.actions_requested; };
    IF $ctx.expected_outcome = NONE AND $memory.content.expected_outcome != NONE THEN { LET $ctx.expected_outcome = $memory.content.expected_outcome; };
    IF $ctx.target_audience = NONE AND $memory.content.target_audience != NONE THEN { LET $ctx.target_audience = $memory.content.target_audience; };
    IF $ctx.necessary_data = NONE AND $memory.content.necessary_data != NONE THEN { LET $ctx.necessary_data = $memory.content.necessary_data; };
  };
  RETURN $ctx;
};

DEFINE FUNCTION fn::create_execution_context($tenant_id, $subject_id, $conversation_id, $message_id, $task_kind, $environment, $tool, $actions_requested, $expected_outcome, $target_audience, $necessary_data, $constraints, $source, $confirmed_by_user) {
  LET $requirement = fn::select_prompt_context_requirement($tenant_id, $task_kind);
  LET $context = { environment: $environment, tool: $tool, actions_requested: $actions_requested, expected_outcome: $expected_outcome, target_audience: $target_audience, necessary_data: $necessary_data };
  LET $completeness = fn::compute_context_completeness($context, $requirement.required_fields);
  RETURN CREATE execution_contexts CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, conversation_id: $conversation_id, message_id: $message_id, task_kind: $task_kind, environment: $environment, tool: $tool, actions_requested: $actions_requested, expected_outcome: $expected_outcome, target_audience: $target_audience, necessary_data: $necessary_data, constraints: $constraints, source: $source, confirmed_by_user: $confirmed_by_user, completeness_score: $completeness.score, missing_fields: $completeness.missing_fields, created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::prepare_prompt_context_before_execution($tenant_id, $subject_id, $conversation_id, $message_id, $task_kind, $base_context, $constraints) {
  LET $requirement = fn::select_prompt_context_requirement($tenant_id, $task_kind);
  LET $initial = fn::compute_context_completeness($base_context, $requirement.required_fields);
  LET $memory_result = IF $requirement.check_memory_before_asking THEN fn::retrieve_memory_for_context($tenant_id, $subject_id, $task_kind, $base_context, $initial.missing_fields, 10) ELSE { memories: [] } END;
  LET $merged = fn::merge_context_from_memory($base_context, $memory_result.memories);
  LET $final = fn::compute_context_completeness($merged, $requirement.required_fields);
  LET $context = CREATE execution_contexts CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, conversation_id: $conversation_id, message_id: $message_id, task_kind: $task_kind, environment: $merged.environment, tool: $merged.tool, actions_requested: $merged.actions_requested, expected_outcome: $merged.expected_outcome, target_audience: $merged.target_audience, necessary_data: $merged.necessary_data, constraints: $constraints, source: IF count($memory_result.memories) > 0 THEN 'user_plus_memory' ELSE 'user' END, confirmed_by_user: false, completeness_score: $final.score, missing_fields: $final.missing_fields, created_at: time::now(), updated_at: time::now() };
  IF $final.score < $requirement.min_completeness_score THEN {
    RETURN { ready_to_execute: false, requires_user_context: true, execution_context_id: $context.id, missing_fields: $final.missing_fields, completeness_score: $final.score, message: 'context_incomplete_after_memory_lookup' };
  };
  IF $requirement.require_user_confirmation AND !$context.confirmed_by_user THEN {
    RETURN { ready_to_execute: false, requires_user_confirmation: true, execution_context_id: $context.id, missing_fields: $final.missing_fields, completeness_score: $final.score, merged_context: $merged, message: 'context_complete_but_user_confirmation_required' };
  };
  RETURN { ready_to_execute: true, execution_context_id: $context.id, completeness_score: $final.score, merged_context: $merged };
};

DEFINE FUNCTION fn::confirm_execution_context($tenant_id, $execution_context_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $ctx = SELECT * FROM $execution_context_id;
  IF count($ctx) = 0 THEN { THROW 'execution_context_not_found'; };
  IF $approval_status != 'approved' THEN { THROW 'execution_context_not_approved'; };
  LET $decision_log = fn::log_decision_context($tenant_id, 'execution_context_confirmation', $ctx[0].subject_id, $human_actor_id, $ctx[0].conversation_id, $ctx[0].message_id, { execution_context_id: $execution_context_id }, {}, {}, { execution_context: $ctx[0] }, {}, {}, {}, {}, $ctx[0].constraints, { required_context_fields: $ctx[0].missing_fields, completeness_score: $ctx[0].completeness_score }, [{ execution_context_id: $execution_context_id }], { approved_context_id: $execution_context_id }, [], 'execution_context_confirmed', { response_text: $response_text, structured_response: $structured_response }, [$execution_context_id], NONE, [], false);
  LET $response = fn::record_human_decision_response($tenant_id, $decision_log.id, $ctx[0].conversation_id, $ctx[0].message_id, $human_actor_id, 'execution_context_confirmation', $response_text, $structured_response, [], [], [], 'approved');
  UPDATE $execution_context_id SET confirmed_by_user = true, confirmation_response_id = $response.id, updated_at = time::now();
  fn::store_memory_node($tenant_id, $ctx[0].subject_id, 'execution_context', { environment: $ctx[0].environment, tool: $ctx[0].tool, actions_requested: $ctx[0].actions_requested, expected_outcome: $ctx[0].expected_outcome, target_audience: $ctx[0].target_audience, necessary_data: $ctx[0].necessary_data, constraints: $ctx[0].constraints }, string::concat('Confirmed execution context for ', $ctx[0].task_kind), ['environment', 'tool', 'actions_requested', 'expected_outcome', 'target_audience', 'necessary_data'], 0.85, 0.90, 0.80, $execution_context_id);
  RETURN SELECT * FROM $execution_context_id;
};

DEFINE FUNCTION fn::require_complete_execution_context($execution_context_id) {
  LET $ctx = SELECT * FROM $execution_context_id;
  IF count($ctx) = 0 THEN { THROW 'execution_context_required'; };
  LET $requirement = fn::select_prompt_context_requirement($ctx[0].tenant_id, $ctx[0].task_kind);
  IF $ctx[0].completeness_score < $requirement.min_completeness_score THEN { THROW 'execution_context_incomplete'; };
  IF $requirement.require_user_confirmation AND !$ctx[0].confirmed_by_user THEN { THROW 'execution_context_user_confirmation_required'; };
  RETURN true;
};
