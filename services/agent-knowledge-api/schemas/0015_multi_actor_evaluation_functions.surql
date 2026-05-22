DEFINE TABLE evaluation_orchestrations SCHEMAFULL;
DEFINE FIELD tenant_id ON evaluation_orchestrations TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON evaluation_orchestrations TYPE string;
DEFINE FIELD suite_id ON evaluation_orchestrations TYPE record<evaluation_suites>;
DEFINE FIELD orchestrator_id ON evaluation_orchestrations TYPE string;
DEFINE FIELD agent_id ON evaluation_orchestrations TYPE option<record<agents>>;
DEFINE FIELD required_self_eval ON evaluation_orchestrations TYPE bool DEFAULT true;
DEFINE FIELD required_peer_evals ON evaluation_orchestrations TYPE int DEFAULT 2;
DEFINE FIELD required_orchestrator_eval ON evaluation_orchestrations TYPE bool DEFAULT true;
DEFINE FIELD status ON evaluation_orchestrations TYPE string DEFAULT 'running';
DEFINE FIELD final_score ON evaluation_orchestrations TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD final_decision ON evaluation_orchestrations TYPE option<string>;
DEFINE FIELD observation_run_id ON evaluation_orchestrations TYPE option<record<observation_runs>>;
DEFINE FIELD jsonld_context ON evaluation_orchestrations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON evaluation_orchestrations TYPE array<string> DEFAULT ['schema:Action', 'agx:EvaluationOrchestration'];
DEFINE FIELD created_at ON evaluation_orchestrations TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON evaluation_orchestrations TYPE option<datetime>;

DEFINE TABLE actor_evaluation_reports SCHEMAFULL;
DEFINE FIELD tenant_id ON actor_evaluation_reports TYPE option<record<tenants>>;
DEFINE FIELD orchestration_id ON actor_evaluation_reports TYPE record<evaluation_orchestrations>;
DEFINE FIELD evaluation_run_id ON actor_evaluation_reports TYPE option<record<evaluation_runs>>;
DEFINE FIELD evaluator_id ON actor_evaluation_reports TYPE string;
DEFINE FIELD evaluator_kind ON actor_evaluation_reports TYPE string;
DEFINE FIELD subject_id ON actor_evaluation_reports TYPE string;
DEFINE FIELD score ON actor_evaluation_reports TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD confidence ON actor_evaluation_reports TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD passed ON actor_evaluation_reports TYPE bool;
DEFINE FIELD findings ON actor_evaluation_reports TYPE array<string> DEFAULT [];
DEFINE FIELD evidence_ids ON actor_evaluation_reports TYPE array<record<trust_evidence>> DEFAULT [];
DEFINE FIELD explanation ON actor_evaluation_reports TYPE object DEFAULT {};
DEFINE FIELD observed_at ON actor_evaluation_reports TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON actor_evaluation_reports TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON actor_evaluation_reports TYPE array<string> DEFAULT ['schema:Review', 'agx:ActorEvaluationReport'];
DEFINE INDEX actor_evaluation_reports_unique ON actor_evaluation_reports FIELDS orchestration_id, evaluator_id, evaluator_kind UNIQUE;

DEFINE FUNCTION fn::start_evaluation_orchestration($tenant_id, $suite_id, $agent_id, $subject_id, $orchestrator_id, $required_peer_evals) {
  LET $suite = SELECT * FROM $suite_id;
  IF count($suite) = 0 THEN { THROW 'evaluation_suite_not_found'; };
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'evaluation_orchestration', 'agx:multi-actor-evaluation-v1');
  LET $orch = CREATE evaluation_orchestrations CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    suite_id: $suite_id,
    orchestrator_id: $orchestrator_id,
    agent_id: $agent_id,
    required_self_eval: true,
    required_peer_evals: $required_peer_evals,
    required_orchestrator_eval: true,
    status: 'running',
    observation_run_id: $obs.id,
    created_at: time::now()
  };
  fn::add_observation_step($obs.id, 1, 'start_evaluation_orchestration', { suite_id: $suite_id, subject_id: $subject_id, orchestrator_id: $orchestrator_id }, { orchestration_id: $orch.id, required_peer_evals: $required_peer_evals }, 'completed', 'agx:multi-actor-evaluation-v1');
  RETURN $orch;
};

