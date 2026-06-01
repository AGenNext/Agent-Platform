-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Issue / Claim / Resolution Schema
-- ============================================================

-- Purpose:
-- Issue models operational problems, findings, defects, incidents,
-- disputes, violations, risks, exceptions, claims, and their resolution.
-- This is separate from commercial assurance claims and supports
-- governance, compliance, security, operations, evaluation, and trust.

DEFINE TABLE issue SCHEMAFULL;

DEFINE FIELD entity ON issue TYPE record<entity>;
DEFINE FIELD reporter ON issue TYPE option<record<identity>>;
DEFINE FIELD owner ON issue TYPE option<record<identity>>;
DEFINE FIELD assignee ON issue TYPE option<record<identity>>;
DEFINE FIELD subject ON issue TYPE option<record<entity>>;
DEFINE FIELD related_task ON issue TYPE option<record<task>>;
DEFINE FIELD related_decision ON issue TYPE option<record<decision>>;
DEFINE FIELD related_evaluation ON issue TYPE option<record<evaluation>>;
DEFINE FIELD related_artifact ON issue TYPE option<record<artifact>>;
DEFINE FIELD related_workflow_run ON issue TYPE option<record<workflow_run>>;

DEFINE FIELD issue_type ON issue TYPE string
  ASSERT $value IN [
    "incident",
    "risk",
    "finding",
    "violation",
    "defect",
    "bug",
    "exception",
    "observation",
    "recommendation",
    "dispute",
    "non_conformance",
    "policy_breach",
    "security_issue",
    "privacy_issue",
    "quality_issue",
    "reliability_issue",
    "trust_issue",
    "compliance_issue",
    "operational_issue"
  ];

DEFINE FIELD status ON issue TYPE string DEFAULT "open"
  ASSERT $value IN [
    "draft",
    "open",
    "triaged",
    "assigned",
    "in_progress",
    "blocked",
    "needs_review",
    "resolved",
    "closed",
    "cancelled",
    "duplicate",
    "wont_fix",
    "accepted_risk"
  ];

DEFINE FIELD title ON issue TYPE string;
DEFINE FIELD description ON issue TYPE option<string>;
DEFINE FIELD severity ON issue TYPE string DEFAULT "medium" ASSERT $value IN ["info", "low", "medium", "high", "critical"];
DEFINE FIELD priority ON issue TYPE string DEFAULT "medium" ASSERT $value IN ["low", "medium", "high", "critical"];
DEFINE FIELD impact ON issue TYPE option<object>;
DEFINE FIELD root_cause ON issue TYPE option<object>;
DEFINE FIELD evidence ON issue TYPE option<object>;
DEFINE FIELD policy_evaluations ON issue TYPE array<record<policy_evaluation>> DEFAULT [];
DEFINE FIELD validation_results ON issue TYPE array<record<validation_result>> DEFAULT [];
DEFINE FIELD labels ON issue TYPE array<string> DEFAULT [];
DEFINE FIELD due_at ON issue TYPE option<datetime>;
DEFINE FIELD resolved_at ON issue TYPE option<datetime>;
DEFINE FIELD closed_at ON issue TYPE option<datetime>;
DEFINE FIELD created_at ON issue TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON issue TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON issue TYPE option<object>;

DEFINE INDEX issue_entity_idx ON issue FIELDS entity UNIQUE;
DEFINE INDEX issue_type_idx ON issue FIELDS issue_type;
DEFINE INDEX issue_status_idx ON issue FIELDS status;
DEFINE INDEX issue_severity_idx ON issue FIELDS severity;
DEFINE INDEX issue_subject_idx ON issue FIELDS subject;
DEFINE INDEX issue_title_idx ON issue FIELDS title SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Claim
-- ------------------------------------------------------------

DEFINE TABLE operational_claim SCHEMAFULL;

DEFINE FIELD entity ON operational_claim TYPE record<entity>;
DEFINE FIELD issue ON operational_claim TYPE option<record<issue>>;
DEFINE FIELD claimant ON operational_claim TYPE option<record<identity>>;
DEFINE FIELD subject ON operational_claim TYPE option<record<entity>>;
DEFINE FIELD claim_type ON operational_claim TYPE string
  ASSERT $value IN [
    "assertion",
    "requirement",
    "obligation",
    "attestation",
    "statement",
    "finding_claim",
    "compliance_claim",
    "security_claim",
    "quality_claim",
    "trust_claim",
    "performance_claim",
    "capability_claim"
  ];

DEFINE FIELD status ON operational_claim TYPE string DEFAULT "claimed"
  ASSERT $value IN ["draft", "claimed", "verified", "rejected", "disputed", "superseded", "archived"];

DEFINE FIELD statement ON operational_claim TYPE string;
DEFINE FIELD evidence ON operational_claim TYPE option<object>;
DEFINE FIELD verification_result ON operational_claim TYPE option<object>;
DEFINE FIELD confidence ON operational_claim TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD created_at ON operational_claim TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON operational_claim TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON operational_claim TYPE option<object>;

DEFINE INDEX operational_claim_entity_idx ON operational_claim FIELDS entity UNIQUE;
DEFINE INDEX operational_claim_issue_idx ON operational_claim FIELDS issue;
DEFINE INDEX operational_claim_type_idx ON operational_claim FIELDS claim_type;
DEFINE INDEX operational_claim_status_idx ON operational_claim FIELDS status;
DEFINE INDEX operational_claim_statement_idx ON operational_claim FIELDS statement SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Resolution
-- ------------------------------------------------------------

DEFINE TABLE resolution SCHEMAFULL;

