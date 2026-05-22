DEFINE TABLE decision_context_logs SCHEMAFULL;
DEFINE FIELD tenant_id ON decision_context_logs TYPE option<record<tenants>>;
DEFINE FIELD decision_id ON decision_context_logs TYPE string;
DEFINE FIELD decision_kind ON decision_context_logs TYPE string;
DEFINE FIELD subject_id ON decision_context_logs TYPE string;
DEFINE FIELD actor_id ON decision_context_logs TYPE string;
DEFINE FIELD conversation_id ON decision_context_logs TYPE option<string>;
DEFINE FIELD message_id ON decision_context_logs TYPE option<string>;
DEFINE FIELD parent_decision_id ON decision_context_logs TYPE option<record<decision_context_logs>>;
DEFINE FIELD input_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD retrieved_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD graph_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD memory_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD trust_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD reliability_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD evaluation_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD policy_context ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD constraints ON decision_context_logs TYPE array<object> DEFAULT [];
DEFINE FIELD constraint_documentation ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD alternatives_considered ON decision_context_logs TYPE array<object> DEFAULT [];
DEFINE FIELD selected_option ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD rejected_options ON decision_context_logs TYPE array<object> DEFAULT [];
DEFINE FIELD decision ON decision_context_logs TYPE string;
DEFINE FIELD rationale ON decision_context_logs TYPE object DEFAULT {};
DEFINE FIELD evidence_ids ON decision_context_logs TYPE array<record> DEFAULT [];
DEFINE FIELD observation_run_id ON decision_context_logs TYPE option<record<observation_runs>>;
DEFINE FIELD observation_step_ids ON decision_context_logs TYPE array<record<observation_steps>> DEFAULT [];
DEFINE FIELD human_response_required ON decision_context_logs TYPE bool DEFAULT false;
DEFINE FIELD human_response_status ON decision_context_logs TYPE string DEFAULT 'not_required';
DEFINE FIELD human_response_ids ON decision_context_logs TYPE array<record<human_decision_responses>> DEFAULT [];
DEFINE FIELD immutable ON decision_context_logs TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON decision_context_logs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON decision_context_logs TYPE array<string> DEFAULT ['schema:Action', 'agx:DecisionContextLog'];
DEFINE FIELD created_at ON decision_context_logs TYPE datetime DEFAULT time::now();
DEFINE INDEX decision_context_logs_decision_id_unique ON decision_context_logs FIELDS decision_id UNIQUE;

