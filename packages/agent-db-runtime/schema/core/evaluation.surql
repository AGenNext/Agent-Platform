-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Evaluation Schema
-- ============================================================

-- Purpose:
-- Evaluation determines whether work was correct, complete, compliant,
-- safe, aligned, cost-effective, timely, and trustworthy. It supports
-- self review, peer review, human review, automated review, benchmark
-- scoring, maturity scoring, and governance conformance checks.

DEFINE TABLE evaluation SCHEMAFULL;

DEFINE FIELD entity ON evaluation TYPE record<entity>;
DEFINE FIELD target ON evaluation TYPE record<entity>;
DEFINE FIELD evaluator ON evaluation TYPE option<record<identity>>;
DEFINE FIELD task ON evaluation TYPE option<record<task>>;
DEFINE FIELD decision ON evaluation TYPE option<record<decision>>;
DEFINE FIELD action_invocation ON evaluation TYPE option<record<action_invocation>>;

DEFINE FIELD evaluation_type ON evaluation TYPE string
  ASSERT $value IN [
    "self_review",
    "peer_review",
    "human_review",
    "automated_review",
    "benchmark",
    "maturity_assessment",
    "trust_assessment",
    "policy_compliance",
    "protocol_compliance",
    "standard_conformance",
    "security_review",
    "safety_review",
    "quality_review",
    "cost_review",
    "latency_review",
    "completeness_review",
    "correctness_review",
    "internal_alignment",
    "external_conformance"
  ];

DEFINE FIELD status ON evaluation TYPE string DEFAULT "draft"
  ASSERT $value IN ["draft", "running", "completed", "failed", "needs_review", "archived"];

DEFINE FIELD method ON evaluation TYPE string DEFAULT "manual"
  ASSERT $value IN ["manual", "rule_based", "llm_judge", "benchmark", "unit_test", "integration_test", "policy_engine", "hybrid"];

DEFINE FIELD criteria ON evaluation TYPE array<object> DEFAULT [];
DEFINE FIELD findings ON evaluation TYPE array<object> DEFAULT [];
DEFINE FIELD recommendations ON evaluation TYPE array<object> DEFAULT [];
DEFINE FIELD evidence ON evaluation TYPE option<object>;
DEFINE FIELD score ON evaluation TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD grade ON evaluation TYPE option<string> ASSERT $value = NONE OR $value IN ["A", "B", "C", "D", "E", "F", "pass", "fail"];
DEFINE FIELD confidence ON evaluation TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD dimensions ON evaluation TYPE object DEFAULT {
  correctness: NONE,
  completeness: NONE,
  compliance: NONE,
  safety: NONE,
  security: NONE,
  latency: NONE,
  cost: NONE,
  quality: NONE,
  alignment: NONE,
  trustworthiness: NONE
};

DEFINE FIELD policy_evaluations ON evaluation TYPE array<record<policy_evaluation>> DEFAULT [];
DEFINE FIELD validation_results ON evaluation TYPE array<record<validation_result>> DEFAULT [];
DEFINE FIELD created_at ON evaluation TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON evaluation TYPE datetime VALUE time::now();
DEFINE FIELD completed_at ON evaluation TYPE option<datetime>;
DEFINE FIELD metadata ON evaluation TYPE option<object>;

DEFINE INDEX evaluation_entity_idx ON evaluation FIELDS entity UNIQUE;
DEFINE INDEX evaluation_target_idx ON evaluation FIELDS target;
DEFINE INDEX evaluation_type_idx ON evaluation FIELDS evaluation_type;
DEFINE INDEX evaluation_status_idx ON evaluation FIELDS status;
DEFINE INDEX evaluation_score_idx ON evaluation FIELDS score;

-- ------------------------------------------------------------
-- Evaluation Metric
-- ------------------------------------------------------------

DEFINE TABLE evaluation_metric SCHEMAFULL;

DEFINE FIELD evaluation ON evaluation_metric TYPE record<evaluation>;
DEFINE FIELD name ON evaluation_metric TYPE string;
DEFINE FIELD category ON evaluation_metric TYPE string
  ASSERT $value IN [
    "correctness",
    "completeness",
    "compliance",
    "safety",
    "security",
    "latency",
    "cost",
    "quality",
    "alignment",
    "trustworthiness",
    "reliability",
    "usability",
    "maintainability"
  ];

DEFINE FIELD value ON evaluation_metric TYPE number;
DEFINE FIELD unit ON evaluation_metric TYPE option<string>;
DEFINE FIELD threshold ON evaluation_metric TYPE option<number>;
DEFINE FIELD passed ON evaluation_metric TYPE option<bool>;
DEFINE FIELD evidence ON evaluation_metric TYPE option<object>;
DEFINE FIELD created_at ON evaluation_metric TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON evaluation_metric TYPE option<object>;

DEFINE INDEX evaluation_metric_evaluation_idx ON evaluation_metric FIELDS evaluation;
DEFINE INDEX evaluation_metric_category_idx ON evaluation_metric FIELDS category;
DEFINE INDEX evaluation_metric_name_idx ON evaluation_metric FIELDS name;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_evaluation(
  $entity: record<entity>,
  $target: record<entity>,
  $evaluation_type: string,
  $method: string,
  $evaluator: option<record<identity>>,
  $score: option<number>,
  $grade: option<string>,
  $confidence: option<number>,
  $findings: array<object>,
  $recommendations: array<object>,
  $evidence: option<object>
) {
  RETURN CREATE evaluation SET
    entity = $entity,
    target = $target,
    evaluation_type = $evaluation_type,
    method = $method,
    evaluator = $evaluator,
    status = "completed",
    score = $score,
    grade = $grade,
    confidence = $confidence,
    findings = $findings,
    recommendations = $recommendations,
    evidence = $evidence,
    completed_at = time::now();
};

DEFINE FUNCTION fn::record_evaluation_metric(
  $evaluation: record<evaluation>,
  $name: string,
  $category: string,
  $value: number,
  $unit: option<string>,
  $threshold: option<number>,
  $evidence: option<object>
) {
  RETURN CREATE evaluation_metric SET
    evaluation = $evaluation,
    name = $name,
    category = $category,
    value = $value,
    unit = $unit,
    threshold = $threshold,
    passed = IF $threshold = NONE THEN NONE ELSE $value >= $threshold END,
    evidence = $evidence;
};

DEFINE FUNCTION fn::evaluation_passed($evaluation: record<evaluation>) {
  LET $e = SELECT * FROM ONLY $evaluation;
  RETURN $e.status = "completed"
    AND (
      ($e.score != NONE AND $e.score >= 0.70)
      OR $e.grade IN ["A", "B", "pass"]
    );
};

DEFINE FUNCTION fn::evaluation_needs_review($evaluation: record<evaluation>) {
  LET $e = SELECT * FROM ONLY $evaluation;
  RETURN $e.status = "needs_review"
    OR ($e.score != NONE AND $e.score < 0.70)
    OR ($e.confidence != NONE AND $e.confidence < 0.70)
    OR $e.grade IN ["D", "E", "F", "fail"];
};
