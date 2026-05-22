DEFINE TABLE prompt_libraries SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_libraries TYPE option<record<tenants>>;
DEFINE FIELD key ON prompt_libraries TYPE string;
DEFINE FIELD name ON prompt_libraries TYPE string;
DEFINE FIELD description ON prompt_libraries TYPE string;
DEFINE FIELD owner_id ON prompt_libraries TYPE string;
DEFINE FIELD enabled ON prompt_libraries TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON prompt_libraries TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON prompt_libraries TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:PromptLibrary'];
DEFINE FIELD created_at ON prompt_libraries TYPE datetime DEFAULT time::now();
DEFINE INDEX prompt_libraries_key_unique ON prompt_libraries FIELDS tenant_id, key UNIQUE;

DEFINE TABLE prompt_templates SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_templates TYPE option<record<tenants>>;
DEFINE FIELD library_id ON prompt_templates TYPE record<prompt_libraries>;
DEFINE FIELD key ON prompt_templates TYPE string;
DEFINE FIELD name ON prompt_templates TYPE string;
DEFINE FIELD task_kind ON prompt_templates TYPE string;
DEFINE FIELD template_text ON prompt_templates TYPE string;
DEFINE FIELD version ON prompt_templates TYPE string DEFAULT '1.0.0';
DEFINE FIELD status ON prompt_templates TYPE string DEFAULT 'active';
DEFINE FIELD quality_score ON prompt_templates TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD cost_score ON prompt_templates TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD output_score ON prompt_templates TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD reliability_score ON prompt_templates TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD constraints ON prompt_templates TYPE array<object> DEFAULT [];
DEFINE FIELD source_grounding_refs ON prompt_templates TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON prompt_templates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON prompt_templates TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:PromptTemplate'];
DEFINE FIELD created_at ON prompt_templates TYPE datetime DEFAULT time::now();
DEFINE INDEX prompt_templates_key_version_unique ON prompt_templates FIELDS tenant_id, key, version UNIQUE;

DEFINE TABLE prompt_optimization_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_optimization_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON prompt_optimization_policies TYPE string;
DEFINE FIELD name ON prompt_optimization_policies TYPE string;
DEFINE FIELD prefer_library_prompt ON prompt_optimization_policies TYPE bool DEFAULT true;
DEFINE FIELD store_optimized_prompt ON prompt_optimization_policies TYPE bool DEFAULT true;
DEFINE FIELD max_prompt_tokens ON prompt_optimization_policies TYPE int DEFAULT 4000;
DEFINE FIELD min_quality_score ON prompt_optimization_policies TYPE number DEFAULT 0.70 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD max_estimated_cost_usd ON prompt_optimization_policies TYPE number DEFAULT 0.25;
DEFINE FIELD require_human_approval ON prompt_optimization_policies TYPE bool DEFAULT false;
DEFINE FIELD require_human_approval_for_high_risk ON prompt_optimization_policies TYPE bool DEFAULT true;
DEFINE FIELD weights ON prompt_optimization_policies TYPE object DEFAULT { quality: 0.30, cost: 0.20, output: 0.20, reliability: 0.15, specificity: 0.10, constraint: 0.05 };
DEFINE FIELD enabled ON prompt_optimization_policies TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON prompt_optimization_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON prompt_optimization_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:PromptOptimizationPolicy'];
DEFINE FIELD created_at ON prompt_optimization_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX prompt_optimization_policies_key_unique ON prompt_optimization_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE prompt_execution_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_execution_runs TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON prompt_execution_runs TYPE option<record<agents>>;
DEFINE FIELD subject_id ON prompt_execution_runs TYPE string;
DEFINE FIELD task_kind ON prompt_execution_runs TYPE string;
DEFINE FIELD original_prompt ON prompt_execution_runs TYPE string;
DEFINE FIELD optimized_prompt ON prompt_execution_runs TYPE option<string>;
DEFINE FIELD selected_template_id ON prompt_execution_runs TYPE option<record<prompt_templates>>;
DEFINE FIELD selected_template_version ON prompt_execution_runs TYPE option<string>;
DEFINE FIELD policy_id ON prompt_execution_runs TYPE record<prompt_optimization_policies>;
DEFINE FIELD llm_selection_run_id ON prompt_execution_runs TYPE option<record<llm_selection_runs>>;
DEFINE FIELD status ON prompt_execution_runs TYPE string DEFAULT 'optimizing';
DEFINE FIELD risk_level ON prompt_execution_runs TYPE string DEFAULT 'medium';
DEFINE FIELD constraints ON prompt_execution_runs TYPE array<object> DEFAULT [];
DEFINE FIELD optimization_score ON prompt_execution_runs TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD estimated_cost_usd ON prompt_execution_runs TYPE option<number>;
DEFINE FIELD human_approval_required ON prompt_execution_runs TYPE bool DEFAULT false;
DEFINE FIELD human_response_status ON prompt_execution_runs TYPE string DEFAULT 'not_required';
DEFINE FIELD decision_log_id ON prompt_execution_runs TYPE option<record<decision_context_logs>>;
DEFINE FIELD observation_run_id ON prompt_execution_runs TYPE option<record<observation_runs>>;
DEFINE FIELD execution_output ON prompt_execution_runs TYPE object DEFAULT {};
DEFINE FIELD jsonld_context ON prompt_execution_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON prompt_execution_runs TYPE array<string> DEFAULT ['schema:Action', 'agx:PromptExecutionRun'];
DEFINE FIELD created_at ON prompt_execution_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON prompt_execution_runs TYPE option<datetime>;

