DEFINE TABLE llm_providers SCHEMAFULL;
DEFINE FIELD tenant_id ON llm_providers TYPE option<record<tenants>>;
DEFINE FIELD key ON llm_providers TYPE string;
DEFINE FIELD name ON llm_providers TYPE string;
DEFINE FIELD provider_kind ON llm_providers TYPE string;
DEFINE FIELD base_url ON llm_providers TYPE option<string>;
DEFINE FIELD enabled ON llm_providers TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON llm_providers TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON llm_providers TYPE array<string> DEFAULT ['schema:Organization', 'agx:LLMProvider'];
DEFINE FIELD created_at ON llm_providers TYPE datetime DEFAULT time::now();
DEFINE INDEX llm_providers_key_unique ON llm_providers FIELDS tenant_id, key UNIQUE;

DEFINE TABLE llm_models SCHEMAFULL;
DEFINE FIELD tenant_id ON llm_models TYPE option<record<tenants>>;
DEFINE FIELD provider_id ON llm_models TYPE record<llm_providers>;
DEFINE FIELD key ON llm_models TYPE string;
DEFINE FIELD model_name ON llm_models TYPE string;
DEFINE FIELD modality ON llm_models TYPE array<string> DEFAULT ['text'];
DEFINE FIELD context_window_tokens ON llm_models TYPE int DEFAULT 0;
DEFINE FIELD max_output_tokens ON llm_models TYPE int DEFAULT 0;
DEFINE FIELD input_cost_per_1m_tokens ON llm_models TYPE number DEFAULT 0;
DEFINE FIELD output_cost_per_1m_tokens ON llm_models TYPE number DEFAULT 0;
DEFINE FIELD baseline_quality_score ON llm_models TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD baseline_latency_ms ON llm_models TYPE number DEFAULT 1000;
DEFINE FIELD enabled ON llm_models TYPE bool DEFAULT true;
DEFINE FIELD requires_human_approval ON llm_models TYPE bool DEFAULT false;
DEFINE FIELD jsonld_context ON llm_models TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON llm_models TYPE array<string> DEFAULT ['schema:SoftwareApplication', 'agx:LLMModel'];
DEFINE FIELD created_at ON llm_models TYPE datetime DEFAULT time::now();
DEFINE INDEX llm_models_key_unique ON llm_models FIELDS tenant_id, key UNIQUE;

DEFINE TABLE llm_selection_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON llm_selection_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON llm_selection_policies TYPE string;
DEFINE FIELD name ON llm_selection_policies TYPE string;
DEFINE FIELD max_estimated_cost_usd ON llm_selection_policies TYPE number DEFAULT 1;
DEFINE FIELD max_latency_ms ON llm_selection_policies TYPE number DEFAULT 30000;
DEFINE FIELD min_quality_score ON llm_selection_policies TYPE number DEFAULT 0.70 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_trust_score ON llm_selection_policies TYPE number DEFAULT 0.60 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_reliability_score ON llm_selection_policies TYPE number DEFAULT 0.60 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD require_human_approval ON llm_selection_policies TYPE bool DEFAULT false;
DEFINE FIELD require_human_approval_above_cost_usd ON llm_selection_policies TYPE option<number>;
DEFINE FIELD require_human_approval_for_high_risk ON llm_selection_policies TYPE bool DEFAULT true;
DEFINE FIELD weights ON llm_selection_policies TYPE object DEFAULT { quality: 0.30, cost: 0.20, latency: 0.15, trust: 0.15, reliability: 0.15, context_fit: 0.05 };
DEFINE FIELD enabled ON llm_selection_policies TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON llm_selection_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON llm_selection_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:LLMSelectionPolicy'];
DEFINE FIELD created_at ON llm_selection_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX llm_selection_policies_key_unique ON llm_selection_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE llm_selection_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON llm_selection_runs TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON llm_selection_runs TYPE option<record<agents>>;
DEFINE FIELD subject_id ON llm_selection_runs TYPE string;
DEFINE FIELD task_kind ON llm_selection_runs TYPE string;
DEFINE FIELD risk_level ON llm_selection_runs TYPE string DEFAULT 'medium';
DEFINE FIELD policy_id ON llm_selection_runs TYPE record<llm_selection_policies>;
DEFINE FIELD input_tokens_estimate ON llm_selection_runs TYPE int DEFAULT 0;
DEFINE FIELD output_tokens_estimate ON llm_selection_runs TYPE int DEFAULT 0;
DEFINE FIELD constraints ON llm_selection_runs TYPE array<object> DEFAULT [];
DEFINE FIELD status ON llm_selection_runs TYPE string DEFAULT 'running';
DEFINE FIELD selected_candidate_id ON llm_selection_runs TYPE option<record<llm_selection_candidates>>;
DEFINE FIELD selected_model_id ON llm_selection_runs TYPE option<record<llm_models>>;
DEFINE FIELD final_estimated_cost_usd ON llm_selection_runs TYPE option<number>;
DEFINE FIELD human_approval_required ON llm_selection_runs TYPE bool DEFAULT false;
DEFINE FIELD human_response_status ON llm_selection_runs TYPE string DEFAULT 'not_required';
DEFINE FIELD decision_log_id ON llm_selection_runs TYPE option<record<decision_context_logs>>;
DEFINE FIELD observation_run_id ON llm_selection_runs TYPE option<record<observation_runs>>;
DEFINE FIELD jsonld_context ON llm_selection_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON llm_selection_runs TYPE array<string> DEFAULT ['schema:Action', 'agx:LLMSelectionRun'];
DEFINE FIELD created_at ON llm_selection_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON llm_selection_runs TYPE option<datetime>;