DEFINE FIELD entity ON resolution TYPE record<entity>;
DEFINE FIELD issue ON resolution TYPE record<issue>;
DEFINE FIELD resolver ON resolution TYPE option<record<identity>>;
DEFINE FIELD resolution_type ON resolution TYPE string
  ASSERT $value IN [
    "corrective_action",
    "preventive_action",
    "exception_approval",
    "risk_acceptance",
    "settlement",
    "closure",
    "reconciliation",
    "rollback",
    "compensation",
    "documentation_update",
    "policy_update",
    "control_update",
    "training",
    "monitoring",
    "no_action"
  ];

DEFINE FIELD status ON resolution TYPE string DEFAULT "proposed"
  ASSERT $value IN ["proposed", "approved", "in_progress", "implemented", "verified", "rejected", "closed"];

DEFINE FIELD summary ON resolution TYPE string;
DEFINE FIELD actions ON resolution TYPE array<object> DEFAULT [];
DEFINE FIELD linked_tasks ON resolution TYPE array<record<task>> DEFAULT [];
DEFINE FIELD evidence ON resolution TYPE option<object>;
DEFINE FIELD verification_result ON resolution TYPE option<object>;
DEFINE FIELD due_at ON resolution TYPE option<datetime>;
DEFINE FIELD implemented_at ON resolution TYPE option<datetime>;
DEFINE FIELD verified_at ON resolution TYPE option<datetime>;
DEFINE FIELD created_at ON resolution TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON resolution TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON resolution TYPE option<object>;

DEFINE INDEX resolution_entity_idx ON resolution FIELDS entity UNIQUE;
DEFINE INDEX resolution_issue_idx ON resolution FIELDS issue;
DEFINE INDEX resolution_type_idx ON resolution FIELDS resolution_type;
DEFINE INDEX resolution_status_idx ON resolution FIELDS status;

-- ------------------------------------------------------------
-- Issue Event
-- ------------------------------------------------------------

DEFINE TABLE issue_event SCHEMAFULL;

DEFINE FIELD issue ON issue_event TYPE record<issue>;
DEFINE FIELD event_type ON issue_event TYPE string
  ASSERT $value IN [
    "created",
    "triaged",
    "assigned",
    "started",
    "blocked",
    "evidence_added",
    "claim_added",
    "resolution_proposed",
    "resolved",
    "closed",
    "reopened",
    "cancelled",
    "risk_accepted"
  ];

DEFINE FIELD actor ON issue_event TYPE option<record<identity>>;
DEFINE FIELD from_status ON issue_event TYPE option<string>;
DEFINE FIELD to_status ON issue_event TYPE option<string>;
DEFINE FIELD reason ON issue_event TYPE option<string>;
DEFINE FIELD payload ON issue_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON issue_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON issue_event TYPE option<object>;

DEFINE INDEX issue_event_issue_idx ON issue_event FIELDS issue;
DEFINE INDEX issue_event_type_idx ON issue_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::open_issue(
  $entity: record<entity>,
  $issue_type: string,
  $title: string,
  $description: option<string>,
  $reporter: option<record<identity>>,
  $subject: option<record<entity>>,
  $severity: string,
  $priority: string,
  $evidence: option<object>
) {
  LET $created = CREATE issue SET
    entity = $entity,
    issue_type = $issue_type,
    title = $title,
    description = $description,
    reporter = $reporter,
    subject = $subject,
    severity = $severity,
    priority = $priority,
    evidence = $evidence,
    status = "open";

  CREATE issue_event SET
    issue = $created.id,
    event_type = "created",
    actor = $reporter,
    to_status = "open",
    payload = { issue_type: $issue_type, severity: $severity, priority: $priority };

  RETURN $created;
};

DEFINE FUNCTION fn::record_operational_claim(
  $entity: record<entity>,
  $issue: option<record<issue>>,
  $claimant: option<record<identity>>,
  $subject: option<record<entity>>,
  $claim_type: string,
  $statement: string,
  $evidence: option<object>,
  $confidence: option<number>
) {
  RETURN CREATE operational_claim SET
    entity = $entity,
    issue = $issue,
    claimant = $claimant,
    subject = $subject,
    claim_type = $claim_type,
    statement = $statement,
    evidence = $evidence,
    confidence = $confidence,
    status = "claimed";
};

DEFINE FUNCTION fn::resolve_issue(
  $resolution_entity: record<entity>,
  $issue: record<issue>,
  $resolver: option<record<identity>>,
  $resolution_type: string,
  $summary: string,
  $actions: array<object>,
  $evidence: option<object>
) {
  LET $res = CREATE resolution SET
    entity = $resolution_entity,
    issue = $issue,
    resolver = $resolver,
    resolution_type = $resolution_type,
    summary = $summary,
    actions = $actions,
    evidence = $evidence,
    status = "implemented",
    implemented_at = time::now();

  LET $before = SELECT * FROM ONLY $issue;

  UPDATE $issue SET
    status = "resolved",
    resolved_at = time::now();

  CREATE issue_event SET
    issue = $issue,
    event_type = "resolved",
    actor = $resolver,
    from_status = $before.status,
    to_status = "resolved",
    payload = { resolution: $res.id, resolution_type: $resolution_type };

  RETURN $res;
};

DEFINE FUNCTION fn::close_issue(
  $issue: record<issue>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $before = SELECT * FROM ONLY $issue;

  LET $updated = UPDATE $issue SET
    status = "closed",
    closed_at = time::now();

  CREATE issue_event SET
    issue = $issue,
    event_type = "closed",
    actor = $actor,
    from_status = $before.status,
    to_status = "closed",
    reason = $reason;

  RETURN $updated;
};
