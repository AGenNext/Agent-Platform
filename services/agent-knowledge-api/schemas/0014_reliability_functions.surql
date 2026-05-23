DEFINE TABLE reliability_profiles SCHEMAFULL;
DEFINE FIELD tenant_id ON reliability_profiles TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON reliability_profiles TYPE string;
DEFINE FIELD scope ON reliability_profiles TYPE object DEFAULT {};
DEFINE FIELD window_start ON reliability_profiles TYPE option<datetime>;
DEFINE FIELD window_end ON reliability_profiles TYPE datetime DEFAULT time::now();
DEFINE FIELD total_events ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD successful_events ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD failed_events ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD timeout_events ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD policy_blocked_events ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD contradiction_events ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD evaluated_events ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD passed_evaluations ON reliability_profiles TYPE int DEFAULT 0;
DEFINE FIELD mean_evaluation_score ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD success_rate ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD failure_rate ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD timeout_rate ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD policy_block_rate ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD contradiction_rate ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD evaluation_pass_rate ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD reliability_score ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD confidence ON reliability_profiles TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD explanation ON reliability_profiles TYPE object DEFAULT {};
DEFINE FIELD observation_run_id ON reliability_profiles TYPE option<record<observation_runs>>;
DEFINE FIELD jsonld_context ON reliability_profiles TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON reliability_profiles TYPE array<string> DEFAULT ['schema:PropertyValue', 'agx:ReliabilityProfile'];
DEFINE FIELD computed_at ON reliability_profiles TYPE datetime DEFAULT time::now();

