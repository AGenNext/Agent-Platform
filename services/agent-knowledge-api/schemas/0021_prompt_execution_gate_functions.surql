DEFINE TABLE gated_prompt_execution_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON gated_prompt_execution_runs TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON gated_prompt_execution_runs TYPE option<record<agents>>;
DEFINE FIELD subject_id ON gated_prompt_execution_runs TYPE string;
DEFINE FIELD conversation_id ON gated_prompt_execution_runs TYPE option<string>;
DEFINE FIELD message_id ON gated_prompt_execution_runs TYPE option<string>;
DEFINE FIELD task_kind ON gated_prompt_execution_runs TYPE string;
DEFINE FIELD risk_level ON gated_prompt_execution_runs TYPE string DEFAULT 'medium';
DEFINE FIELD original_prompt ON gated_prompt_execution_runs TYPE string;
DEFINE FIELD base_context ON gated_prompt_execution_runs TYPE object DEFAULT {};
DEFINE FIELD execution_context_id ON gated_prompt_execution_runs TYPE option<record<execution_contexts>>;
DEFINE FIELD prompt_execution_run_id ON gated_prompt_execution_runs TYPE option<record<prompt_execution_runs>>;
DEFINE FIELD status ON gated_prompt_execution_runs TYPE string DEFAULT 'context_checking';
DEFINE FIELD missing_fields ON gated_prompt_execution_runs TYPE array<string> DEFAULT [];
DEFINE FIELD required_user_action ON gated_prompt_execution_runs TYPE option<string>;
DEFINE FIELD constraints ON gated_prompt_execution_runs TYPE array<object> DEFAULT [];
DEFINE FIELD jsonld_context ON gated_prompt_execution_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON gated_prompt_execution_runs TYPE array<string> DEFAULT ['schema:Action', 'agx:GatedPromptExecutionRun'];
DEFINE FIELD created_at ON gated_prompt_execution_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON gated_prompt_execution_runs TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::start_gated_prompt_execution($tenant_id, $agent_id, $subject_id, $conversation_id, $message_id, $task_kind, $risk_level, $original_prompt, $base_context, $policy_key, $constraints) {
  LET $prepared = fn::prepare_prompt_context_before_execution($tenant_id, $subject_id, $conversation_id, $message_id, $task_kind, $base_context, $constraints);
  LET $gated = CREATE gated_prompt_execution_runs CONTENT {
    tenant_id: $tenant_id,
    agent_id: $agent_id,
    subject_id: $subject_id,
    conversation_id: $conversation_id,
    message_id: $message_id,
    task_kind: $task_kind,
    risk_level: $risk_level,
    original_prompt: $original_prompt,
    base_context: $base_context,
    execution_context_id: $prepared.execution_context_id,
    status: IF $prepared.ready_to_execute THEN 'context_ready' ELSE IF $prepared.requires_user_context THEN 'waiting_for_missing_context' ELSE 'waiting_for_user_confirmation' END END,
    missing_fields: IF $prepared.missing_fields = NONE THEN [] ELSE $prepared.missing_fields END,
    required_user_action: IF $prepared.ready_to_execute THEN NONE ELSE IF $prepared.requires_user_context THEN 'provide_missing_context' ELSE 'confirm_context' END END,
    constraints: $constraints,
    created_at: time::now(),
    updated_at: time::now()
  };

  IF $prepared.ready_to_execute THEN {
    fn::require_complete_execution_context($prepared.execution_context_id);
    LET $prompt_run = fn::start_prompt_execution($tenant_id, $agent_id, $subject_id, $task_kind, $risk_level, $original_prompt, $policy_key, $constraints);
    UPDATE $gated.id SET prompt_execution_run_id = $prompt_run.id, status = 'prompt_optimization_started', updated_at = time::now();
  };

  RETURN SELECT * FROM $gated.id;
};

DEFINE FUNCTION fn::continue_gated_prompt_execution_after_context($gated_prompt_execution_run_id, $human_actor_id, $approval_status, $response_text, $structured_response, $policy_key) {
  LET $gated = SELECT * FROM $gated_prompt_execution_run_id;
  IF count($gated) = 0 THEN { THROW 'gated_prompt_execution_not_found'; };
  IF $gated[0].execution_context_id = NONE THEN { THROW 'execution_context_required'; };

  LET $confirmed = fn::confirm_execution_context($gated[0].tenant_id, $gated[0].execution_context_id, $human_actor_id, $approval_status, $response_text, $structured_response);
  fn::require_complete_execution_context($confirmed.id);
  LET $prompt_run = fn::start_prompt_execution($gated[0].tenant_id, $gated[0].agent_id, $gated[0].subject_id, $gated[0].task_kind, $gated[0].risk_level, $gated[0].original_prompt, $policy_key, $gated[0].constraints);
  UPDATE $gated_prompt_execution_run_id SET prompt_execution_run_id = $prompt_run.id, status = 'prompt_optimization_started', missing_fields = [], required_user_action = NONE, updated_at = time::now();
  RETURN SELECT * FROM $gated_prompt_execution_run_id;
};

DEFINE FUNCTION fn::execute_gated_optimized_prompt($gated_prompt_execution_run_id, $llm_selection_run_id, $execution_output, $actual_cost_usd, $quality_score, $success) {
  LET $gated = SELECT * FROM $gated_prompt_execution_run_id;
  IF count($gated) = 0 THEN { THROW 'gated_prompt_execution_not_found'; };
  IF $gated[0].execution_context_id = NONE THEN { THROW 'execution_context_required'; };
  IF $gated[0].prompt_execution_run_id = NONE THEN { THROW 'prompt_execution_run_required'; };
  fn::require_complete_execution_context($gated[0].execution_context_id);
  LET $result = fn::execute_optimized_prompt_step($gated[0].prompt_execution_run_id, $llm_selection_run_id, $execution_output, $actual_cost_usd, $quality_score, $success);
  UPDATE $gated_prompt_execution_run_id SET status = IF $success THEN 'completed' ELSE 'failed' END, updated_at = time::now();
  RETURN $result;
};
