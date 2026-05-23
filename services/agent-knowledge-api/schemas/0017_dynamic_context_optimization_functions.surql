DEFINE TABLE context_optimization_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON context_optimization_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON context_optimization_policies TYPE string;
DEFINE FIELD name ON context_optimization_policies TYPE string;
DEFINE FIELD max_context_items ON context_optimization_policies TYPE int DEFAULT 20;
DEFINE FIELD max_total_tokens ON context_optimization_policies TYPE int DEFAULT 12000;
DEFINE FIELD min_relevance_score ON context_optimization_policies TYPE number DEFAULT 0.45 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_trust_score ON context_optimization_policies TYPE number DEFAULT 0.50 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_reliability_score ON context_optimization_policies TYPE number DEFAULT 0.50 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD recency_half_life_hours ON context_optimization_policies TYPE number DEFAULT 168;
DEFINE FIELD weights ON context_optimization_policies TYPE object DEFAULT { relevance: 0.32, trust: 0.20, reliability: 0.16, recency: 0.12, coverage: 0.10, diversity: 0.05, constraint: 0.05 };
DEFINE FIELD enabled ON context_optimization_policies TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON context_optimization_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON context_optimization_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ContextOptimizationPolicy'];
DEFINE FIELD created_at ON context_optimization_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX context_optimization_policies_key_unique ON context_optimization_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE context_optimization_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON context_optimization_runs TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON context_optimization_runs TYPE option<record<agents>>;
DEFINE FIELD subject_id ON context_optimization_runs TYPE string;
DEFINE FIELD query_text ON context_optimization_runs TYPE string;
DEFINE FIELD policy_id ON context_optimization_runs TYPE record<context_optimization_policies>;
DEFINE FIELD constraints ON context_optimization_runs TYPE array<object> DEFAULT [];
DEFINE FIELD candidate_count ON context_optimization_runs TYPE int DEFAULT 0;
DEFINE FIELD selected_count ON context_optimization_runs TYPE int DEFAULT 0;
DEFINE FIELD total_estimated_tokens ON context_optimization_runs TYPE int DEFAULT 0;
DEFINE FIELD status ON context_optimization_runs TYPE string DEFAULT 'running';
DEFINE FIELD observation_run_id ON context_optimization_runs TYPE option<record<observation_runs>>;
DEFINE FIELD decision_log_id ON context_optimization_runs TYPE option<record<decision_context_logs>>;
DEFINE FIELD jsonld_context ON context_optimization_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON context_optimization_runs TYPE array<string> DEFAULT ['schema:Action', 'agx:ContextOptimizationRun'];
DEFINE FIELD created_at ON context_optimization_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON context_optimization_runs TYPE option<datetime>;

DEFINE TABLE context_candidates SCHEMAFULL;
DEFINE FIELD tenant_id ON context_candidates TYPE option<record<tenants>>;
DEFINE FIELD optimization_run_id ON context_candidates TYPE record<context_optimization_runs>;
DEFINE FIELD source_ref ON context_candidates TYPE record;
DEFINE FIELD source_kind ON context_candidates TYPE string;
DEFINE FIELD content_summary ON context_candidates TYPE string;
DEFINE FIELD estimated_tokens ON context_candidates TYPE int DEFAULT 0;
DEFINE FIELD relevance_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD trust_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD reliability_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD recency_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD coverage_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD diversity_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD constraint_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD final_score ON context_candidates TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD selected ON context_candidates TYPE bool DEFAULT false;
DEFINE FIELD rejection_reason ON context_candidates TYPE option<string>;
DEFINE FIELD metadata ON context_candidates TYPE object DEFAULT {};
DEFINE FIELD jsonld_context ON context_candidates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON context_candidates TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ContextCandidate'];
DEFINE FIELD created_at ON context_candidates TYPE datetime DEFAULT time::now();