DEFINE TABLE prompt_versions SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_versions TYPE option<record<tenants>>;
DEFINE FIELD prompt_execution_run_id ON prompt_versions TYPE record<prompt_execution_runs>;
DEFINE FIELD template_id ON prompt_versions TYPE option<record<prompt_templates>>;
DEFINE FIELD prompt_text ON prompt_versions TYPE string;
DEFINE FIELD version ON prompt_versions TYPE string;
DEFINE FIELD version_kind ON prompt_versions TYPE string;
DEFINE FIELD quality_score ON prompt_versions TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD cost_score ON prompt_versions TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD output_score ON prompt_versions TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD reliability_score ON prompt_versions TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD specificity_score ON prompt_versions TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD constraint_score ON prompt_versions TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD final_score ON prompt_versions TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD estimated_tokens ON prompt_versions TYPE int DEFAULT 0;
DEFINE FIELD estimated_cost_usd ON prompt_versions TYPE number DEFAULT 0;
DEFINE FIELD jsonld_context ON prompt_versions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON prompt_versions TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:PromptVersion'];
DEFINE FIELD created_at ON prompt_versions TYPE datetime DEFAULT time::now();

UPSERT prompt_optimization_policies:default CONTENT {
  tenant_id: NONE,
  key: 'default',
  name: 'Default Two Step Prompt Optimization Policy',
  prefer_library_prompt: true,
  store_optimized_prompt: true,
  max_prompt_tokens: 4000,
  min_quality_score: 0.70,
  max_estimated_cost_usd: 0.25,
  require_human_approval: false,
  require_human_approval_for_high_risk: true,
  weights: { quality: 0.30, cost: 0.20, output: 0.20, reliability: 0.15, specificity: 0.10, constraint: 0.05 },
  enabled: true
};

DEFINE FUNCTION fn::select_prompt_optimization_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM prompt_optimization_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM prompt_optimization_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN prompt_optimization_policies:default;
};

DEFINE FUNCTION fn::create_prompt_library($tenant_id, $key, $name, $description, $owner_id) {
  LET $existing = SELECT * FROM prompt_libraries WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE prompt_libraries CONTENT { tenant_id: $tenant_id, key: $key, name: $name, description: $description, owner_id: $owner_id, enabled: true, created_at: time::now() };
};

