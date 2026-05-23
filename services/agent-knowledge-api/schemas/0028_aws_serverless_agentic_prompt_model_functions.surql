DEFINE TABLE serverless_agent_architecture_guidance SCHEMAFULL;
DEFINE FIELD tenant_id ON serverless_agent_architecture_guidance TYPE option<record<tenants>>;
DEFINE FIELD key ON serverless_agent_architecture_guidance TYPE string;
DEFINE FIELD name ON serverless_agent_architecture_guidance TYPE string;
DEFINE FIELD provider ON serverless_agent_architecture_guidance TYPE string DEFAULT 'aws';
DEFINE FIELD guidance_uri ON serverless_agent_architecture_guidance TYPE string;
DEFINE FIELD guidance_version ON serverless_agent_architecture_guidance TYPE string;
DEFINE FIELD guidance_kind ON serverless_agent_architecture_guidance TYPE string DEFAULT 'prompt_agent_model_selection';
DEFINE FIELD principles ON serverless_agent_architecture_guidance TYPE array<object> DEFAULT [];
DEFINE FIELD status ON serverless_agent_architecture_guidance TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON serverless_agent_architecture_guidance TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON serverless_agent_architecture_guidance TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON serverless_agent_architecture_guidance TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ServerlessAgentArchitectureGuidance'];
DEFINE FIELD created_at ON serverless_agent_architecture_guidance TYPE datetime DEFAULT time::now();
DEFINE INDEX serverless_agent_architecture_guidance_key_unique ON serverless_agent_architecture_guidance FIELDS tenant_id, key, guidance_version UNIQUE;

DEFINE TABLE serverless_agent_execution_profiles SCHEMAFULL;
DEFINE FIELD tenant_id ON serverless_agent_execution_profiles TYPE option<record<tenants>>;
DEFINE FIELD key ON serverless_agent_execution_profiles TYPE string;
DEFINE FIELD name ON serverless_agent_execution_profiles TYPE string;
DEFINE FIELD profile_kind ON serverless_agent_execution_profiles TYPE string DEFAULT 'aws_serverless_agent';
DEFINE FIELD task_kind ON serverless_agent_execution_profiles TYPE string;
DEFINE FIELD prompt_strategy ON serverless_agent_execution_profiles TYPE object DEFAULT {};
DEFINE FIELD agent_strategy ON serverless_agent_execution_profiles TYPE object DEFAULT {};
DEFINE FIELD model_strategy ON serverless_agent_execution_profiles TYPE object DEFAULT {};
DEFINE FIELD tool_strategy ON serverless_agent_execution_profiles TYPE object DEFAULT {};
DEFINE FIELD cost_strategy ON serverless_agent_execution_profiles TYPE object DEFAULT {};
DEFINE FIELD performance_strategy ON serverless_agent_execution_profiles TYPE object DEFAULT {};
DEFINE FIELD human_approval_strategy ON serverless_agent_execution_profiles TYPE object DEFAULT {};
DEFINE FIELD enabled ON serverless_agent_execution_profiles TYPE bool DEFAULT true;
DEFINE FIELD source_grounding_refs ON serverless_agent_execution_profiles TYPE array<string> DEFAULT ['aws-prescriptive-guidance:agentic-ai-serverless:prompt-agent-model'];
DEFINE FIELD jsonld_context ON serverless_agent_execution_profiles TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON serverless_agent_execution_profiles TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ServerlessAgentExecutionProfile'];
DEFINE FIELD created_at ON serverless_agent_execution_profiles TYPE datetime DEFAULT time::now();
DEFINE INDEX serverless_agent_execution_profiles_key_unique ON serverless_agent_execution_profiles FIELDS tenant_id, key UNIQUE;