DEFINE TABLE optimized_context_items SCHEMAFULL;
DEFINE FIELD tenant_id ON optimized_context_items TYPE option<record<tenants>>;
DEFINE FIELD optimization_run_id ON optimized_context_items TYPE record<context_optimization_runs>;
DEFINE FIELD candidate_id ON optimized_context_items TYPE record<context_candidates>;
DEFINE FIELD rank ON optimized_context_items TYPE int;
DEFINE FIELD source_ref ON optimized_context_items TYPE record;
DEFINE FIELD source_kind ON optimized_context_items TYPE string;
DEFINE FIELD content_summary ON optimized_context_items TYPE string;
DEFINE FIELD final_score ON optimized_context_items TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD estimated_tokens ON optimized_context_items TYPE int DEFAULT 0;
DEFINE FIELD inclusion_reason ON optimized_context_items TYPE string;
DEFINE FIELD jsonld_context ON optimized_context_items TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON optimized_context_items TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:OptimizedContextItem'];
DEFINE FIELD created_at ON optimized_context_items TYPE datetime DEFAULT time::now();
DEFINE INDEX optimized_context_items_rank_unique ON optimized_context_items FIELDS optimization_run_id, rank UNIQUE;

UPSERT context_optimization_policies:default CONTENT {
  tenant_id: NONE,
  key: 'default',
  name: 'Default Dynamic Context Optimization Policy',
  max_context_items: 20,
  max_total_tokens: 12000,
  min_relevance_score: 0.45,
  min_trust_score: 0.50,
  min_reliability_score: 0.50,
  recency_half_life_hours: 168,
  weights: { relevance: 0.32, trust: 0.20, reliability: 0.16, recency: 0.12, coverage: 0.10, diversity: 0.05, constraint: 0.05 },
  enabled: true
};

DEFINE FUNCTION fn::select_context_optimization_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM context_optimization_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM context_optimization_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN context_optimization_policies:default;
};

DEFINE FUNCTION fn::context_final_score($policy, $relevance, $trust, $reliability, $recency, $coverage, $diversity, $constraint) {
  RETURN fn::clamp01(
    ($policy.weights.relevance * $relevance) +
    ($policy.weights.trust * $trust) +
    ($policy.weights.reliability * $reliability) +
    ($policy.weights.recency * $recency) +
    ($policy.weights.coverage * $coverage) +
    ($policy.weights.diversity * $diversity) +
    ($policy.weights.constraint * $constraint)
  );
};

DEFINE FUNCTION fn::start_context_optimization($tenant_id, $agent_id, $subject_id, $query_text, $policy_key, $constraints) {
  LET $policy = fn::select_context_optimization_policy($tenant_id, $policy_key);
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'context_optimization', 'agx:dynamic-context-optimization-v1');
  LET $run = CREATE context_optimization_runs CONTENT {
    tenant_id: $tenant_id,
    agent_id: $agent_id,
    subject_id: $subject_id,
    query_text: $query_text,
    policy_id: $policy.id,
    constraints: $constraints,
    status: 'running',
    observation_run_id: $obs.id,
    created_at: time::now()
  };
  fn::add_observation_step($obs.id, 1, 'start_context_optimization', { subject_id: $subject_id, query_text: $query_text, constraints: $constraints }, { optimization_run_id: $run.id, policy_id: $policy.id }, 'completed', 'agx:dynamic-context-optimization-v1');
  RETURN $run;
};