DEFINE FUNCTION fn::store_prompt_template($tenant_id, $library_id, $key, $name, $task_kind, $template_text, $version, $quality_score, $cost_score, $output_score, $reliability_score, $constraints, $source_grounding_refs) {
  LET $library = SELECT * FROM $library_id;
  IF count($library) = 0 THEN { THROW 'prompt_library_not_found'; };
  RETURN CREATE prompt_templates CONTENT { tenant_id: $tenant_id, library_id: $library_id, key: $key, name: $name, task_kind: $task_kind, template_text: $template_text, version: $version, status: 'active', quality_score: fn::clamp01($quality_score), cost_score: fn::clamp01($cost_score), output_score: fn::clamp01($output_score), reliability_score: fn::clamp01($reliability_score), constraints: $constraints, source_grounding_refs: $source_grounding_refs, created_at: time::now() };
};

DEFINE FUNCTION fn::estimate_prompt_tokens($prompt_text) {
  RETURN math::ceil(string::len($prompt_text) / 4);
};

DEFINE FUNCTION fn::prompt_final_score($policy, $quality, $cost, $output, $reliability, $specificity, $constraint) {
  RETURN fn::clamp01(($policy.weights.quality * $quality) + ($policy.weights.cost * $cost) + ($policy.weights.output * $output) + ($policy.weights.reliability * $reliability) + ($policy.weights.specificity * $specificity) + ($policy.weights.constraint * $constraint));
};

DEFINE FUNCTION fn::find_best_prompt_template($tenant_id, $task_kind, $constraints) {
  LET $templates = SELECT * FROM prompt_templates WHERE (tenant_id = $tenant_id OR tenant_id = NONE) AND task_kind = $task_kind AND status = 'active' ORDER BY quality_score DESC, reliability_score DESC, cost_score DESC LIMIT 1;
  RETURN IF count($templates) = 0 THEN NONE ELSE $templates[0] END;
};

DEFINE FUNCTION fn::start_prompt_execution($tenant_id, $agent_id, $subject_id, $task_kind, $risk_level, $original_prompt, $policy_key, $constraints) {
  LET $policy = fn::select_prompt_optimization_policy($tenant_id, $policy_key);
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'two_step_prompt_execution', 'agx:prompt-two-step-v1');
  LET $run = CREATE prompt_execution_runs CONTENT { tenant_id: $tenant_id, agent_id: $agent_id, subject_id: $subject_id, task_kind: $task_kind, original_prompt: $original_prompt, policy_id: $policy.id, status: 'optimizing', risk_level: $risk_level, constraints: $constraints, observation_run_id: $obs.id, created_at: time::now() };
  fn::add_observation_step($obs.id, 1, 'start_prompt_execution', { task_kind: $task_kind, risk_level: $risk_level, original_prompt_tokens: fn::estimate_prompt_tokens($original_prompt), constraints: $constraints }, { prompt_execution_run_id: $run.id, policy_id: $policy.id }, 'completed', 'agx:prompt-two-step-v1');
  RETURN $run;
};

