DEFINE TABLE evaluation_suites SCHEMAFULL;
DEFINE FIELD tenant_id ON evaluation_suites TYPE option<record<tenants>>;
DEFINE FIELD key ON evaluation_suites TYPE string;
DEFINE FIELD name ON evaluation_suites TYPE string;
DEFINE FIELD description ON evaluation_suites TYPE string;
DEFINE FIELD owner_id ON evaluation_suites TYPE string;
DEFINE FIELD status ON evaluation_suites TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON evaluation_suites TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON evaluation_suites TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:EvaluationSuite'];
DEFINE FIELD source_grounding_refs ON evaluation_suites TYPE array<string> DEFAULT ['arxiv:2402.12545', 'arxiv:2409.11242'];
DEFINE FIELD created_at ON evaluation_suites TYPE datetime DEFAULT time::now();
DEFINE INDEX evaluation_suites_key_unique ON evaluation_suites FIELDS tenant_id, key UNIQUE;

DEFINE TABLE evaluation_cases SCHEMAFULL;
DEFINE FIELD tenant_id ON evaluation_cases TYPE option<record<tenants>>;
DEFINE FIELD suite_id ON evaluation_cases TYPE record<evaluation_suites>;
DEFINE FIELD key ON evaluation_cases TYPE string;
DEFINE FIELD input ON evaluation_cases TYPE object;
DEFINE FIELD expected ON evaluation_cases TYPE object DEFAULT {};
DEFINE FIELD tags ON evaluation_cases TYPE array<string> DEFAULT [];
DEFINE FIELD risk_level ON evaluation_cases TYPE string DEFAULT 'medium';
DEFINE FIELD jsonld_context ON evaluation_cases TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON evaluation_cases TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:EvaluationCase'];
DEFINE FIELD created_at ON evaluation_cases TYPE datetime DEFAULT time::now();
DEFINE INDEX evaluation_cases_key_unique ON evaluation_cases FIELDS suite_id, key UNIQUE;

DEFINE TABLE evaluation_metrics SCHEMAFULL;
DEFINE FIELD tenant_id ON evaluation_metrics TYPE option<record<tenants>>;
DEFINE FIELD key ON evaluation_metrics TYPE string;
DEFINE FIELD name ON evaluation_metrics TYPE string;
DEFINE FIELD metric_kind ON evaluation_metrics TYPE string;
DEFINE FIELD min_pass_score ON evaluation_metrics TYPE number DEFAULT 0.7 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD weight ON evaluation_metrics TYPE number DEFAULT 1 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD jsonld_context ON evaluation_metrics TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON evaluation_metrics TYPE array<string> DEFAULT ['schema:PropertyValue', 'agx:EvaluationMetric'];
DEFINE FIELD source_grounding_refs ON evaluation_metrics TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON evaluation_metrics TYPE datetime DEFAULT time::now();
DEFINE INDEX evaluation_metrics_key_unique ON evaluation_metrics FIELDS tenant_id, key UNIQUE;

DEFINE TABLE evaluation_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON evaluation_runs TYPE option<record<tenants>>;
DEFINE FIELD suite_id ON evaluation_runs TYPE record<evaluation_suites>;
DEFINE FIELD agent_id ON evaluation_runs TYPE option<record<agents>>;
DEFINE FIELD subject_id ON evaluation_runs TYPE string;
DEFINE FIELD run_kind ON evaluation_runs TYPE string DEFAULT 'agent_evaluation';
DEFINE FIELD status ON evaluation_runs TYPE string DEFAULT 'running';
DEFINE FIELD started_at ON evaluation_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD ended_at ON evaluation_runs TYPE option<datetime>;
DEFINE FIELD observation_run_id ON evaluation_runs TYPE option<record<observation_runs>>;
DEFINE FIELD aggregate_score ON evaluation_runs TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD passed ON evaluation_runs TYPE option<bool>;
DEFINE FIELD jsonld_context ON evaluation_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON evaluation_runs TYPE array<string> DEFAULT ['schema:Action', 'agx:EvaluationRun'];
DEFINE FIELD source_grounding_refs ON evaluation_runs TYPE array<string> DEFAULT ['arxiv:2402.12545', 'arxiv:2409.11242'];

