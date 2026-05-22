-- AGenNext Platform
-- 0060: Decision intelligence simulation, evaluation, implementation, and review
-- Purpose: extend the enterprise decision log into a complete decision intelligence lifecycle.

DEFINE TABLE decision_simulations SCHEMAFULL;
DEFINE FIELD decision_id ON decision_simulations TYPE record<enterprise_decision_logs>;
DEFINE FIELD simulation_ref ON decision_simulations TYPE string;
DEFINE FIELD simulation_name ON decision_simulations TYPE string;
DEFINE FIELD simulation_kind ON decision_simulations TYPE string DEFAULT 'scenario_analysis';
DEFINE FIELD assumptions ON decision_simulations TYPE array<object> DEFAULT [];
DEFINE FIELD scenarios ON decision_simulations TYPE array<object> DEFAULT [];
DEFINE FIELD constraints ON decision_simulations TYPE array<object> DEFAULT [];
DEFINE FIELD success_metrics ON decision_simulations TYPE array<object> DEFAULT [];
DEFINE FIELD risk_model ON decision_simulations TYPE object DEFAULT {};
DEFINE FIELD status ON decision_simulations TYPE string DEFAULT 'draft';
DEFINE FIELD created_by_person_id ON decision_simulations TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON decision_simulations TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON decision_simulations TYPE option<datetime>;
DEFINE INDEX decision_simulation_ref_unique ON decision_simulations FIELDS simulation_ref UNIQUE;

DEFINE TABLE decision_simulation_results SCHEMAFULL;
DEFINE FIELD simulation_id ON decision_simulation_results TYPE record<decision_simulations>;
DEFINE FIELD scenario_key ON decision_simulation_results TYPE string;
DEFINE FIELD outcome_summary ON decision_simulation_results TYPE string;
DEFINE FIELD score ON decision_simulation_results TYPE number DEFAULT 0;
DEFINE FIELD confidence ON decision_simulation_results TYPE number DEFAULT 0;
DEFINE FIELD benefits ON decision_simulation_results TYPE array<object> DEFAULT [];
DEFINE FIELD costs ON decision_simulation_results TYPE array<object> DEFAULT [];
DEFINE FIELD risks ON decision_simulation_results TYPE array<object> DEFAULT [];
DEFINE FIELD tradeoffs ON decision_simulation_results TYPE array<object> DEFAULT [];
DEFINE FIELD recommendation ON decision_simulation_results TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON decision_simulation_results TYPE datetime DEFAULT time::now();

DEFINE TABLE decision_evaluations SCHEMAFULL;
DEFINE FIELD decision_id ON decision_evaluations TYPE record<enterprise_decision_logs>;
DEFINE FIELD evaluation_ref ON decision_evaluations TYPE string;
DEFINE FIELD evaluation_name ON decision_evaluations TYPE string;
DEFINE FIELD evaluation_framework ON decision_evaluations TYPE string DEFAULT 'weighted_scorecard';
DEFINE FIELD criteria ON decision_evaluations TYPE array<object> DEFAULT [];
DEFINE FIELD evidence_refs ON decision_evaluations TYPE array<string> DEFAULT [];
DEFINE FIELD evaluator_roles ON decision_evaluations TYPE array<string> DEFAULT [];
DEFINE FIELD evaluation_status ON decision_evaluations TYPE string DEFAULT 'in_review';
DEFINE FIELD final_score ON decision_evaluations TYPE number DEFAULT 0;
DEFINE FIELD decision_recommendation ON decision_evaluations TYPE string DEFAULT 'continue_review';
DEFINE FIELD created_at ON decision_evaluations TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON decision_evaluations TYPE option<datetime>;
DEFINE INDEX decision_evaluation_ref_unique ON decision_evaluations FIELDS evaluation_ref UNIQUE;