DEFINE FUNCTION fn::optimize_prompt_step($prompt_execution_run_id, $candidate_optimized_prompt, $quality_score, $output_score, $specificity_score, $constraint_score, $estimated_cost_usd) {
  LET $run = SELECT * FROM $prompt_execution_run_id;
  IF count($run) = 0 THEN { THROW 'prompt_execution_run_not_found'; };
  IF $run[0].status != 'optimizing' THEN { THROW 'prompt_execution_not_optimizing'; };
  LET $policy = SELECT * FROM $run[0].policy_id;
  LET $template = IF $policy[0].prefer_library_prompt THEN fn::find_best_prompt_template($run[0].tenant_id, $run[0].task_kind, $run[0].constraints) ELSE NONE END;
  LET $selected_prompt = IF $template = NONE THEN $candidate_optimized_prompt ELSE $template.template_text END;
  LET $tokens = fn::estimate_prompt_tokens($selected_prompt);
  IF $tokens > $policy[0].max_prompt_tokens THEN { THROW 'optimized_prompt_exceeds_token_budget'; };
  LET $cost_score = IF $policy[0].max_estimated_cost_usd = 0 THEN 0 ELSE fn::clamp01(1 - ($estimated_cost_usd / $policy[0].max_estimated_cost_usd)) END;
  LET $reliability = IF $template = NONE THEN 0.5 ELSE $template.reliability_score END;
  LET $quality = IF $template = NONE THEN fn::clamp01($quality_score) ELSE math::max([fn::clamp01($quality_score), $template.quality_score]) END;
  LET $output = IF $template = NONE THEN fn::clamp01($output_score) ELSE math::max([fn::clamp01($output_score), $template.output_score]) END;
  LET $final = fn::prompt_final_score($policy[0], $quality, $cost_score, $output, $reliability, fn::clamp01($specificity_score), fn::clamp01($constraint_score));
  IF $final < $policy[0].min_quality_score THEN { THROW 'optimized_prompt_quality_too_low'; };
  LET $version = string::concat('v', string::concat(time::unix(), ''));
  LET $prompt_version = CREATE prompt_versions CONTENT { tenant_id: $run[0].tenant_id, prompt_execution_run_id: $prompt_execution_run_id, template_id: IF $template = NONE THEN NONE ELSE $template.id END, prompt_text: $selected_prompt, version: $version, version_kind: IF $template = NONE THEN 'optimized' ELSE 'library_selected' END, quality_score: $quality, cost_score: $cost_score, output_score: $output, reliability_score: $reliability, specificity_score: fn::clamp01($specificity_score), constraint_score: fn::clamp01($constraint_score), final_score: $final, estimated_tokens: $tokens, estimated_cost_usd: $estimated_cost_usd, created_at: time::now() };
  LET $human_required = $policy[0].require_human_approval OR ($policy[0].require_human_approval_for_high_risk AND $run[0].risk_level IN ['high', 'critical']);
  LET $decision_log = fn::log_decision_context($run[0].tenant_id, 'prompt_optimization', $run[0].subject_id, string::concat($run[0].agent_id), NONE, NONE, { original_prompt: $run[0].original_prompt, task_kind: $run[0].task_kind }, { selected_template_id: IF $template = NONE THEN NONE ELSE $template.id END }, {}, {}, {}, {}, {}, { policy_id: $run[0].policy_id, policy: $policy[0] }, $run[0].constraints, { max_prompt_tokens: $policy[0].max_prompt_tokens, min_quality_score: $policy[0].min_quality_score, max_estimated_cost_usd: $policy[0].max_estimated_cost_usd }, [{ kind: 'candidate_optimized_prompt', prompt: $candidate_optimized_prompt }, { kind: 'library_template', template_id: IF $template = NONE THEN NONE ELSE $template.id END }], { prompt_version_id: $prompt_version.id, final_score: $final, estimated_tokens: $tokens, estimated_cost_usd: $estimated_cost_usd }, [], 'prompt_optimized', { method: 'agx:prompt-two-step-v1', version: $version, final_score: $final, selected_from_library: $template != NONE }, [$prompt_version.id], $run[0].observation_run_id, [], $human_required);
  UPDATE $prompt_execution_run_id SET optimized_prompt = $selected_prompt, selected_template_id = IF $template = NONE THEN NONE ELSE $template.id END, selected_template_version = IF $template = NONE THEN NONE ELSE $template.version END, status = IF $human_required THEN 'pending_human_approval' ELSE 'ready_to_execute' END, optimization_score = $final, estimated_cost_usd = $estimated_cost_usd, human_approval_required = $human_required, human_response_status = IF $human_required THEN 'pending' ELSE 'not_required' END, decision_log_id = $decision_log.id;
  fn::add_observation_step($run[0].observation_run_id, 2, 'optimize_prompt_step', { candidate_tokens: fn::estimate_prompt_tokens($candidate_optimized_prompt), policy_id: $run[0].policy_id }, { prompt_version_id: $prompt_version.id, selected_from_library: $template != NONE, final_score: $final, status: IF $human_required THEN 'pending_human_approval' ELSE 'ready_to_execute' END }, 'completed', 'agx:prompt-two-step-v1');
  RETURN SELECT * FROM $prompt_execution_run_id;
};