DEFINE TABLE evaluation_results SCHEMAFULL;
DEFINE FIELD tenant_id ON evaluation_results TYPE option<record<tenants>>;
DEFINE FIELD evaluation_run_id ON evaluation_results TYPE record<evaluation_runs>;
DEFINE FIELD case_id ON evaluation_results TYPE record<evaluation_cases>;
DEFINE FIELD metric_id ON evaluation_results TYPE record<evaluation_metrics>;
DEFINE FIELD score ON evaluation_results TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD passed ON evaluation_results TYPE bool;
DEFINE FIELD output ON evaluation_results TYPE object DEFAULT {};
DEFINE FIELD evidence_ids ON evaluation_results TYPE array<record<trust_evidence>> DEFAULT [];
DEFINE FIELD explanation ON evaluation_results TYPE object DEFAULT {};
DEFINE FIELD observed_at ON evaluation_results TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON evaluation_results TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON evaluation_results TYPE array<string> DEFAULT ['schema:Action', 'agx:EvaluationResult'];

DEFINE TABLE release_gates SCHEMAFULL;
DEFINE FIELD tenant_id ON release_gates TYPE option<record<tenants>>;
DEFINE FIELD key ON release_gates TYPE string;
DEFINE FIELD name ON release_gates TYPE string;
DEFINE FIELD min_aggregate_score ON release_gates TYPE number DEFAULT 0.8 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD require_all_cases_pass ON release_gates TYPE bool DEFAULT false;
DEFINE FIELD require_observable_steps ON release_gates TYPE bool DEFAULT true;
DEFINE FIELD required_observable_steps ON release_gates TYPE int DEFAULT 1;
DEFINE FIELD jsonld_context ON release_gates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_gates TYPE array<string> DEFAULT ['schema:Action', 'agx:ReleaseGate'];
DEFINE FIELD created_at ON release_gates TYPE datetime DEFAULT time::now();
DEFINE INDEX release_gates_key_unique ON release_gates FIELDS tenant_id, key UNIQUE;

DEFINE TABLE shipping_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON shipping_decisions TYPE option<record<tenants>>;
DEFINE FIELD evaluation_run_id ON shipping_decisions TYPE record<evaluation_runs>;
DEFINE FIELD release_gate_id ON shipping_decisions TYPE record<release_gates>;
DEFINE FIELD decision ON shipping_decisions TYPE string;
DEFINE FIELD reason ON shipping_decisions TYPE string;
DEFINE FIELD aggregate_score ON shipping_decisions TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD jsonld_context ON shipping_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON shipping_decisions TYPE array<string> DEFAULT ['schema:Action', 'agx:ShippingDecision'];
DEFINE FIELD created_at ON shipping_decisions TYPE datetime DEFAULT time::now();

UPSERT evaluation_metrics:behavioral_consistency CONTENT { tenant_id: NONE, key: 'behavioral_consistency', name: 'Behavioral Consistency', metric_kind: 'trustworthiness', min_pass_score: 0.75, weight: 0.20, source_grounding_refs: ['arxiv:2402.12545'] };
UPSERT evaluation_metrics:grounded_attribution CONTENT { tenant_id: NONE, key: 'grounded_attribution', name: 'Grounded Attribution', metric_kind: 'grounding', min_pass_score: 0.75, weight: 0.25, source_grounding_refs: ['arxiv:2409.11242'] };
UPSERT evaluation_metrics:citation_quality CONTENT { tenant_id: NONE, key: 'citation_quality', name: 'Citation Quality', metric_kind: 'grounding', min_pass_score: 0.70, weight: 0.15, source_grounding_refs: ['arxiv:2409.11242'] };
UPSERT evaluation_metrics:refusal_correctness CONTENT { tenant_id: NONE, key: 'refusal_correctness', name: 'Refusal Correctness', metric_kind: 'safety', min_pass_score: 0.70, weight: 0.20, source_grounding_refs: ['arxiv:2409.11242'] };
UPSERT evaluation_metrics:policy_compliance CONTENT { tenant_id: NONE, key: 'policy_compliance', name: 'Policy Compliance', metric_kind: 'guardrail', min_pass_score: 0.85, weight: 0.20, source_grounding_refs: [] };
UPSERT release_gates:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default Release Gate', min_aggregate_score: 0.80, require_all_cases_pass: false, require_observable_steps: true, required_observable_steps: 1 };

