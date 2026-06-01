-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Governance Schema
-- ============================================================

-- Purpose:
-- Governance defines the policy, framework, standard, protocol,
-- compliance control, risk, constraint, objective, approval,
-- delegation, and escalation layer for agents and humans.

DEFINE TABLE governance_object SCHEMAFULL;

DEFINE FIELD entity ON governance_object TYPE record<entity>;
DEFINE FIELD governance_type ON governance_object TYPE string
  ASSERT $value IN [
    "policy",
    "framework",
    "standard",
    "protocol",
    "regulation",
    "compliance_control",
    "constraint",
    "objective",
    "risk",
    "approval_rule",
    "delegation_rule",
    "escalation_rule",
    "agent_constitution",
    "operating_model",
    "playbook",
    "runbook"
  ];

DEFINE FIELD code ON governance_object TYPE string;
DEFINE FIELD title ON governance_object TYPE string;
DEFINE FIELD description ON governance_object TYPE option<string>;
DEFINE FIELD status ON governance_object TYPE string DEFAULT "draft"
  ASSERT $value IN ["draft", "active", "inactive", "deprecated", "archived"];

DEFINE FIELD severity ON governance_object TYPE option<string>
  ASSERT $value = NONE OR $value IN ["info", "low", "medium", "high", "critical"];

DEFINE FIELD priority ON governance_object TYPE option<string>
  ASSERT $value = NONE OR $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD applies_to_entity_types ON governance_object TYPE array<string> DEFAULT [];
DEFINE FIELD applies_to_actions ON governance_object TYPE array<string> DEFAULT [];
DEFINE FIELD applies_to_environments ON governance_object TYPE array<string> DEFAULT [];
DEFINE FIELD rule ON governance_object TYPE option<object>;
DEFINE FIELD expression_language ON governance_object TYPE option<string>
  ASSERT $value = NONE OR $value IN ["surrealql", "rego", "cel", "jsonlogic", "authzen", "openfga", "natural_language"];

DEFINE FIELD external_ref ON governance_object TYPE option<string>;
DEFINE FIELD owner ON governance_object TYPE option<record<identity>>;
DEFINE FIELD created_at ON governance_object TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON governance_object TYPE datetime VALUE time::now();
DEFINE FIELD valid_from ON governance_object TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON governance_object TYPE option<datetime>;
DEFINE FIELD metadata ON governance_object TYPE option<object>;

DEFINE INDEX governance_entity_idx ON governance_object FIELDS entity UNIQUE;
DEFINE INDEX governance_type_idx ON governance_object FIELDS governance_type;
DEFINE INDEX governance_code_idx ON governance_object FIELDS code UNIQUE;
DEFINE INDEX governance_status_idx ON governance_object FIELDS status;

-- ------------------------------------------------------------
-- Policy Evaluation
-- ------------------------------------------------------------

DEFINE TABLE policy_evaluation SCHEMAFULL;

DEFINE FIELD governance_object ON policy_evaluation TYPE record<governance_object>;
DEFINE FIELD subject ON policy_evaluation TYPE option<record<identity>>;
DEFINE FIELD action ON policy_evaluation TYPE option<string>;
DEFINE FIELD resource ON policy_evaluation TYPE option<record<entity>>;
DEFINE FIELD environment ON policy_evaluation TYPE option<object>;

DEFINE FIELD decision ON policy_evaluation TYPE string
  ASSERT $value IN ["allow", "deny", "abstain", "needs_approval", "needs_more_context"];

DEFINE FIELD confidence ON policy_evaluation TYPE option<number>
  ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD reason ON policy_evaluation TYPE option<string>;
DEFINE FIELD obligations ON policy_evaluation TYPE array<object> DEFAULT [];
DEFINE FIELD advice ON policy_evaluation TYPE array<object> DEFAULT [];
DEFINE FIELD evidence ON policy_evaluation TYPE option<object>;
DEFINE FIELD engine ON policy_evaluation TYPE option<string>
  ASSERT $value = NONE OR $value IN ["surrealdb", "opa", "openfga", "authzen", "manual", "external"];

DEFINE FIELD created_at ON policy_evaluation TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON policy_evaluation TYPE option<object>;

DEFINE INDEX policy_eval_governance_idx ON policy_evaluation FIELDS governance_object;
DEFINE INDEX policy_eval_subject_idx ON policy_evaluation FIELDS subject;
DEFINE INDEX policy_eval_resource_idx ON policy_evaluation FIELDS resource;
DEFINE INDEX policy_eval_decision_idx ON policy_evaluation FIELDS decision;

-- ------------------------------------------------------------
-- Approval Request
-- ------------------------------------------------------------

DEFINE TABLE governance_approval SCHEMAFULL;

DEFINE FIELD subject ON governance_approval TYPE option<record<identity>>;
DEFINE FIELD resource ON governance_approval TYPE option<record<entity>>;
DEFINE FIELD requested_action ON governance_approval TYPE string;
DEFINE FIELD policy_evaluation ON governance_approval TYPE option<record<policy_evaluation>>;
DEFINE FIELD status ON governance_approval TYPE string DEFAULT "pending"
  ASSERT $value IN ["pending", "approved", "rejected", "expired", "cancelled"];

DEFINE FIELD reason ON governance_approval TYPE option<string>;
DEFINE FIELD approver ON governance_approval TYPE option<record<identity>>;
DEFINE FIELD approver_comment ON governance_approval TYPE option<string>;
DEFINE FIELD expires_at ON governance_approval TYPE option<datetime>;
DEFINE FIELD decided_at ON governance_approval TYPE option<datetime>;
DEFINE FIELD created_at ON governance_approval TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON governance_approval TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON governance_approval TYPE option<object>;

DEFINE INDEX governance_approval_status_idx ON governance_approval FIELDS status;
DEFINE INDEX governance_approval_resource_idx ON governance_approval FIELDS resource;
DEFINE INDEX governance_approval_subject_idx ON governance_approval FIELDS subject;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_policy_evaluation(
  $governance_object: record<governance_object>,
  $subject: option<record<identity>>,
  $action: option<string>,
  $resource: option<record<entity>>,
  $decision: string,
  $reason: option<string>,
  $engine: option<string>,
  $confidence: option<number>
) {
  RETURN CREATE policy_evaluation SET
    governance_object = $governance_object,
    subject = $subject,
    action = $action,
    resource = $resource,
    decision = $decision,
    reason = $reason,
    engine = $engine,
    confidence = $confidence;
};

DEFINE FUNCTION fn::request_governance_approval(
  $subject: option<record<identity>>,
  $resource: option<record<entity>>,
  $requested_action: string,
  $policy_evaluation: option<record<policy_evaluation>>,
  $reason: option<string>
) {
  RETURN CREATE governance_approval SET
    subject = $subject,
    resource = $resource,
    requested_action = $requested_action,
    policy_evaluation = $policy_evaluation,
    status = "pending",
    reason = $reason;
};

DEFINE FUNCTION fn::approve_governance_request(
  $approval: record<governance_approval>,
  $approver: record<identity>,
  $comment: option<string>
) {
  RETURN UPDATE $approval SET
    status = "approved",
    approver = $approver,
    approver_comment = $comment,
    decided_at = time::now();
};

DEFINE FUNCTION fn::reject_governance_request(
  $approval: record<governance_approval>,
  $approver: record<identity>,
  $comment: option<string>
) {
  RETURN UPDATE $approval SET
    status = "rejected",
    approver = $approver,
    approver_comment = $comment,
    decided_at = time::now();
};
