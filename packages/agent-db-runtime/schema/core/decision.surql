-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Decision Schema
-- ============================================================

-- Purpose:
-- Decision explains why work happened. Actions describe capability,
-- tasks track execution, and decisions preserve context, options,
-- constraints, tradeoffs, evidence, policy results, confidence,
-- approvals, and selected outcomes for replay and governance.

DEFINE TABLE decision SCHEMAFULL;

DEFINE FIELD entity ON decision TYPE record<entity>;
DEFINE FIELD task ON decision TYPE option<record<task>>;
DEFINE FIELD action_invocation ON decision TYPE option<record<action_invocation>>;
DEFINE FIELD subject ON decision TYPE option<record<identity>>;
DEFINE FIELD resource ON decision TYPE option<record<entity>>;

DEFINE FIELD decision_type ON decision TYPE string
  ASSERT $value IN [
    "classification",
    "routing",
    "prioritization",
    "approval",
    "rejection",
    "delegation",
    "handoff",
    "tool_selection",
    "model_selection",
    "policy_decision",
    "risk_decision",
    "security_decision",
    "commerce_decision",
    "payment_decision",
    "workflow_decision",
    "reconciliation_decision",
    "evaluation_decision",
    "trust_decision",
    "human_decision",
    "agent_decision"
  ];

DEFINE FIELD title ON decision TYPE string;
DEFINE FIELD question ON decision TYPE option<string>;
DEFINE FIELD context ON decision TYPE object DEFAULT {};
DEFINE FIELD intent ON decision TYPE option<string>;
DEFINE FIELD constraints ON decision TYPE array<object> DEFAULT [];
DEFINE FIELD objectives ON decision TYPE array<object> DEFAULT [];
DEFINE FIELD options ON decision TYPE array<object> DEFAULT [];
DEFINE FIELD tradeoffs ON decision TYPE array<object> DEFAULT [];
DEFINE FIELD selected_option ON decision TYPE option<object>;
DEFINE FIELD rejected_options ON decision TYPE array<object> DEFAULT [];

DEFINE FIELD status ON decision TYPE string DEFAULT "proposed"
  ASSERT $value IN [
    "proposed",
    "accepted",
    "rejected",
    "superseded",
    "reversed",
    "needs_approval",
    "approved",
    "archived"
  ];

DEFINE FIELD outcome ON decision TYPE option<object>;
DEFINE FIELD reason_summary ON decision TYPE string;
DEFINE FIELD evidence ON decision TYPE option<object>;
DEFINE FIELD policy_evaluations ON decision TYPE array<record<policy_evaluation>> DEFAULT [];
DEFINE FIELD approval ON decision TYPE option<record<governance_approval>>;

DEFINE FIELD confidence ON decision TYPE option<number>
  ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD risk_level ON decision TYPE string DEFAULT "low"
  ASSERT $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD reversible ON decision TYPE bool DEFAULT false;
DEFINE FIELD replayable ON decision TYPE bool DEFAULT true;
DEFINE FIELD supersedes ON decision TYPE option<record<decision>>;
DEFINE FIELD decided_by ON decision TYPE option<record<identity>>;
DEFINE FIELD decided_at ON decision TYPE datetime DEFAULT time::now();
DEFINE FIELD created_at ON decision TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON decision TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON decision TYPE option<object>;

DEFINE INDEX decision_entity_idx ON decision FIELDS entity UNIQUE;
DEFINE INDEX decision_task_idx ON decision FIELDS task;
DEFINE INDEX decision_type_idx ON decision FIELDS decision_type;
DEFINE INDEX decision_status_idx ON decision FIELDS status;
DEFINE INDEX decision_subject_idx ON decision FIELDS subject;
DEFINE INDEX decision_resource_idx ON decision FIELDS resource;
DEFINE INDEX decision_risk_idx ON decision FIELDS risk_level;

-- ------------------------------------------------------------
-- Decision Event
-- ------------------------------------------------------------

DEFINE TABLE decision_event SCHEMAFULL;

DEFINE FIELD decision ON decision_event TYPE record<decision>;
DEFINE FIELD event_type ON decision_event TYPE string
  ASSERT $value IN [
    "created",
    "proposed",
    "accepted",
    "rejected",
    "approved",
    "superseded",
    "reversed",
    "evidence_added",
    "policy_evaluated",
    "replayed",
    "archived"
  ];

DEFINE FIELD actor ON decision_event TYPE option<record<identity>>;
DEFINE FIELD from_status ON decision_event TYPE option<string>;
DEFINE FIELD to_status ON decision_event TYPE option<string>;
DEFINE FIELD reason ON decision_event TYPE option<string>;
DEFINE FIELD payload ON decision_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON decision_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON decision_event TYPE option<object>;

DEFINE INDEX decision_event_decision_idx ON decision_event FIELDS decision;
DEFINE INDEX decision_event_type_idx ON decision_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_decision(
  $entity: record<entity>,
  $decision_type: string,
  $title: string,
  $reason_summary: string,
  $subject: option<record<identity>>,
  $resource: option<record<entity>>,
  $task: option<record<task>>,
  $context: object,
  $options: array<object>,
  $selected_option: option<object>,
  $confidence: option<number>,
  $risk_level: string
) {
  LET $created = CREATE decision SET
    entity = $entity,
    decision_type = $decision_type,
    title = $title,
    reason_summary = $reason_summary,
    subject = $subject,
    resource = $resource,
    task = $task,
    context = $context,
    options = $options,
    selected_option = $selected_option,
    confidence = $confidence,
    risk_level = $risk_level,
    status = IF $risk_level IN ["high", "critical"] THEN "needs_approval" ELSE "accepted" END;

  CREATE decision_event SET
    decision = $created.id,
    event_type = "created",
    actor = $subject,
    to_status = $created.status,
    payload = { confidence: $confidence, risk_level: $risk_level };

  RETURN $created;
};

DEFINE FUNCTION fn::accept_decision(
  $decision: record<decision>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $before = SELECT * FROM ONLY $decision;

  LET $updated = UPDATE $decision SET
    status = "accepted",
    decided_by = $actor,
    decided_at = time::now();

  CREATE decision_event SET
    decision = $decision,
    event_type = "accepted",
    actor = $actor,
    from_status = $before.status,
    to_status = "accepted",
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::reject_decision(
  $decision: record<decision>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $before = SELECT * FROM ONLY $decision;

  LET $updated = UPDATE $decision SET
    status = "rejected",
    decided_by = $actor,
    decided_at = time::now();

  CREATE decision_event SET
    decision = $decision,
    event_type = "rejected",
    actor = $actor,
    from_status = $before.status,
    to_status = "rejected",
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::supersede_decision(
  $old_decision: record<decision>,
  $new_decision: record<decision>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  UPDATE $old_decision SET status = "superseded";
  UPDATE $new_decision SET supersedes = $old_decision;

  RETURN CREATE decision_event SET
    decision = $old_decision,
    event_type = "superseded",
    actor = $actor,
    from_status = "accepted",
    to_status = "superseded",
    reason = $reason,
    payload = { new_decision: $new_decision };
};

DEFINE FUNCTION fn::decision_needs_approval($decision: record<decision>) {
  LET $d = SELECT * FROM ONLY $decision;
  RETURN $d.status = "needs_approval"
    OR $d.risk_level IN ["high", "critical"]
    OR ($d.confidence != NONE AND $d.confidence < 0.70);
};
