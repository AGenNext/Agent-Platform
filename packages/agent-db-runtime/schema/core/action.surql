-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Action Schema
-- ============================================================

-- Purpose:
-- Action is the canonical bridge between intent and execution.
-- Tasks implement actions. Policies govern actions. Tools execute actions.
-- Actions may map to schema.org Action, MCP tools, A2A messages,
-- AP2/UCP commerce/payment actions, human actions, and agent actions.

DEFINE TABLE action SCHEMAFULL;

DEFINE FIELD entity ON action TYPE record<entity>;
DEFINE FIELD action_type ON action TYPE string
  ASSERT $value IN [
    "create",
    "read",
    "update",
    "delete",
    "search",
    "observe",
    "notify",
    "approve",
    "reject",
    "assign",
    "delegate",
    "handoff",
    "escalate",
    "execute",
    "validate",
    "verify",
    "authenticate",
    "authorize",
    "transform",
    "generate",
    "classify",
    "summarize",
    "analyze",
    "decide",
    "recommend",
    "plan",
    "schedule",
    "publish",
    "deploy",
    "rollback",
    "reconcile",
    "pay",
    "buy",
    "sell",
    "quote",
    "order",
    "invoice",
    "refund",
    "settle"
  ];

DEFINE FIELD name ON action TYPE string;
DEFINE FIELD description ON action TYPE option<string>;
DEFINE FIELD status ON action TYPE string DEFAULT "draft"
  ASSERT $value IN ["draft", "active", "inactive", "deprecated", "archived"];

DEFINE FIELD input_schema ON action TYPE option<object>;
DEFINE FIELD output_schema ON action TYPE option<object>;
DEFINE FIELD preconditions ON action TYPE array<object> DEFAULT [];
DEFINE FIELD postconditions ON action TYPE array<object> DEFAULT [];
DEFINE FIELD invariants ON action TYPE array<object> DEFAULT [];

DEFINE FIELD risk_level ON action TYPE string DEFAULT "low"
  ASSERT $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD approval_required ON action TYPE bool DEFAULT false;
DEFINE FIELD human_required ON action TYPE bool DEFAULT false;
DEFINE FIELD deterministic ON action TYPE bool DEFAULT false;
DEFINE FIELD idempotent ON action TYPE bool DEFAULT false;
DEFINE FIELD reversible ON action TYPE bool DEFAULT false;

DEFINE FIELD schema_org_type ON action TYPE option<string>;
DEFINE FIELD protocol_refs ON action TYPE array<string> DEFAULT [];
DEFINE FIELD tool_refs ON action TYPE array<string> DEFAULT [];
DEFINE FIELD policy_refs ON action TYPE array<record<governance_object>> DEFAULT [];

DEFINE FIELD created_at ON action TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON action TYPE datetime VALUE time::now();
DEFINE FIELD valid_from ON action TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON action TYPE option<datetime>;
DEFINE FIELD metadata ON action TYPE option<object>;

DEFINE INDEX action_entity_idx ON action FIELDS entity UNIQUE;
DEFINE INDEX action_type_idx ON action FIELDS action_type;
DEFINE INDEX action_status_idx ON action FIELDS status;
DEFINE INDEX action_risk_idx ON action FIELDS risk_level;

-- ------------------------------------------------------------
-- Action Invocation
-- ------------------------------------------------------------

DEFINE TABLE action_invocation SCHEMAFULL;

DEFINE FIELD action ON action_invocation TYPE record<action>;
DEFINE FIELD subject ON action_invocation TYPE option<record<identity>>;
DEFINE FIELD resource ON action_invocation TYPE option<record<entity>>;
DEFINE FIELD status ON action_invocation TYPE string DEFAULT "requested"
  ASSERT $value IN [
    "requested",
    "authorized",
    "denied",
    "queued",
    "running",
    "completed",
    "failed",
    "cancelled",
    "needs_approval",
    "needs_more_context"
  ];

DEFINE FIELD input ON action_invocation TYPE object DEFAULT {};
DEFINE FIELD output ON action_invocation TYPE option<object>;
DEFINE FIELD error ON action_invocation TYPE option<string>;
DEFINE FIELD confidence ON action_invocation TYPE option<number>
  ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD policy_evaluations ON action_invocation TYPE array<record<policy_evaluation>> DEFAULT [];
DEFINE FIELD approval ON action_invocation TYPE option<record<governance_approval>>;
DEFINE FIELD evidence ON action_invocation TYPE option<object>;
DEFINE FIELD trace ON action_invocation TYPE option<object>;

DEFINE FIELD requested_at ON action_invocation TYPE datetime DEFAULT time::now();
DEFINE FIELD started_at ON action_invocation TYPE option<datetime>;
DEFINE FIELD completed_at ON action_invocation TYPE option<datetime>;
DEFINE FIELD updated_at ON action_invocation TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON action_invocation TYPE option<object>;

DEFINE INDEX action_invocation_action_idx ON action_invocation FIELDS action;
DEFINE INDEX action_invocation_subject_idx ON action_invocation FIELDS subject;
DEFINE INDEX action_invocation_resource_idx ON action_invocation FIELDS resource;
DEFINE INDEX action_invocation_status_idx ON action_invocation FIELDS status;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::request_action(
  $action: record<action>,
  $subject: option<record<identity>>,
  $resource: option<record<entity>>,
  $input: object
) {
  LET $action_record = SELECT * FROM ONLY $action;

  RETURN CREATE action_invocation SET
    action = $action,
    subject = $subject,
    resource = $resource,
    input = $input,
    status = IF $action_record.approval_required THEN "needs_approval" ELSE "requested" END;
};

DEFINE FUNCTION fn::complete_action(
  $invocation: record<action_invocation>,
  $output: object,
  $confidence: option<number>
) {
  RETURN UPDATE $invocation SET
    status = "completed",
    output = $output,
    confidence = $confidence,
    completed_at = time::now();
};

DEFINE FUNCTION fn::fail_action(
  $invocation: record<action_invocation>,
  $error: string,
  $evidence: option<object>
) {
  RETURN UPDATE $invocation SET
    status = "failed",
    error = $error,
    evidence = $evidence,
    completed_at = time::now();
};

DEFINE FUNCTION fn::action_requires_approval($action: record<action>) {
  LET $action_record = SELECT * FROM ONLY $action;
  RETURN $action_record.approval_required = true
    OR $action_record.human_required = true
    OR $action_record.risk_level IN ["high", "critical"];
};