DEFINE FUNCTION fn::create_evaluation_suite($tenant_id, $key, $name, $description, $owner_id) {
  RETURN CREATE evaluation_suites CONTENT { tenant_id: $tenant_id, key: $key, name: $name, description: $description, owner_id: $owner_id, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::add_evaluation_case($tenant_id, $suite_id, $key, $input, $expected, $tags, $risk_level) {
  LET $suite = SELECT * FROM $suite_id;
  IF count($suite) = 0 THEN { THROW 'evaluation_suite_not_found'; };
  RETURN CREATE evaluation_cases CONTENT { tenant_id: $tenant_id, suite_id: $suite_id, key: $key, input: $input, expected: $expected, tags: $tags, risk_level: $risk_level, created_at: time::now() };
};

DEFINE FUNCTION fn::start_evaluation_run($tenant_id, $suite_id, $agent_id, $subject_id) {
  LET $suite = SELECT * FROM $suite_id;
  IF count($suite) = 0 THEN { THROW 'evaluation_suite_not_found'; };
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'evaluation_run', 'agx:evaluation-v1');
  LET $run = CREATE evaluation_runs CONTENT { tenant_id: $tenant_id, suite_id: $suite_id, agent_id: $agent_id, subject_id: $subject_id, status: 'running', started_at: time::now(), observation_run_id: $obs.id };
  fn::add_observation_step($obs.id, 1, 'start_evaluation_run', { suite_id: $suite_id, subject_id: $subject_id }, { evaluation_run_id: $run.id }, 'completed', 'agx:evaluation-v1');
  RETURN $run;
};

DEFINE FUNCTION fn::record_evaluation_result($tenant_id, $evaluation_run_id, $case_id, $metric_id, $score, $output, $evidence_ids, $explanation) {
  LET $metric = SELECT * FROM $metric_id;
  LET $run = SELECT * FROM $evaluation_run_id;
  IF count($metric) = 0 THEN { THROW 'evaluation_metric_not_found'; };
  IF count($run) = 0 THEN { THROW 'evaluation_run_not_found'; };
  LET $passed = $score >= $metric[0].min_pass_score;
  LET $result = CREATE evaluation_results CONTENT { tenant_id: $tenant_id, evaluation_run_id: $evaluation_run_id, case_id: $case_id, metric_id: $metric_id, score: $score, passed: $passed, output: $output, evidence_ids: $evidence_ids, explanation: $explanation, observed_at: time::now() };
  fn::add_observation_step($run[0].observation_run_id, 100 + count(SELECT * FROM evaluation_results WHERE evaluation_run_id = $evaluation_run_id), 'record_evaluation_result', { case_id: $case_id, metric_id: $metric_id }, { score: $score, passed: $passed, result_id: $result.id }, 'completed', 'agx:evaluation-v1');
  RETURN $result;
};

DEFINE FUNCTION fn::finalize_evaluation_run($evaluation_run_id) {
  LET $run = SELECT * FROM $evaluation_run_id;
  IF count($run) = 0 THEN { THROW 'evaluation_run_not_found'; };
  LET $results = SELECT * FROM evaluation_results WHERE evaluation_run_id = $evaluation_run_id;
  IF count($results) = 0 THEN { THROW 'evaluation_results_required'; };
  LET $aggregate = fn::clamp01(math::mean($results[*].score));
  LET $passed = $aggregate >= 0.80 AND count(SELECT * FROM $results WHERE passed = false) = 0;
  UPDATE $evaluation_run_id SET status = 'completed', ended_at = time::now(), aggregate_score = $aggregate, passed = $passed;
  fn::add_observation_step($run[0].observation_run_id, 999, 'finalize_evaluation_run', { result_count: count($results) }, { aggregate_score: $aggregate, passed: $passed }, 'completed', 'agx:evaluation-v1');
  fn::finish_observation_run($run[0].observation_run_id, 'completed', { aggregate_score: $aggregate, passed: $passed });
  RETURN SELECT * FROM $evaluation_run_id;
};

DEFINE FUNCTION fn::evaluate_release_gate($tenant_id, $evaluation_run_id, $release_gate_id) {
  LET $run = SELECT * FROM $evaluation_run_id;
  LET $gate = SELECT * FROM $release_gate_id;
  IF count($run) = 0 THEN { THROW 'evaluation_run_not_found'; };
  IF count($gate) = 0 THEN { THROW 'release_gate_not_found'; };
  IF $run[0].status != 'completed' THEN { THROW 'evaluation_run_not_completed'; };
  IF $gate[0].require_observable_steps THEN { fn::require_observable_steps($run[0].observation_run_id, $gate[0].required_observable_steps); };
  LET $failed_results = SELECT * FROM evaluation_results WHERE evaluation_run_id = $evaluation_run_id AND passed = false;
  LET $score_pass = $run[0].aggregate_score >= $gate[0].min_aggregate_score;
  LET $case_pass = IF $gate[0].require_all_cases_pass THEN count($failed_results) = 0 ELSE true END;
  LET $decision = IF $score_pass AND $case_pass THEN 'approved_for_shipping' ELSE 'blocked' END;
  LET $reason = IF $score_pass AND $case_pass THEN 'release_gate_passed' ELSE 'release_gate_failed' END;
  RETURN CREATE shipping_decisions CONTENT { tenant_id: $tenant_id, evaluation_run_id: $evaluation_run_id, release_gate_id: $release_gate_id, decision: $decision, reason: $reason, aggregate_score: $run[0].aggregate_score, created_at: time::now() };
};