DEFINE TABLE serverless_agent_execution_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON serverless_agent_execution_decisions TYPE option<record<tenants>>;
DEFINE FIELD profile_id ON serverless_agent_execution_decisions TYPE record<serverless_agent_execution_profiles>;
DEFINE FIELD subject_id ON serverless_agent_execution_decisions TYPE string;
DEFINE FIELD agent_id ON serverless_agent_execution_decisions TYPE option<record<agents>>;
DEFINE FIELD task_kind ON serverless_agent_execution_decisions TYPE string;
DEFINE FIELD prompt_execution_run_id ON serverless_agent_execution_decisions TYPE option<record<prompt_execution_runs>>;
DEFINE FIELD llm_selection_run_id ON serverless_agent_execution_decisions TYPE option<record<llm_selection_runs>>;
DEFINE FIELD gated_prompt_execution_run_id ON serverless_agent_execution_decisions TYPE option<record<gated_prompt_execution_runs>>;
DEFINE FIELD selected_prompt_strategy ON serverless_agent_execution_decisions TYPE object DEFAULT {};
DEFINE FIELD selected_agent_strategy ON serverless_agent_execution_decisions TYPE object DEFAULT {};
DEFINE FIELD selected_model_strategy ON serverless_agent_execution_decisions TYPE object DEFAULT {};
DEFINE FIELD selected_tool_strategy ON serverless_agent_execution_decisions TYPE object DEFAULT {};
DEFINE FIELD estimated_cost_usd ON serverless_agent_execution_decisions TYPE number DEFAULT 0;
DEFINE FIELD estimated_latency_ms ON serverless_agent_execution_decisions TYPE number DEFAULT 0;
DEFINE FIELD decision ON serverless_agent_execution_decisions TYPE string;
DEFINE FIELD reason ON serverless_agent_execution_decisions TYPE string;
DEFINE FIELD human_approval_required ON serverless_agent_execution_decisions TYPE bool DEFAULT false;
DEFINE FIELD decision_log_id ON serverless_agent_execution_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD observation_run_id ON serverless_agent_execution_decisions TYPE option<record<observation_runs>>;
DEFINE FIELD jsonld_context ON serverless_agent_execution_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON serverless_agent_execution_decisions TYPE array<string> DEFAULT ['schema:Action', 'agx:ServerlessAgentExecutionDecision'];
DEFINE FIELD created_at ON serverless_agent_execution_decisions TYPE datetime DEFAULT time::now();

UPSERT serverless_agent_architecture_guidance:aws_prompt_agent_model CONTENT {
  tenant_id: NONE,
  key: 'aws_prompt_agent_model',
  name: 'AWS Serverless Agentic AI Prompt, Agent, and Model Guidance',
  provider: 'aws',
  guidance_uri: 'https://docs.aws.amazon.com/prescriptive-guidance/latest/agentic-ai-serverless/prompt-agent-and-model.html',
  guidance_version: 'latest',
  guidance_kind: 'prompt_agent_model_selection',
  principles: [
    { key: 'prompt_first', description: 'Optimize prompt strategy before runtime execution.' },
    { key: 'agent_fit', description: 'Select agent pattern based on task complexity, tool needs and orchestration needs.' },
    { key: 'model_fit', description: 'Select model based on quality, latency, cost, context window and modality requirements.' },
    { key: 'serverless_fit', description: 'Prefer scalable, event-driven and bounded execution profiles for agentic workloads.' },
    { key: 'human_approval', description: 'Require approval for high-risk or high-cost decisions when policy demands it.' }
  ],
  status: 'active',
  source_grounding_refs: ['aws-prescriptive-guidance:agentic-ai-serverless:prompt-agent-model']
};

UPSERT serverless_agent_execution_profiles:default CONTENT {
  tenant_id: NONE,
  key: 'default',
  name: 'Default AWS-Grounded Serverless Agent Execution Profile',
  profile_kind: 'aws_serverless_agent',
  task_kind: '*',
  prompt_strategy: { require_two_step_prompt_execution: true, require_context_completeness: true, prefer_prompt_library: true },
  agent_strategy: { orchestration: 'bounded_agent', allow_multi_agent: true, require_observability: true },
  model_strategy: { selection_policy_key: 'default', optimize_for: ['quality', 'cost', 'latency', 'reliability', 'trust'] },
  tool_strategy: { enforce_tool_configuration: true, require_authorization_api_grant: true },
  cost_strategy: { require_cost_estimate: true, max_default_estimated_cost_usd: 0.25 },
  performance_strategy: { require_latency_estimate: true, prefer_serverless_bounded_execution: true },
  human_approval_strategy: { require_for_high_risk: true, require_for_high_cost: true },
  enabled: true,
  source_grounding_refs: ['aws-prescriptive-guidance:agentic-ai-serverless:prompt-agent-model']
};

DEFINE FUNCTION fn::select_serverless_agent_execution_profile($tenant_id, $task_kind, $key) {
  LET $tenant_specific = SELECT * FROM serverless_agent_execution_profiles WHERE tenant_id = $tenant_id AND key = $key AND (task_kind = $task_kind OR task_kind = '*') AND enabled = true ORDER BY task_kind DESC LIMIT 1;
  IF count($tenant_specific) > 0 THEN { RETURN $tenant_specific[0]; };
  LET $global_specific = SELECT * FROM serverless_agent_execution_profiles WHERE tenant_id = NONE AND key = $key AND (task_kind = $task_kind OR task_kind = '*') AND enabled = true ORDER BY task_kind DESC LIMIT 1;
  IF count($global_specific) > 0 THEN { RETURN $global_specific[0]; };
  RETURN serverless_agent_execution_profiles:default;
};