DEFINE TABLE decision_implementation_plans SCHEMAFULL;
DEFINE FIELD decision_id ON decision_implementation_plans TYPE record<enterprise_decision_logs>;
DEFINE FIELD implementation_ref ON decision_implementation_plans TYPE string;
DEFINE FIELD implementation_name ON decision_implementation_plans TYPE string;
DEFINE FIELD owner_role ON decision_implementation_plans TYPE string;
DEFINE FIELD owner_person_id ON decision_implementation_plans TYPE option<record<identity_persons>>;
DEFINE FIELD target_environment ON decision_implementation_plans TYPE string DEFAULT 'sandbox';
DEFINE FIELD milestones ON decision_implementation_plans TYPE array<object> DEFAULT [];
DEFINE FIELD dependencies ON decision_implementation_plans TYPE array<object> DEFAULT [];
DEFINE FIELD rollback_plan ON decision_implementation_plans TYPE object DEFAULT {};
DEFINE FIELD controls ON decision_implementation_plans TYPE array<object> DEFAULT [];
DEFINE FIELD status ON decision_implementation_plans TYPE string DEFAULT 'planned';
DEFINE FIELD created_at ON decision_implementation_plans TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON decision_implementation_plans TYPE datetime DEFAULT time::now();
DEFINE INDEX decision_implementation_ref_unique ON decision_implementation_plans FIELDS implementation_ref UNIQUE;

DEFINE TABLE decision_reviews SCHEMAFULL;
DEFINE FIELD decision_id ON decision_reviews TYPE record<enterprise_decision_logs>;
DEFINE FIELD implementation_id ON decision_reviews TYPE option<record<decision_implementation_plans>>;
DEFINE FIELD review_ref ON decision_reviews TYPE string;
DEFINE FIELD review_kind ON decision_reviews TYPE string DEFAULT 'post_implementation_review';
DEFINE FIELD scheduled_at ON decision_reviews TYPE datetime;
DEFINE FIELD reviewer_roles ON decision_reviews TYPE array<string> DEFAULT [];
DEFINE FIELD expected_outcomes ON decision_reviews TYPE array<object> DEFAULT [];
DEFINE FIELD actual_outcomes ON decision_reviews TYPE array<object> DEFAULT [];
DEFINE FIELD variance_analysis ON decision_reviews TYPE array<object> DEFAULT [];
DEFINE FIELD lessons_learned ON decision_reviews TYPE array<object> DEFAULT [];
DEFINE FIELD review_status ON decision_reviews TYPE string DEFAULT 'scheduled';
DEFINE FIELD created_at ON decision_reviews TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON decision_reviews TYPE option<datetime>;
DEFINE INDEX decision_review_ref_unique ON decision_reviews FIELDS review_ref UNIQUE;

