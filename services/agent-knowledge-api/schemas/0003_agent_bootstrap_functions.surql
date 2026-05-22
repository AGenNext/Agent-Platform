DEFINE FUNCTION fn::bootstrap_agent($agent) {
  LET $modules = SELECT * FROM agent_modules WHERE enabled_by_default = true ORDER BY load_order;

  FOR $module IN $modules {
    UPSERT agent_module_instances SET
      tenant_id = $agent.tenant_id,
      agent_id = $agent.id,
      module_id = $module.id,
      key = $module.key,
      enabled = true,
      config = {},
      status = 'active';
  };

  UPDATE $agent.id SET
    default_modules_loaded = true,
    trust_policy_id = trust_policies:default,
    updated_at = time::now();

  RETURN SELECT * FROM agent_module_instances WHERE agent_id = $agent.id ORDER BY key;
};

DEFINE FUNCTION fn::create_observation_run($tenant_id, $agent_id, $run_kind, $method_version) {
  RETURN CREATE observation_runs CONTENT {
    tenant_id: $tenant_id,
    agent_id: $agent_id,
    run_kind: $run_kind,
    semantic_id: rand::uuid(),
    status: 'running',
    started_at: time::now(),
    method_version: $method_version
  };
};

DEFINE FUNCTION fn::add_observation_step($run_id, $sequence, $step_kind, $input, $output, $status, $method_version) {
  LET $run = SELECT * FROM $run_id;
  RETURN CREATE observation_steps CONTENT {
    tenant_id: $run[0].tenant_id,
    run_id: $run_id,
    agent_id: $run[0].agent_id,
    sequence: $sequence,
    step_kind: $step_kind,
    semantic_id: rand::uuid(),
    input: $input,
    output: $output,
    status: $status,
    started_at: time::now(),
    ended_at: time::now(),
    observed_at: time::now(),
    method_version: $method_version
  };
};

DEFINE FUNCTION fn::compute_trust($subject_id, $evaluator_id, $scope) {
  LET $run = fn::create_observation_run(NONE, NONE, 'trust_computation', 'agx:trust-weighted-evidence-v1');

  LET $evidence = SELECT * FROM trust_evidence WHERE subject_id = $subject_id;
  LET $count = count($evidence);
  LET $avg_weight = IF $count = 0 THEN 0 ELSE math::mean($evidence[*].weight) END;
  LET $avg_confidence = IF $count = 0 THEN 0 ELSE math::mean($evidence[*].confidence) END;
  LET $raw_score = ($avg_weight + $avg_confidence) / 2;
  LET $score = math::min([1, math::max([0, $raw_score])]);

  LET $step = fn::add_observation_step($run.id, 1, 'compute_trust', {
    subject_id: $subject_id,
    evaluator_id: $evaluator_id,
    scope: $scope
  }, {
    evidence_count: $count,
    avg_weight: $avg_weight,
    avg_confidence: $avg_confidence,
    score: $score
  }, 'completed', 'agx:trust-weighted-evidence-v1');

  LET $record = CREATE trust_scores CONTENT {
    subject_id: $subject_id,
    evaluator_id: $evaluator_id,
    scope: $scope,
    score: $score,
    confidence: $avg_confidence,
    method_version: 'agx:trust-weighted-evidence-v1',
    component_scores: {
      avg_weight: $avg_weight,
      avg_confidence: $avg_confidence
    },
    explanation: {
      summary: 'Computed from average evidence weight and confidence.' 
    },
    evidence_ids: $evidence[*].id,
    observation_run_id: $run.id,
    observation_step_ids: [$step.id]
  };

  UPDATE $run.id SET status = 'completed', ended_at = time::now();

  RETURN $record;
};

DEFINE EVENT bootstrap_default_modules ON agents
WHEN $event = 'CREATE'
THEN {
  fn::bootstrap_agent($after);
};
