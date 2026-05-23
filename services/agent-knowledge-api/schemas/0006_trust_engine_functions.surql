DEFINE FUNCTION fn::clamp01($value) {
  RETURN math::min([1, math::max([0, $value])]);
};

DEFINE FUNCTION fn::trust_component_average($evidence, $kind, $default) {
  LET $items = SELECT * FROM $evidence WHERE evidence_kind = $kind;
  RETURN IF count($items) = 0 THEN $default ELSE fn::clamp01(math::mean($items[*].weight)) END;
};

DEFINE FUNCTION fn::trust_confidence_average($evidence, $default) {
  RETURN IF count($evidence) = 0 THEN $default ELSE fn::clamp01(math::mean($evidence[*].confidence)) END;
};

DEFINE FUNCTION fn::trust_penalty_average($evidence, $kind) {
  LET $items = SELECT * FROM $evidence WHERE evidence_kind = $kind;
  RETURN IF count($items) = 0 THEN 0 ELSE fn::clamp01(math::mean($items[*].weight)) END;
};

DEFINE FUNCTION fn::trust_cap_for_subject($subject_id, $evidence, $base_cap) {
  LET $revocations = SELECT * FROM trust_evidence WHERE subject_id = $subject_id AND evidence_kind = 'revocation' AND weight > 0;
  LET $security = SELECT * FROM trust_evidence WHERE subject_id = $subject_id AND evidence_kind = 'security_risk' AND weight > 0;
  LET $graph_failures = SELECT * FROM trust_evidence WHERE subject_id = $subject_id AND evidence_kind = 'failed_graph_validation' AND weight > 0;
  LET $unknown_source = SELECT * FROM trust_evidence WHERE subject_id = $subject_id AND evidence_kind = 'unknown_source' AND weight > 0;

  LET $cap = $base_cap;
  LET $cap = IF count($evidence) = 0 THEN math::min([$cap, 0.60]) ELSE $cap END;
  LET $cap = IF count($unknown_source) > 0 THEN math::min([$cap, 0.50]) ELSE $cap END;
  LET $cap = IF count($graph_failures) > 0 THEN math::min([$cap, 0.40]) ELSE $cap END;
  LET $cap = IF count($security) > 0 THEN math::min([$cap, 0.30]) ELSE $cap END;
  LET $cap = IF count($revocations) > 0 THEN math::min([$cap, 0.10]) ELSE $cap END;

  RETURN $cap;
};