DEFINE TABLE llm_selection_candidates SCHEMAFULL;
DEFINE FIELD tenant_id ON llm_selection_candidates TYPE option<record<tenants>>;
DEFINE FIELD selection_run_id ON llm_selection_candidates TYPE record<llm_selection_runs>;
DEFINE FIELD model_id ON llm_selection_candidates TYPE record<llm_models>;
DEFINE FIELD quality_score ON llm_selection_candidates TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD trust_score ON llm_selection_candidates TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD reliability_score ON llm_selection_candidates TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD latency_score ON llm_selection_candidates TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD cost_score ON llm_selection_candidates TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD context_fit_score ON llm_selection_candidates TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD estimated_cost_usd ON llm_selection_candidates TYPE number DEFAULT 0;
DEFINE FIELD estimated_latency_ms ON llm_selection_candidates TYPE number DEFAULT 0;
DEFINE FIELD final_score ON llm_selection_candidates TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD selected ON llm_selection_candidates TYPE bool DEFAULT false;
DEFINE FIELD rejection_reason ON llm_selection_candidates TYPE option<string>;
DEFINE FIELD explanation ON llm_selection_candidates TYPE object DEFAULT {};
DEFINE FIELD jsonld_context ON llm_selection_candidates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON llm_selection_candidates TYPE array<string> DEFAULT ['schema:PropertyValue', 'agx:LLMSelectionCandidate'];
DEFINE FIELD created_at ON llm_selection_candidates TYPE datetime DEFAULT time::now();

DEFINE TABLE llm_usage_events SCHEMAFULL;
DEFINE FIELD tenant_id ON llm_usage_events TYPE option<record<tenants>>;
DEFINE FIELD selection_run_id ON llm_usage_events TYPE option<record<llm_selection_runs>>;
DEFINE FIELD model_id ON llm_usage_events TYPE record<llm_models>;
DEFINE FIELD subject_id ON llm_usage_events TYPE string;
DEFINE FIELD task_kind ON llm_usage_events TYPE string;
DEFINE FIELD input_tokens ON llm_usage_events TYPE int DEFAULT 0;
DEFINE FIELD output_tokens ON llm_usage_events TYPE int DEFAULT 0;
DEFINE FIELD actual_cost_usd ON llm_usage_events TYPE number DEFAULT 0;
DEFINE FIELD latency_ms ON llm_usage_events TYPE number DEFAULT 0;
DEFINE FIELD success ON llm_usage_events TYPE bool DEFAULT true;
DEFINE FIELD quality_score ON llm_usage_events TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD observed_at ON llm_usage_events TYPE datetime DEFAULT time::now();
DEFINE FIELD payload ON llm_usage_events TYPE object DEFAULT {};
DEFINE FIELD jsonld_context ON llm_usage_events TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON llm_usage_events TYPE array<string> DEFAULT ['schema:Action', 'agx:LLMUsageEvent'];