DEFINE FUNCTION fn::create_decision_simulation(
  $decision_id: record<enterprise_decision_logs>,
  $simulation_name: string,
  $simulation_kind: string,
  $assumptions: array<object>,
  $scenarios: array<object>,
  $constraints: array<object>,
  $success_metrics: array<object>,
  $risk_model: object,
  $created_by_person_id: option<record<identity_persons>>
) {
  LET $decision = SELECT * FROM ONLY $decision_id;
  IF $decision = NONE THEN { THROW 'enterprise_decision_not_found'; };

  RETURN CREATE decision_simulations CONTENT {
    decision_id: $decision_id,
    simulation_ref: rand::uuid(),
    simulation_name: $simulation_name,
    simulation_kind: $simulation_kind,
    assumptions: $assumptions,
    scenarios: $scenarios,
    constraints: $constraints,
    success_metrics: $success_metrics,
    risk_model: $risk_model,
    status: 'ready_to_run',
    created_by_person_id: $created_by_person_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::record_decision_simulation_result(
  $simulation_id: record<decision_simulations>,
  $scenario_key: string,
  $outcome_summary: string,
  $score: number,
  $confidence: number,
  $benefits: array<object>,
  $costs: array<object>,
  $risks: array<object>,
  $tradeoffs: array<object>,
  $recommendation: string
) {
  CREATE decision_simulation_results CONTENT {
    simulation_id: $simulation_id,
    scenario_key: $scenario_key,
    outcome_summary: $outcome_summary,
    score: $score,
    confidence: $confidence,
    benefits: $benefits,
    costs: $costs,
    risks: $risks,
    tradeoffs: $tradeoffs,
    recommendation: $recommendation,
    created_at: time::now()
  };
  UPDATE $simulation_id SET status = 'completed', completed_at = time::now();
  RETURN SELECT * FROM decision_simulation_results WHERE simulation_id = $simulation_id ORDER BY score DESC;
};

DEFINE FUNCTION fn::create_decision_evaluation(
  $decision_id: record<enterprise_decision_logs>,
  $evaluation_name: string,
  $evaluation_framework: string,
  $criteria: array<object>,
  $evidence_refs: array<string>,
  $evaluator_roles: array<string>
) {
  RETURN CREATE decision_evaluations CONTENT {
    decision_id: $decision_id,
    evaluation_ref: rand::uuid(),
    evaluation_name: $evaluation_name,
    evaluation_framework: $evaluation_framework,
    criteria: $criteria,
    evidence_refs: $evidence_refs,
    evaluator_roles: $evaluator_roles,
    evaluation_status: 'in_review',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::complete_decision_evaluation(
  $evaluation_id: record<decision_evaluations>,
  $final_score: number,
  $decision_recommendation: string
) {
  RETURN UPDATE $evaluation_id SET
    final_score = $final_score,
    decision_recommendation = $decision_recommendation,
    evaluation_status = 'completed',
    completed_at = time::now();
};

DEFINE FUNCTION fn::create_decision_implementation_plan(
  $decision_id: record<enterprise_decision_logs>,
  $implementation_name: string,
  $owner_role: string,
  $owner_person_id: option<record<identity_persons>>,
  $target_environment: string,
  $milestones: array<object>,
  $dependencies: array<object>,
  $rollback_plan: object,
  $controls: array<object>
) {
  LET $decision = SELECT * FROM ONLY $decision_id;
  IF $decision.decision_status != 'accepted' THEN { THROW 'decision_must_be_accepted_before_implementation'; };

  RETURN CREATE decision_implementation_plans CONTENT {
    decision_id: $decision_id,
    implementation_ref: rand::uuid(),
    implementation_name: $implementation_name,
    owner_role: $owner_role,
    owner_person_id: $owner_person_id,
    target_environment: $target_environment,
    milestones: $milestones,
    dependencies: $dependencies,
    rollback_plan: $rollback_plan,
    controls: $controls,
    status: 'planned',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::schedule_decision_review(
  $decision_id: record<enterprise_decision_logs>,
  $implementation_id: option<record<decision_implementation_plans>>,
  $review_kind: string,
  $scheduled_at: datetime,
  $reviewer_roles: array<string>,
  $expected_outcomes: array<object>
) {
  RETURN CREATE decision_reviews CONTENT {
    decision_id: $decision_id,
    implementation_id: $implementation_id,
    review_ref: rand::uuid(),
    review_kind: $review_kind,
    scheduled_at: $scheduled_at,
    reviewer_roles: $reviewer_roles,
    expected_outcomes: $expected_outcomes,
    review_status: 'scheduled',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::complete_decision_review(
  $review_id: record<decision_reviews>,
  $actual_outcomes: array<object>,
  $variance_analysis: array<object>,
  $lessons_learned: array<object>
) {
  RETURN UPDATE $review_id SET
    actual_outcomes = $actual_outcomes,
    variance_analysis = $variance_analysis,
    lessons_learned = $lessons_learned,
    review_status = 'completed',
    completed_at = time::now();
};

DEFINE FUNCTION fn::decision_intelligence_context($decision_id: record<enterprise_decision_logs>) {
  RETURN {
    decision: SELECT * FROM ONLY $decision_id,
    simulations: SELECT * FROM decision_simulations WHERE decision_id = $decision_id ORDER BY created_at DESC,
    simulation_results: SELECT * FROM decision_simulation_results WHERE simulation_id IN (SELECT id FROM decision_simulations WHERE decision_id = $decision_id) ORDER BY score DESC,
    evaluations: SELECT * FROM decision_evaluations WHERE decision_id = $decision_id ORDER BY created_at DESC,
    implementation_plans: SELECT * FROM decision_implementation_plans WHERE decision_id = $decision_id ORDER BY created_at DESC,
    reviews: SELECT * FROM decision_reviews WHERE decision_id = $decision_id ORDER BY scheduled_at DESC
  };
};