DEFINE FUNCTION fn::compute_trust_v1($tenant_id, $subject_id, $evaluator_id, $scope) {
  LET $method = 'agx:trust-weighted-evidence-v1';
  LET $run = fn::create_observation_run($tenant_id, NONE, 'trust_computation', $method);

  LET $evidence = SELECT * FROM trust_evidence WHERE subject_id = $subject_id AND (tenant_id = $tenant_id OR tenant_id = NONE);
  LET $source_reliability = fn::trust_component_average($evidence, 'source_reliability', 0.50);
  LET $evidence_strength = fn::trust_component_average($evidence, 'evidence_strength', 0.50);
  LET $behavioral_consistency = fn::trust_component_average($evidence, 'behavioral_consistency', 0.50);
  LET $grounded_attribution = fn::trust_component_average($evidence, 'grounded_attribution', 0.50);
  LET $citation_quality = fn::trust_component_average($evidence, 'citation_quality', 0.50);
  LET $refusal_correctness = fn::trust_component_average($evidence, 'refusal_correctness', 0.50);
  LET $message_reliability = fn::trust_component_average($evidence, 'message_reliability', 0.50);
  LET $registry_reliability = fn::trust_component_average($evidence, 'registry_reliability', 0.50);
  LET $identity_proof = fn::trust_component_average($evidence, 'identity_proof', 0.50);
  LET $endorsement_strength = fn::trust_component_average($evidence, 'endorsement_strength', 0.50);
  LET $local_usage_success = fn::trust_component_average($evidence, 'local_usage_success', 0.50);
  LET $graph_consistency = fn::trust_component_average($evidence, 'graph_consistency', 0.50);
  LET $temporal_freshness = fn::trust_component_average($evidence, 'temporal_freshness', 0.50);
  LET $governance_approval = fn::trust_component_average($evidence, 'governance_approval', 0.00);

  LET $risk_penalty = fn::trust_penalty_average($evidence, 'risk_penalty');
  LET $security_penalty = fn::trust_penalty_average($evidence, 'security_penalty');
  LET $contradiction_penalty = fn::trust_penalty_average($evidence, 'contradiction_penalty');
  LET $revocation_penalty = fn::trust_penalty_average($evidence, 'revocation_penalty');
  LET $sybil_risk_penalty = fn::trust_penalty_average($evidence, 'sybil_risk_penalty');
  LET $camouflage_risk_penalty = fn::trust_penalty_average($evidence, 'camouflage_risk_penalty');
  LET $policy_penalty = fn::trust_penalty_average($evidence, 'policy_penalty');

  LET $raw_score =
    (0.12 * $source_reliability) +
    (0.10 * $evidence_strength) +
    (0.10 * $behavioral_consistency) +
    (0.10 * $grounded_attribution) +
    (0.06 * $citation_quality) +
    (0.06 * $refusal_correctness) +
    (0.08 * $message_reliability) +
    (0.08 * $registry_reliability) +
    (0.06 * $identity_proof) +
    (0.06 * $endorsement_strength) +
    (0.06 * $local_usage_success) +
    (0.06 * $graph_consistency) +
    (0.04 * $temporal_freshness) +
    (0.02 * $governance_approval) -
    $risk_penalty -
    $security_penalty -
    $contradiction_penalty -
    $revocation_penalty -
    $sybil_risk_penalty -
    $camouflage_risk_penalty -
    $policy_penalty;

  LET $uncapped_score = fn::clamp01($raw_score);
  LET $cap = fn::trust_cap_for_subject($subject_id, $evidence, 1.0);
  LET $score = math::min([$uncapped_score, $cap]);
  LET $confidence = fn::trust_confidence_average($evidence, 0.25);

  LET $components = {
    sourceReliability: $source_reliability,
    evidenceStrength: $evidence_strength,
    behavioralConsistency: $behavioral_consistency,
    groundedAttribution: $grounded_attribution,
    citationQuality: $citation_quality,
    refusalCorrectness: $refusal_correctness,
    messageReliability: $message_reliability,
    registryReliability: $registry_reliability,
    identityProof: $identity_proof,
    endorsementStrength: $endorsement_strength,
    localUsageSuccess: $local_usage_success,
    graphConsistency: $graph_consistency,
    temporalFreshness: $temporal_freshness,
    governanceApproval: $governance_approval
  };

  LET $penalties = {
    riskPenalty: $risk_penalty,
    securityPenalty: $security_penalty,
    contradictionPenalty: $contradiction_penalty,
    revocationPenalty: $revocation_penalty,
    sybilRiskPenalty: $sybil_risk_penalty,
    camouflageRiskPenalty: $camouflage_risk_penalty,
    policyPenalty: $policy_penalty
  };

  LET $step1 = fn::add_observation_step($run.id, 1, 'collect_trust_evidence', { subject_id: $subject_id, evaluator_id: $evaluator_id, scope: $scope }, { evidence_count: count($evidence), evidence_ids: $evidence[*].id }, 'completed', $method);
  LET $step2 = fn::add_observation_step($run.id, 2, 'compute_trust_components', { evidence_ids: $evidence[*].id }, $components, 'completed', $method);
  LET $step3 = fn::add_observation_step($run.id, 3, 'apply_trust_penalties_and_caps', { uncapped_score: $uncapped_score, penalties: $penalties }, { cap: $cap, final_score: $score }, 'completed', $method);

  LET $record = CREATE trust_scores CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    evaluator_id: $evaluator_id,
    scope: $scope,
    score: $score,
    confidence: $confidence,
    method_version: $method,
    component_scores: $components,
    caps_applied: IF $cap < 1.0 THEN ['trust_cap_applied'] ELSE [] END,
    penalties_applied: $penalties,
    explanation: {
      method: $method,
      raw_score: $raw_score,
      uncapped_score: $uncapped_score,
      cap: $cap,
      final_score: $score,
      evidence_count: count($evidence)
    },
    evidence_ids: $evidence[*].id,
    observation_run_id: $run.id,
    observation_step_ids: [$step1.id, $step2.id, $step3.id],
    computed_at: time::now(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:TrustScore']
  };

  UPDATE $run.id SET status = 'completed', ended_at = time::now();
  RETURN $record;
};

DEFINE FUNCTION fn::compute_trust($subject_id, $evaluator_id, $scope) {
  RETURN fn::compute_trust_v1(NONE, $subject_id, $evaluator_id, $scope);
};