DEFINE FUNCTION fn::approve_prompt_optimization($prompt_execution_run_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $run = SELECT * FROM $prompt_execution_run_id;
  IF count($run) = 0 THEN { THROW 'prompt_execution_run_not_found'; };
  IF !$run[0].human_approval_required THEN { THROW 'human_approval_not_required'; };
  LET $response = fn::record_human_decision_response($run[0].tenant_id, $run[0].decision_log_id, NONE, NONE, $human_actor_id, 'prompt_optimization_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $prompt_execution_run_id SET status = IF $approval_status = 'approved' THEN 'ready_to_execute' ELSE 'rejected' END, human_response_status = $approval_status;
  fn::add_observation_step($run[0].observation_run_id, 3, 'human_prompt_optimization_response', { human_actor_id: $human_actor_id }, { approval_status: $approval_status, response_id: $response.id }, 'completed', 'agx:prompt-two-step-v1');
  RETURN SELECT * FROM $prompt_execution_run_id;
};

DEFINE FUNCTION fn::execute_optimized_prompt_step($prompt_execution_run_id, $llm_selection_run_id, $execution_output, $actual_cost_usd, $quality_score, $success) {
  LET $run = SELECT * FROM $prompt_execution_run_id;
  IF count($run) = 0 THEN { THROW 'prompt_execution_run_not_found'; };
  IF $run[0].status != 'ready_to_execute' THEN { THROW 'prompt_not_ready_to_execute'; };
  fn::require_decision_context_log($run[0].decision_log_id);
  LET $llm_run = IF $llm_selection_run_id = NONE THEN [] ELSE SELECT * FROM $llm_selection_run_id END;
  IF $llm_selection_run_id != NONE AND count($llm_run) = 0 THEN { THROW 'llm_selection_run_not_found'; };
  IF $llm_selection_run_id != NONE AND $llm_run[0].status != 'completed' THEN { THROW 'llm_selection_not_completed'; };
  UPDATE $prompt_execution_run_id SET status = IF $success THEN 'completed' ELSE 'failed' END, llm_selection_run_id = $llm_selection_run_id, execution_output = $execution_output, completed_at = time::now();
  fn::add_observation_step($run[0].observation_run_id, 4, 'execute_optimized_prompt_step', { prompt_tokens: fn::estimate_prompt_tokens($run[0].optimized_prompt), llm_selection_run_id: $llm_selection_run_id }, { success: $success, actual_cost_usd: $actual_cost_usd, quality_score: $quality_score }, IF $success THEN 'completed' ELSE 'failed' END, 'agx:prompt-two-step-v1');
  fn::record_reliability_event($run[0].tenant_id, $run[0].subject_id, 'prompt_execution', IF $success THEN 'success' ELSE 'failure' END, IF $quality_score = NONE THEN 0.5 ELSE $quality_score END, NONE, string::concat($prompt_execution_run_id), { actual_cost_usd: $actual_cost_usd, task_kind: $run[0].task_kind, optimization_score: $run[0].optimization_score });
  fn::finish_observation_run($run[0].observation_run_id, IF $success THEN 'completed' ELSE 'failed' END, { success: $success, actual_cost_usd: $actual_cost_usd, quality_score: $quality_score });
  RETURN SELECT * FROM $prompt_execution_run_id;
};