DEFINE TABLE human_decision_responses SCHEMAFULL;
DEFINE FIELD tenant_id ON human_decision_responses TYPE option<record<tenants>>;
DEFINE FIELD decision_log_id ON human_decision_responses TYPE record<decision_context_logs>;
DEFINE FIELD conversation_id ON human_decision_responses TYPE option<string>;
DEFINE FIELD message_id ON human_decision_responses TYPE option<string>;
DEFINE FIELD human_actor_id ON human_decision_responses TYPE string;
DEFINE FIELD response_kind ON human_decision_responses TYPE string;
DEFINE FIELD response_text ON human_decision_responses TYPE string;
DEFINE FIELD structured_response ON human_decision_responses TYPE object DEFAULT {};
DEFINE FIELD accepted_constraints ON human_decision_responses TYPE array<string> DEFAULT [];
DEFINE FIELD rejected_constraints ON human_decision_responses TYPE array<string> DEFAULT [];
DEFINE FIELD requested_changes ON human_decision_responses TYPE array<object> DEFAULT [];
DEFINE FIELD approval_status ON human_decision_responses TYPE string;
DEFINE FIELD observed_at ON human_decision_responses TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON human_decision_responses TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON human_decision_responses TYPE array<string> DEFAULT ['schema:ReplyAction', 'agx:HumanDecisionResponse'];
DEFINE FIELD created_at ON human_decision_responses TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::log_decision_context($tenant_id, $decision_kind, $subject_id, $actor_id, $conversation_id, $message_id, $input_context, $retrieved_context, $graph_context, $memory_context, $trust_context, $reliability_context, $evaluation_context, $policy_context, $constraints, $constraint_documentation, $alternatives_considered, $selected_option, $rejected_options, $decision, $rationale, $evidence_ids, $observation_run_id, $observation_step_ids, $human_response_required) {
  IF count($constraints) = 0 THEN { THROW 'decision_constraints_required'; };
  IF $constraint_documentation = {} THEN { THROW 'constraint_documentation_required'; };
  IF $decision = NONE OR string::len($decision) = 0 THEN { THROW 'decision_required'; };
  IF $rationale = {} THEN { THROW 'decision_rationale_required'; };

  LET $log = CREATE decision_context_logs CONTENT {
    tenant_id: $tenant_id,
    decision_id: rand::uuid(),
    decision_kind: $decision_kind,
    subject_id: $subject_id,
    actor_id: $actor_id,
    conversation_id: $conversation_id,
    message_id: $message_id,
    input_context: $input_context,
    retrieved_context: $retrieved_context,
    graph_context: $graph_context,
    memory_context: $memory_context,
    trust_context: $trust_context,
    reliability_context: $reliability_context,
    evaluation_context: $evaluation_context,
    policy_context: $policy_context,
    constraints: $constraints,
    constraint_documentation: $constraint_documentation,
    alternatives_considered: $alternatives_considered,
    selected_option: $selected_option,
    rejected_options: $rejected_options,
    decision: $decision,
    rationale: $rationale,
    evidence_ids: $evidence_ids,
    observation_run_id: $observation_run_id,
    observation_step_ids: $observation_step_ids,
    human_response_required: $human_response_required,
    human_response_status: IF $human_response_required THEN 'pending' ELSE 'not_required' END,
    immutable: true,
    created_at: time::now()
  };

  IF $observation_run_id != NONE THEN {
    fn::add_observation_step($observation_run_id, 950, 'decision_context_logged', { decision_kind: $decision_kind, subject_id: $subject_id }, { decision_log_id: $log.id, decision: $decision, human_response_required: $human_response_required }, 'completed', 'agx:decision-context-log-v1');
  };

  CREATE audit_logs CONTENT {
    tenant_id: $tenant_id,
    actor_id: $actor_id,
    action: 'decision_context_logged',
    resource_type: 'decision_context_logs',
    resource_id: string::concat($log.id),
    metadata: { decision_kind: $decision_kind, decision: $decision, human_response_required: $human_response_required },
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:AuditEvent'],
    time: { observed_at: time::now() },
    created_at: time::now()
  };

  RETURN $log;
};

DEFINE FUNCTION fn::record_human_decision_response($tenant_id, $decision_log_id, $conversation_id, $message_id, $human_actor_id, $response_kind, $response_text, $structured_response, $accepted_constraints, $rejected_constraints, $requested_changes, $approval_status) {
  LET $decision_log = SELECT * FROM $decision_log_id;
  IF count($decision_log) = 0 THEN { THROW 'decision_log_not_found'; };
  IF $approval_status NOT IN ['approved', 'rejected', 'changes_requested', 'acknowledged'] THEN { THROW 'invalid_human_approval_status'; };

  LET $response = CREATE human_decision_responses CONTENT {
    tenant_id: $tenant_id,
    decision_log_id: $decision_log_id,
    conversation_id: $conversation_id,
    message_id: $message_id,
    human_actor_id: $human_actor_id,
    response_kind: $response_kind,
    response_text: $response_text,
    structured_response: $structured_response,
    accepted_constraints: $accepted_constraints,
    rejected_constraints: $rejected_constraints,
    requested_changes: $requested_changes,
    approval_status: $approval_status,
    observed_at: time::now(),
    created_at: time::now()
  };

  UPDATE $decision_log_id SET
    human_response_status = $approval_status,
    human_response_ids += $response.id;

  CREATE audit_logs CONTENT {
    tenant_id: $tenant_id,
    actor_id: $human_actor_id,
    action: 'human_decision_response_recorded',
    resource_type: 'human_decision_responses',
    resource_id: string::concat($response.id),
    metadata: { decision_log_id: $decision_log_id, approval_status: $approval_status },
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:AuditEvent'],
    time: { observed_at: time::now() },
    created_at: time::now()
  };

  RETURN $response;
};

DEFINE FUNCTION fn::require_decision_context_log($decision_log_id) {
  LET $log = SELECT * FROM $decision_log_id;
  IF count($log) = 0 THEN { THROW 'decision_context_log_required'; };
  IF count($log[0].constraints) = 0 THEN { THROW 'decision_constraints_required'; };
  IF $log[0].constraint_documentation = {} THEN { THROW 'constraint_documentation_required'; };
  IF $log[0].human_response_required AND $log[0].human_response_status = 'pending' THEN { THROW 'human_response_pending'; };
  RETURN true;
};