DEFINE FUNCTION fn::record_actor_evaluation($tenant_id, $orchestration_id, $evaluation_run_id, $evaluator_id, $evaluator_kind, $score, $confidence, $passed, $findings, $evidence_ids, $explanation) {
  LET $orch = SELECT * FROM $orchestration_id;
  IF count($orch) = 0 THEN { THROW 'evaluation_orchestration_not_found'; };
  IF $orch[0].status != 'running' THEN { THROW 'evaluation_orchestration_not_running'; };
  IF $evaluator_kind NOT IN ['self', 'peer', 'orchestrator'] THEN { THROW 'invalid_evaluator_kind'; };

  LET $report = UPSERT type::thing('actor_evaluation_reports', rand::uuid()) CONTENT {
    tenant_id: $tenant_id,
    orchestration_id: $orchestration_id,
    evaluation_run_id: $evaluation_run_id,
    evaluator_id: $evaluator_id,
    evaluator_kind: $evaluator_kind,
    subject_id: $orch[0].subject_id,
    score: fn::clamp01($score),
    confidence: fn::clamp01($confidence),
    passed: $passed,
    findings: $findings,
    evidence_ids: $evidence_ids,
    explanation: $explanation,
    observed_at: time::now()
  };

  CREATE trust_evidence CONTENT {
    tenant_id: $tenant_id,
    subject_id: $orch[0].subject_id,
    evidence_kind: IF $evaluator_kind = 'self' THEN 'self_evaluation' ELSE IF $evaluator_kind = 'peer' THEN 'peer_evaluation' ELSE 'orchestrator_evaluation' END END,
    source_id: $evaluator_id,
    weight: fn::clamp01($score),
    confidence: fn::clamp01($confidence),
    payload: { report_id: $report.id, evaluator_kind: $evaluator_kind, passed: $passed, findings: $findings },
    observed_at: time::now(),
    source_grounding_refs: ['agx:multi-actor-evaluation-v1'],
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence']
  };

  fn::add_observation_step($orch[0].observation_run_id, 10 + count(SELECT * FROM actor_evaluation_reports WHERE orchestration_id = $orchestration_id), 'record_actor_evaluation', { evaluator_id: $evaluator_id, evaluator_kind: $evaluator_kind }, { score: $score, confidence: $confidence, passed: $passed, report_id: $report.id }, 'completed', 'agx:multi-actor-evaluation-v1');
  RETURN $report;
};

DEFINE FUNCTION fn::evaluate_orchestration_completeness($orchestration_id) {
  LET $orch = SELECT * FROM $orchestration_id;
  IF count($orch) = 0 THEN { THROW 'evaluation_orchestration_not_found'; };
  LET $reports = SELECT * FROM actor_evaluation_reports WHERE orchestration_id = $orchestration_id;
  LET $self_count = count(SELECT * FROM $reports WHERE evaluator_kind = 'self');
  LET $peer_count = count(SELECT * FROM $reports WHERE evaluator_kind = 'peer');
  LET $orchestrator_count = count(SELECT * FROM $reports WHERE evaluator_kind = 'orchestrator');
  LET $complete =
    (!$orch[0].required_self_eval OR $self_count >= 1) AND
    ($peer_count >= $orch[0].required_peer_evals) AND
    (!$orch[0].required_orchestrator_eval OR $orchestrator_count >= 1);
  RETURN { complete: $complete, self_count: $self_count, peer_count: $peer_count, orchestrator_count: $orchestrator_count, required_peer_evals: $orch[0].required_peer_evals };
};

DEFINE FUNCTION fn::finalize_evaluation_orchestration($orchestration_id) {
  LET $orch = SELECT * FROM $orchestration_id;
  IF count($orch) = 0 THEN { THROW 'evaluation_orchestration_not_found'; };
  LET $complete = fn::evaluate_orchestration_completeness($orchestration_id);
  IF !$complete.complete THEN { THROW 'evaluation_orchestration_incomplete'; };

  LET $reports = SELECT * FROM actor_evaluation_reports WHERE orchestration_id = $orchestration_id;
  LET $self_reports = SELECT * FROM $reports WHERE evaluator_kind = 'self';
  LET $peer_reports = SELECT * FROM $reports WHERE evaluator_kind = 'peer';
  LET $orchestrator_reports = SELECT * FROM $reports WHERE evaluator_kind = 'orchestrator';
  LET $self_score = IF count($self_reports) = 0 THEN 0 ELSE math::mean($self_reports[*].score) END;
  LET $peer_score = IF count($peer_reports) = 0 THEN 0 ELSE math::mean($peer_reports[*].score) END;
  LET $orchestrator_score = IF count($orchestrator_reports) = 0 THEN 0 ELSE math::mean($orchestrator_reports[*].score) END;
  LET $final_score = fn::clamp01((0.20 * $self_score) + (0.45 * $peer_score) + (0.35 * $orchestrator_score));
  LET $failed = count(SELECT * FROM $reports WHERE passed = false);
  LET $decision = IF $final_score >= 0.80 AND $failed = 0 THEN 'passed' ELSE 'failed' END;

  UPDATE $orchestration_id SET status = 'completed', final_score = $final_score, final_decision = $decision, completed_at = time::now();
  fn::add_observation_step($orch[0].observation_run_id, 999, 'finalize_evaluation_orchestration', { report_count: count($reports), completeness: $complete }, { self_score: $self_score, peer_score: $peer_score, orchestrator_score: $orchestrator_score, final_score: $final_score, decision: $decision }, 'completed', 'agx:multi-actor-evaluation-v1');
  fn::finish_observation_run($orch[0].observation_run_id, 'completed', { final_score: $final_score, decision: $decision });

  CREATE reliability_eventS CONTENT {
    tenant_id: $orch[0].tenant_id,
    subject_id: $orch[0].subject_id,
    event_kind: 'multi_actor_evaluation',
    status: IF $decision = 'passed' THEN 'evaluation_passed' ELSE 'evaluation_failed' END,
    score: $final_score,
    source_id: string::concat($orchestration_id),
    payload: { orchestration_id: $orchestration_id, decision: $decision },
    observed_at: time::now(),
    created_at: time::now()
  };

  RETURN SELECT * FROM $orchestration_id;
};