DEFINE TABLE reliability_events SCHEMAFULL;
DEFINE FIELD tenant_id ON reliability_events TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON reliability_events TYPE string;
DEFINE FIELD event_kind ON reliability_events TYPE string;
DEFINE FIELD status ON reliability_events TYPE string;
DEFINE FIELD score ON reliability_events TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD latency_ms ON reliability_events TYPE option<number>;
DEFINE FIELD source_id ON reliability_events TYPE option<string>;
DEFINE FIELD payload ON reliability_events TYPE object DEFAULT {};
DEFINE FIELD observed_at ON reliability_events TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON reliability_events TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON reliability_events TYPE array<string> DEFAULT ['schema:Action', 'agx:ReliabilityEvent'];
DEFINE FIELD created_at ON reliability_events TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::record_reliability_event($tenant_id, $subject_id, $event_kind, $status, $score, $latency_ms, $source_id, $payload) {
  IF $status NOT IN ['success', 'failure', 'timeout', 'policy_blocked', 'contradiction', 'evaluation_passed', 'evaluation_failed'] THEN { THROW 'invalid_reliability_status'; };
  RETURN CREATE reliability_events CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    event_kind: $event_kind,
    status: $status,
    score: fn::clamp01($score),
    latency_ms: $latency_ms,
    source_id: $source_id,
    payload: $payload,
    observed_at: time::now(),
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::reliability_ratio($numerator, $denominator) {
  RETURN IF $denominator = 0 THEN 0 ELSE fn::clamp01($numerator / $denominator) END;
};

DEFINE FUNCTION fn::compute_reliability($tenant_id, $subject_id, $scope, $window_start) {
  LET $method = 'agx:reliability-v1';
  LET $run = fn::create_observation_run($tenant_id, NONE, 'reliability_computation', $method);
  LET $events = SELECT * FROM reliability_events WHERE subject_id = $subject_id AND (tenant_id = $tenant_id OR tenant_id = NONE) AND ($window_start = NONE OR observed_at >= $window_start);
  LET $evals = SELECT * FROM evaluation_runs WHERE subject_id = $subject_id AND (tenant_id = $tenant_id OR tenant_id = NONE) AND status = 'completed' AND ($window_start = NONE OR ended_at >= $window_start);
  LET $guardrails = SELECT * FROM guardrail_decisions WHERE subject_id = $subject_id AND (tenant_id = $tenant_id OR tenant_id = NONE) AND ($window_start = NONE OR created_at >= $window_start);

  LET $total = count($events) + count($evals) + count($guardrails);
  LET $successes = count(SELECT * FROM $events WHERE status = 'success') + count(SELECT * FROM $evals WHERE passed = true) + count(SELECT * FROM $guardrails WHERE decision = 'allow');
  LET $failures = count(SELECT * FROM $events WHERE status = 'failure') + count(SELECT * FROM $evals WHERE passed = false);
  LET $timeouts = count(SELECT * FROM $events WHERE status = 'timeout');
  LET $policy_blocks = count(SELECT * FROM $events WHERE status = 'policy_blocked') + count(SELECT * FROM $guardrails WHERE decision != 'allow');
  LET $contradictions = count(SELECT * FROM $events WHERE status = 'contradiction');
  LET $eval_count = count($evals);
  LET $eval_passed = count(SELECT * FROM $evals WHERE passed = true);
  LET $mean_eval = IF $eval_count = 0 THEN 0 ELSE fn::clamp01(math::mean($evals[*].aggregate_score)) END;

  LET $success_rate = fn::reliability_ratio($successes, $total);
  LET $failure_rate = fn::reliability_ratio($failures, $total);
  LET $timeout_rate = fn::reliability_ratio($timeouts, $total);
  LET $policy_block_rate = fn::reliability_ratio($policy_blocks, $total);
  LET $contradiction_rate = fn::reliability_ratio($contradictions, $total);
  LET $eval_pass_rate = fn::reliability_ratio($eval_passed, $eval_count);
  LET $volume_confidence = fn::clamp01($total / 30);

  LET $raw =
    (0.35 * $success_rate) +
    (0.25 * $mean_eval) +
    (0.15 * $eval_pass_rate) +
    (0.10 * (1 - $failure_rate)) +
    (0.05 * (1 - $timeout_rate)) +
    (0.05 * (1 - $policy_block_rate)) +
    (0.05 * (1 - $contradiction_rate));

  LET $score = fn::clamp01($raw * (0.50 + (0.50 * $volume_confidence)));

  LET $step1 = fn::add_observation_step($run.id, 1, 'collect_reliability_signals', { subject_id: $subject_id, scope: $scope, window_start: $window_start }, { reliability_events: count($events), evaluation_runs: count($evals), guardrail_decisions: count($guardrails) }, 'completed', $method);
  LET $step2 = fn::add_observation_step($run.id, 2, 'compute_reliability_rates', { total_events: $total }, { success_rate: $success_rate, failure_rate: $failure_rate, timeout_rate: $timeout_rate, policy_block_rate: $policy_block_rate, contradiction_rate: $contradiction_rate, evaluation_pass_rate: $eval_pass_rate }, 'completed', $method);
  LET $step3 = fn::add_observation_step($run.id, 3, 'compute_reliability_score', { raw_score: $raw, volume_confidence: $volume_confidence }, { reliability_score: $score }, 'completed', $method);

  LET $profile = CREATE reliability_profiles CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    scope: $scope,
    window_start: $window_start,
    window_end: time::now(),
    total_events: $total,
    successful_events: $successes,
    failed_events: $failures,
    timeout_events: $timeouts,
    policy_blocked_events: $policy_blocks,
    contradiction_events: $contradictions,
    evaluated_events: $eval_count,
    passed_evaluations: $eval_passed,
    mean_evaluation_score: $mean_eval,
    success_rate: $success_rate,
    failure_rate: $failure_rate,
    timeout_rate: $timeout_rate,
    policy_block_rate: $policy_block_rate,
    contradiction_rate: $contradiction_rate,
    evaluation_pass_rate: $eval_pass_rate,
    reliability_score: $score,
    confidence: $volume_confidence,
    explanation: { method: $method, raw_score: $raw, volume_confidence: $volume_confidence, score: $score },
    observation_run_id: $run.id,
    computed_at: time::now()
  };

  CREATE trust_evidence CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    evidence_kind: 'local_usage_success',
    source_id: string::concat($profile.id),
    weight: $score,
    confidence: $volume_confidence,
    payload: { reliability_profile_id: $profile.id, total_events: $total, success_rate: $success_rate },
    observed_at: time::now(),
    source_grounding_refs: ['agx:reliability-v1'],
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence']
  };

  UPDATE $run.id SET status = 'completed', ended_at = time::now();
  RETURN $profile;
};