UPSERT llm_selection_policies:default CONTENT {
  tenant_id: NONE,
  key: 'default',
  name: 'Default LLM Selection Policy',
  max_estimated_cost_usd: 1,
  max_latency_ms: 30000,
  min_quality_score: 0.70,
  min_trust_score: 0.60,
  min_reliability_score: 0.60,
  require_human_approval: false,
  require_human_approval_above_cost_usd: 0.25,
  require_human_approval_for_high_risk: true,
  weights: { quality: 0.30, cost: 0.20, latency: 0.15, trust: 0.15, reliability: 0.15, context_fit: 0.05 },
  enabled: true
};

DEFINE FUNCTION fn::select_llm_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM llm_selection_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM llm_selection_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN llm_selection_policies:default;
};

DEFINE FUNCTION fn::register_llm_provider($tenant_id, $key, $name, $provider_kind, $base_url) {
  LET $existing = SELECT * FROM llm_providers WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE llm_providers CONTENT { tenant_id: $tenant_id, key: $key, name: $name, provider_kind: $provider_kind, base_url: $base_url, enabled: true, created_at: time::now() };
};

DEFINE FUNCTION fn::register_llm_model($tenant_id, $provider_id, $key, $model_name, $modality, $context_window_tokens, $max_output_tokens, $input_cost_per_1m_tokens, $output_cost_per_1m_tokens, $baseline_quality_score, $baseline_latency_ms, $requires_human_approval) {
  LET $provider = SELECT * FROM $provider_id;
  IF count($provider) = 0 THEN { THROW 'llm_provider_not_found'; };
  LET $existing = SELECT * FROM llm_models WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE llm_models CONTENT {
    tenant_id: $tenant_id,
    provider_id: $provider_id,
    key: $key,
    model_name: $model_name,
    modality: $modality,
    context_window_tokens: $context_window_tokens,
    max_output_tokens: $max_output_tokens,
    input_cost_per_1m_tokens: $input_cost_per_1m_tokens,
    output_cost_per_1m_tokens: $output_cost_per_1m_tokens,
    baseline_quality_score: fn::clamp01($baseline_quality_score),
    baseline_latency_ms: $baseline_latency_ms,
    enabled: true,
    requires_human_approval: $requires_human_approval,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::estimate_llm_cost($model, $input_tokens, $output_tokens) {
  RETURN (($input_tokens / 1000000) * $model.input_cost_per_1m_tokens) + (($output_tokens / 1000000) * $model.output_cost_per_1m_tokens);
};

DEFINE FUNCTION fn::start_llm_selection($tenant_id, $agent_id, $subject_id, $task_kind, $risk_level, $policy_key, $input_tokens_estimate, $output_tokens_estimate, $constraints) {
  LET $policy = fn::select_llm_policy($tenant_id, $policy_key);
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'llm_selection', 'agx:llm-selection-v1');
  LET $run = CREATE llm_selection_runs CONTENT {
    tenant_id: $tenant_id,
    agent_id: $agent_id,
    subject_id: $subject_id,
    task_kind: $task_kind,
    risk_level: $risk_level,
    policy_id: $policy.id,
    input_tokens_estimate: $input_tokens_estimate,
    output_tokens_estimate: $output_tokens_estimate,
    constraints: $constraints,
    status: 'running',
    observation_run_id: $obs.id,
    created_at: time::now()
  };
  fn::add_observation_step($obs.id, 1, 'start_llm_selection', { task_kind: $task_kind, risk_level: $risk_level, constraints: $constraints }, { selection_run_id: $run.id, policy_id: $policy.id }, 'completed', 'agx:llm-selection-v1');
  RETURN $run;
};

DEFINE FUNCTION fn::score_llm_candidate($tenant_id, $selection_run_id, $model_id) {
  LET $run = SELECT * FROM $selection_run_id;
  IF count($run) = 0 THEN { THROW 'llm_selection_run_not_found'; };
  LET $policy = SELECT * FROM $run[0].policy_id;
  LET $model = SELECT * FROM $model_id;
  IF count($model) = 0 THEN { THROW 'llm_model_not_found'; };
  IF !$model[0].enabled THEN { THROW 'llm_model_disabled'; };

  LET $cost = fn::estimate_llm_cost($model[0], $run[0].input_tokens_estimate, $run[0].output_tokens_estimate);
  LET $cost_score = IF $policy[0].max_estimated_cost_usd = 0 THEN 0 ELSE fn::clamp01(1 - ($cost / $policy[0].max_estimated_cost_usd)) END;
  LET $latency_score = fn::clamp01(1 - ($model[0].baseline_latency_ms / $policy[0].max_latency_ms));
  LET $context_fit = IF ($run[0].input_tokens_estimate + $run[0].output_tokens_estimate) <= $model[0].context_window_tokens THEN 1 ELSE 0 END;

  LET $trust = fn::compute_trust_v1($tenant_id, string::concat($model_id), 'system:llm-selection', { type: 'llm_model_selection', task_kind: $run[0].task_kind });
  LET $reliability = fn::compute_reliability($tenant_id, string::concat($model_id), { type: 'llm_model_selection', task_kind: $run[0].task_kind }, NONE);

  LET $quality = fn::clamp01($model[0].baseline_quality_score);
  LET $final = fn::clamp01(
    ($policy[0].weights.quality * $quality) +
    ($policy[0].weights.cost * $cost_score) +
    ($policy[0].weights.latency * $latency_score) +
    ($policy[0].weights.trust * $trust.score) +
    ($policy[0].weights.reliability * $reliability.reliability_score) +
    ($policy[0].weights.context_fit * $context_fit)
  );

  LET $rejection = IF $quality < $policy[0].min_quality_score THEN 'low_quality' ELSE IF $trust.score < $policy[0].min_trust_score THEN 'low_trust' ELSE IF $reliability.reliability_score < $policy[0].min_reliability_score THEN 'low_reliability' ELSE IF $cost > $policy[0].max_estimated_cost_usd THEN 'cost_exceeds_policy' ELSE IF $model[0].baseline_latency_ms > $policy[0].max_latency_ms THEN 'latency_exceeds_policy' ELSE IF $context_fit = 0 THEN 'context_window_too_small' ELSE NONE END END END END END END;

  RETURN CREATE llm_selection_candidates CONTENT {
    tenant_id: $tenant_id,
    selection_run_id: $selection_run_id,
    model_id: $model_id,
    quality_score: $quality,
    trust_score: $trust.score,
    reliability_score: $reliability.reliability_score,
    latency_score: $latency_score,
    cost_score: $cost_score,
    context_fit_score: $context_fit,
    estimated_cost_usd: $cost,
    estimated_latency_ms: $model[0].baseline_latency_ms,
    final_score: $final,
    selected: false,
    rejection_reason: $rejection,
    explanation: { quality: $quality, cost: $cost, cost_score: $cost_score, latency_score: $latency_score, trust_score: $trust.score, reliability_score: $reliability.reliability_score, context_fit: $context_fit, final_score: $final },
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::finalize_llm_selection($selection_run_id) {
  LET $run = SELECT * FROM $selection_run_id;
  IF count($run) = 0 THEN { THROW 'llm_selection_run_not_found'; };
  LET $policy = SELECT * FROM $run[0].policy_id;
  LET $candidates = SELECT * FROM llm_selection_candidates WHERE selection_run_id = $selection_run_id ORDER BY final_score DESC;
  IF count($candidates) = 0 THEN { THROW 'llm_selection_candidates_required'; };
  LET $eligible = SELECT * FROM $candidates WHERE rejection_reason = NONE ORDER BY final_score DESC LIMIT 1;
  IF count($eligible) = 0 THEN { THROW 'no_eligible_llm_model'; };
  LET $selected = $eligible[0];
  LET $model = SELECT * FROM $selected.model_id;
  LET $human_required = $policy[0].require_human_approval OR $model[0].requires_human_approval OR ($policy[0].require_human_approval_for_high_risk AND $run[0].risk_level IN ['high', 'critical']) OR ($policy[0].require_human_approval_above_cost_usd != NONE AND $selected.estimated_cost_usd >= $policy[0].require_human_approval_above_cost_usd);

  UPDATE $selected.id SET selected = true;

  LET $decision_log = fn::log_decision_context(
    $run[0].tenant_id,
    'llm_selection',
    $run[0].subject_id,
    string::concat($run[0].agent_id),
    NONE,
    NONE,
    { task_kind: $run[0].task_kind, risk_level: $run[0].risk_level, input_tokens_estimate: $run[0].input_tokens_estimate, output_tokens_estimate: $run[0].output_tokens_estimate },
    {},
    {},
    {},
    { selected_model_trust_score: $selected.trust_score },
    { selected_model_reliability_score: $selected.reliability_score },
    {},
    { policy_id: $run[0].policy_id, policy: $policy[0] },
    $run[0].constraints,
    { max_cost: $policy[0].max_estimated_cost_usd, max_latency_ms: $policy[0].max_latency_ms, min_quality_score: $policy[0].min_quality_score, min_trust_score: $policy[0].min_trust_score, min_reliability_score: $policy[0].min_reliability_score, human_approval_rules: { require_human_approval: $policy[0].require_human_approval, require_human_approval_above_cost_usd: $policy[0].require_human_approval_above_cost_usd, require_human_approval_for_high_risk: $policy[0].require_human_approval_for_high_risk } },
    $candidates,
    { selected_candidate_id: $selected.id, selected_model_id: $selected.model_id, final_score: $selected.final_score, estimated_cost_usd: $selected.estimated_cost_usd },
    SELECT * FROM $candidates WHERE id != $selected.id,
    'llm_model_selected',
    { method: 'agx:llm-selection-v1', selected_model_id: $selected.model_id, selected_candidate_id: $selected.id, final_score: $selected.final_score, estimated_cost_usd: $selected.estimated_cost_usd, human_approval_required: $human_required },
    [$selected.model_id],
    $run[0].observation_run_id,
    [],
    $human_required
  );

  UPDATE $selection_run_id SET
    status = IF $human_required THEN 'pending_human_approval' ELSE 'completed' END,
    selected_candidate_id = $selected.id,
    selected_model_id = $selected.model_id,
    final_estimated_cost_usd = $selected.estimated_cost_usd,
    human_approval_required = $human_required,
    human_response_status = IF $human_required THEN 'pending' ELSE 'not_required' END,
    decision_log_id = $decision_log.id,
    completed_at = IF $human_required THEN NONE ELSE time::now() END;

  fn::add_observation_step($run[0].observation_run_id, 999, 'finalize_llm_selection', { candidate_count: count($candidates) }, { selected_model_id: $selected.model_id, final_score: $selected.final_score, human_approval_required: $human_required, decision_log_id: $decision_log.id }, 'completed', 'agx:llm-selection-v1');
  IF !$human_required THEN { fn::finish_observation_run($run[0].observation_run_id, 'completed', { selected_model_id: $selected.model_id, final_score: $selected.final_score }); };

  RETURN SELECT * FROM $selection_run_id;
};

DEFINE FUNCTION fn::approve_llm_selection($selection_run_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $run = SELECT * FROM $selection_run_id;
  IF count($run) = 0 THEN { THROW 'llm_selection_run_not_found'; };
  IF !$run[0].human_approval_required THEN { THROW 'human_approval_not_required'; };
  LET $response = fn::record_human_decision_response($run[0].tenant_id, $run[0].decision_log_id, NONE, NONE, $human_actor_id, 'llm_selection_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $selection_run_id SET status = IF $approval_status = 'approved' THEN 'completed' ELSE 'rejected' END, human_response_status = $approval_status, completed_at = time::now();
  fn::finish_observation_run($run[0].observation_run_id, IF $approval_status = 'approved' THEN 'completed' ELSE 'rejected' END, { approval_status: $approval_status, human_response_id: $response.id });
  RETURN SELECT * FROM $selection_run_id;
};

DEFINE FUNCTION fn::record_llm_usage($tenant_id, $selection_run_id, $model_id, $subject_id, $task_kind, $input_tokens, $output_tokens, $latency_ms, $success, $quality_score, $payload) {
  LET $model = SELECT * FROM $model_id;
  IF count($model) = 0 THEN { THROW 'llm_model_not_found'; };
  LET $cost = fn::estimate_llm_cost($model[0], $input_tokens, $output_tokens);
  LET $event = CREATE llm_usage_events CONTENT { tenant_id: $tenant_id, selection_run_id: $selection_run_id, model_id: $model_id, subject_id: $subject_id, task_kind: $task_kind, input_tokens: $input_tokens, output_tokens: $output_tokens, actual_cost_usd: $cost, latency_ms: $latency_ms, success: $success, quality_score: $quality_score, observed_at: time::now(), payload: $payload };
  fn::record_reliability_event($tenant_id, string::concat($model_id), 'llm_usage', IF $success THEN 'success' ELSE 'failure' END, IF $quality_score = NONE THEN 0.5 ELSE $quality_score END, $latency_ms, string::concat($event.id), { task_kind: $task_kind, input_tokens: $input_tokens, output_tokens: $output_tokens, actual_cost_usd: $cost });
  RETURN $event;
};