DEFINE FUNCTION fn::create_serverless_agent_execution_profile($tenant_id, $key, $name, $task_kind, $prompt_strategy, $agent_strategy, $model_strategy, $tool_strategy, $cost_strategy, $performance_strategy, $human_approval_strategy) {
  RETURN CREATE serverless_agent_execution_profiles CONTENT {
    tenant_id: $tenant_id,
    key: $key,
    name: $name,
    profile_kind: 'aws_serverless_agent',
    task_kind: $task_kind,
    prompt_strategy: $prompt_strategy,
    agent_strategy: $agent_strategy,
    model_strategy: $model_strategy,
    tool_strategy: $tool_strategy,
    cost_strategy: $cost_strategy,
    performance_strategy: $performance_strategy,
    human_approval_strategy: $human_approval_strategy,
    enabled: true,
    source_grounding_refs: ['aws-prescriptive-guidance:agentic-ai-serverless:prompt-agent-model'],
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::plan_serverless_agent_execution($tenant_id, $agent_id, $subject_id, $task_kind, $risk_level, $original_prompt, $base_context, $profile_key, $constraints, $input_tokens_estimate, $output_tokens_estimate) {
  LET $profile = fn::select_serverless_agent_execution_profile($tenant_id, $task_kind, $profile_key);
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'serverless_agent_execution_planning', 'agx:aws-serverless-agent-prompt-model-v1');
  LET $gated = IF $profile.prompt_strategy.require_context_completeness THEN fn::start_gated_prompt_execution($tenant_id, $agent_id, $subject_id, NONE, NONE, $task_kind, $risk_level, $original_prompt, $base_context, 'default', $constraints) ELSE NONE END;
  LET $llm_run = fn::start_llm_selection($tenant_id, $agent_id, $subject_id, $task_kind, $risk_level, $profile.model_strategy.selection_policy_key, $input_tokens_estimate, $output_tokens_estimate, $constraints);
  LET $human_required = ($profile.human_approval_strategy.require_for_high_risk AND $risk_level IN ['high', 'critical']) OR ($profile.human_approval_strategy.require_for_high_cost AND $profile.cost_strategy.max_default_estimated_cost_usd != NONE AND 0 >= $profile.cost_strategy.max_default_estimated_cost_usd);
  LET $decision_log = fn::log_decision_context($tenant_id, 'serverless_agent_execution_plan', $subject_id, string::concat($agent_id), NONE, NONE, { task_kind: $task_kind, risk_level: $risk_level, original_prompt: $original_prompt }, {}, {}, {}, {}, {}, {}, { profile_id: $profile.id, profile: $profile }, $constraints, { source_guidance: 'https://docs.aws.amazon.com/prescriptive-guidance/latest/agentic-ai-serverless/prompt-agent-and-model.html', required_steps: ['context_gate', 'prompt_optimization', 'model_selection', 'tool_authorization', 'observability'] }, [{ strategy: 'prompt_first' }, { strategy: 'agent_fit' }, { strategy: 'model_fit' }], { profile_id: $profile.id, gated_prompt_execution_run_id: IF $gated = NONE THEN NONE ELSE $gated[0].id END, llm_selection_run_id: $llm_run.id }, [], 'serverless_agent_execution_planned', { method: 'agx:aws-serverless-agent-prompt-model-v1', guidance_ref: 'aws-prescriptive-guidance:agentic-ai-serverless:prompt-agent-model' }, [$profile.id], $obs.id, [], $human_required);
  LET $record = CREATE serverless_agent_execution_decisions CONTENT { tenant_id: $tenant_id, profile_id: $profile.id, subject_id: $subject_id, agent_id: $agent_id, task_kind: $task_kind, llm_selection_run_id: $llm_run.id, gated_prompt_execution_run_id: IF $gated = NONE THEN NONE ELSE $gated[0].id END, selected_prompt_strategy: $profile.prompt_strategy, selected_agent_strategy: $profile.agent_strategy, selected_model_strategy: $profile.model_strategy, selected_tool_strategy: $profile.tool_strategy, estimated_cost_usd: 0, estimated_latency_ms: 0, decision: 'planned', reason: 'aws_grounded_serverless_agent_execution_plan_created', human_approval_required: $human_required, decision_log_id: $decision_log.id, observation_run_id: $obs.id, created_at: time::now() };
  fn::add_observation_step($obs.id, 1, 'plan_serverless_agent_execution', { task_kind: $task_kind, risk_level: $risk_level, profile_id: $profile.id }, { decision_id: $record.id, llm_selection_run_id: $llm_run.id, gated_prompt_execution_run_id: IF $gated = NONE THEN NONE ELSE $gated[0].id END }, 'completed', 'agx:aws-serverless-agent-prompt-model-v1');
  RETURN $record;
};

DEFINE FUNCTION fn::require_serverless_agent_execution_plan($decision_id) {
  LET $decision = SELECT * FROM $decision_id;
  IF count($decision) = 0 THEN { THROW 'serverless_agent_execution_plan_required'; };
  IF $decision[0].decision != 'planned' THEN { THROW 'serverless_agent_execution_plan_not_valid'; };
  RETURN true;
};