DEFINE FUNCTION fn::add_context_candidate($tenant_id, $optimization_run_id, $source_ref, $source_kind, $content_summary, $estimated_tokens, $relevance_score, $trust_score, $reliability_score, $recency_score, $coverage_score, $diversity_score, $constraint_score, $metadata) {
  LET $run = SELECT * FROM $optimization_run_id;
  IF count($run) = 0 THEN { THROW 'context_optimization_run_not_found'; };
  IF $run[0].status != 'running' THEN { THROW 'context_optimization_not_running'; };
  LET $policy = SELECT * FROM $run[0].policy_id;
  LET $final = fn::context_final_score($policy[0], fn::clamp01($relevance_score), fn::clamp01($trust_score), fn::clamp01($reliability_score), fn::clamp01($recency_score), fn::clamp01($coverage_score), fn::clamp01($diversity_score), fn::clamp01($constraint_score));
  LET $rejection = IF $relevance_score < $policy[0].min_relevance_score THEN 'low_relevance' ELSE IF $trust_score < $policy[0].min_trust_score THEN 'low_trust' ELSE IF $reliability_score < $policy[0].min_reliability_score THEN 'low_reliability' ELSE NONE END END END;
  RETURN CREATE context_candidates CONTENT {
    tenant_id: $tenant_id,
    optimization_run_id: $optimization_run_id,
    source_ref: $source_ref,
    source_kind: $source_kind,
    content_summary: $content_summary,
    estimated_tokens: $estimated_tokens,
    relevance_score: fn::clamp01($relevance_score),
    trust_score: fn::clamp01($trust_score),
    reliability_score: fn::clamp01($reliability_score),
    recency_score: fn::clamp01($recency_score),
    coverage_score: fn::clamp01($coverage_score),
    diversity_score: fn::clamp01($diversity_score),
    constraint_score: fn::clamp01($constraint_score),
    final_score: $final,
    selected: false,
    rejection_reason: $rejection,
    metadata: $metadata,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::finalize_context_optimization($optimization_run_id) {
  LET $run = SELECT * FROM $optimization_run_id;
  IF count($run) = 0 THEN { THROW 'context_optimization_run_not_found'; };
  LET $policy = SELECT * FROM $run[0].policy_id;
  LET $eligible = SELECT * FROM context_candidates WHERE optimization_run_id = $optimization_run_id AND rejection_reason = NONE ORDER BY final_score DESC;
  LET $selected = [];
  LET $tokens = 0;
  LET $rank = 1;
  FOR $candidate IN $eligible {
    IF count($selected) < $policy[0].max_context_items AND ($tokens + $candidate.estimated_tokens) <= $policy[0].max_total_tokens THEN {
      UPDATE $candidate.id SET selected = true;
      CREATE optimized_context_items CONTENT {
        tenant_id: $run[0].tenant_id,
        optimization_run_id: $optimization_run_id,
        candidate_id: $candidate.id,
        rank: $rank,
        source_ref: $candidate.source_ref,
        source_kind: $candidate.source_kind,
        content_summary: $candidate.content_summary,
        final_score: $candidate.final_score,
        estimated_tokens: $candidate.estimated_tokens,
        inclusion_reason: 'highest_scoring_candidate_within_budget',
        created_at: time::now()
      };
      LET $selected += [$candidate.id];
      LET $tokens += $candidate.estimated_tokens;
      LET $rank += 1;
    };
  };
  LET $all_candidates = SELECT * FROM context_candidates WHERE optimization_run_id = $optimization_run_id;
  LET $items = SELECT * FROM optimized_context_items WHERE optimization_run_id = $optimization_run_id ORDER BY rank;
  LET $decision_log = fn::log_decision_context(
    $run[0].tenant_id,
    'context_optimization',
    $run[0].subject_id,
    string::concat($run[0].agent_id),
    NONE,
    NONE,
    { query_text: $run[0].query_text },
    { candidates: $all_candidates[*].id, selected_items: $items[*].id },
    {},
    {},
    {},
    {},
    {},
    { policy_id: $run[0].policy_id, policy: $policy[0] },
    $run[0].constraints,
    { policy: $policy[0], token_budget: $policy[0].max_total_tokens, max_context_items: $policy[0].max_context_items, thresholds: { relevance: $policy[0].min_relevance_score, trust: $policy[0].min_trust_score, reliability: $policy[0].min_reliability_score } },
    $all_candidates,
    { selected_item_ids: $items[*].id, total_tokens: $tokens },
    SELECT * FROM $all_candidates WHERE selected = false,
    'optimized_context_selected',
    { method: 'agx:dynamic-context-optimization-v1', selected_count: count($items), candidate_count: count($all_candidates), total_tokens: $tokens },
    $items[*].source_ref,
    $run[0].observation_run_id,
    [],
    false
  );
  UPDATE $optimization_run_id SET status = 'completed', candidate_count = count($all_candidates), selected_count = count($items), total_estimated_tokens = $tokens, decision_log_id = $decision_log.id, completed_at = time::now();
  fn::add_observation_step($run[0].observation_run_id, 999, 'finalize_context_optimization', { candidate_count: count($all_candidates) }, { selected_count: count($items), total_tokens: $tokens, decision_log_id: $decision_log.id }, 'completed', 'agx:dynamic-context-optimization-v1');
  fn::finish_observation_run($run[0].observation_run_id, 'completed', { selected_count: count($items), total_tokens: $tokens });
  RETURN SELECT * FROM $optimization_run_id;
};
