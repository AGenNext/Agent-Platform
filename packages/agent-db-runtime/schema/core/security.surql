-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Security / Authentication / Authorization / Verification Schema
-- ============================================================

-- Purpose:
-- Security formalizes the chain:
-- Identity -> Credential -> Authentication -> Verification -> Authorization -> Action.
-- It complements identity.surql by making authentication attempts,
-- authorization decisions, verification checks, sessions, and security
-- events first-class runtime records.

DEFINE TABLE security_session SCHEMAFULL;

DEFINE FIELD entity ON security_session TYPE record<entity>;
DEFINE FIELD identity ON security_session TYPE record<identity>;
DEFINE FIELD credential ON security_session TYPE option<record<credential>>;
DEFINE FIELD session_type ON security_session TYPE string
  ASSERT $value IN [
    "human_session",
    "agent_session",
    "service_session",
    "api_session",
    "workflow_session",
    "delegated_session",
    "impersonation_session",
    "break_glass_session"
  ];

DEFINE FIELD status ON security_session TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "expired", "revoked", "suspended", "closed", "archived"];

DEFINE FIELD assurance_level ON security_session TYPE string DEFAULT "low"
  ASSERT $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD issued_at ON security_session TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON security_session TYPE option<datetime>;
DEFINE FIELD revoked_at ON security_session TYPE option<datetime>;
DEFINE FIELD source_ip ON security_session TYPE option<string>;
DEFINE FIELD user_agent ON security_session TYPE option<string>;
DEFINE FIELD context ON security_session TYPE object DEFAULT {};
DEFINE FIELD metadata ON security_session TYPE option<object>;

DEFINE INDEX security_session_entity_idx ON security_session FIELDS entity UNIQUE;
DEFINE INDEX security_session_identity_idx ON security_session FIELDS identity;
DEFINE INDEX security_session_status_idx ON security_session FIELDS status;
DEFINE INDEX security_session_type_idx ON security_session FIELDS session_type;

-- ------------------------------------------------------------
-- Authentication Event
-- ------------------------------------------------------------

DEFINE TABLE authentication_event SCHEMAFULL;

DEFINE FIELD identity ON authentication_event TYPE option<record<identity>>;
DEFINE FIELD credential ON authentication_event TYPE option<record<credential>>;
DEFINE FIELD session ON authentication_event TYPE option<record<security_session>>;
DEFINE FIELD authn_type ON authentication_event TYPE string
  ASSERT $value IN [
    "passwordless",
    "api_key",
    "oauth",
    "oidc",
    "saml",
    "did_auth",
    "mfa",
    "ssh_key",
    "x509",
    "service_token",
    "delegated_token",
    "external_provider"
  ];

DEFINE FIELD result ON authentication_event TYPE string
  ASSERT $value IN ["success", "failure", "challenge", "blocked", "expired", "revoked"];

DEFINE FIELD reason ON authentication_event TYPE option<string>;
DEFINE FIELD evidence ON authentication_event TYPE option<object>;
DEFINE FIELD source_ip ON authentication_event TYPE option<string>;
DEFINE FIELD user_agent ON authentication_event TYPE option<string>;
DEFINE FIELD created_at ON authentication_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON authentication_event TYPE option<object>;

DEFINE INDEX authentication_identity_idx ON authentication_event FIELDS identity;
DEFINE INDEX authentication_result_idx ON authentication_event FIELDS result;
DEFINE INDEX authentication_type_idx ON authentication_event FIELDS authn_type;

-- ------------------------------------------------------------
-- Authorization Decision
-- ------------------------------------------------------------

DEFINE TABLE authorization_decision SCHEMAFULL;

DEFINE FIELD entity ON authorization_decision TYPE record<entity>;
DEFINE FIELD subject ON authorization_decision TYPE option<record<identity>>;
DEFINE FIELD action ON authorization_decision TYPE option<record<action>>;
DEFINE FIELD action_name ON authorization_decision TYPE option<string>;
DEFINE FIELD resource ON authorization_decision TYPE option<record<entity>>;
DEFINE FIELD session ON authorization_decision TYPE option<record<security_session>>;
DEFINE FIELD policy_evaluation ON authorization_decision TYPE option<record<policy_evaluation>>;

DEFINE FIELD engine ON authorization_decision TYPE string DEFAULT "surrealdb"
  ASSERT $value IN ["surrealdb", "opa", "openfga", "authzen", "rbac", "abac", "rebac", "manual", "external"];

DEFINE FIELD decision ON authorization_decision TYPE string
  ASSERT $value IN ["allow", "deny", "abstain", "needs_approval", "needs_more_context"];

DEFINE FIELD reason ON authorization_decision TYPE option<string>;
DEFINE FIELD obligations ON authorization_decision TYPE array<object> DEFAULT [];
DEFINE FIELD advice ON authorization_decision TYPE array<object> DEFAULT [];
DEFINE FIELD evidence ON authorization_decision TYPE option<object>;
DEFINE FIELD confidence ON authorization_decision TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD created_at ON authorization_decision TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON authorization_decision TYPE option<object>;

DEFINE INDEX authorization_entity_idx ON authorization_decision FIELDS entity UNIQUE;
DEFINE INDEX authorization_subject_idx ON authorization_decision FIELDS subject;
DEFINE INDEX authorization_resource_idx ON authorization_decision FIELDS resource;
DEFINE INDEX authorization_decision_idx ON authorization_decision FIELDS decision;
DEFINE INDEX authorization_engine_idx ON authorization_decision FIELDS engine;

-- ------------------------------------------------------------
-- Verification Check
-- ------------------------------------------------------------

DEFINE TABLE verification_check SCHEMAFULL;

DEFINE FIELD entity ON verification_check TYPE record<entity>;
DEFINE FIELD target ON verification_check TYPE record<entity>;
DEFINE FIELD verifier ON verification_check TYPE option<record<identity>>;
DEFINE FIELD verification_type ON verification_check TYPE string
  ASSERT $value IN [
    "identity_verification",
    "credential_verification",
    "authorization_verification",
    "policy_verification",
    "protocol_verification",
    "schema_verification",
    "artifact_verification",
    "knowledge_verification",
    "trust_verification",
    "payment_verification",
    "assurance_verification",
    "signature_verification",
    "proof_verification",
    "claim_verification"
  ];

DEFINE FIELD status ON verification_check TYPE string
  ASSERT $value IN ["passed", "failed", "pending", "expired", "revoked", "inconclusive"];

DEFINE FIELD method ON verification_check TYPE option<string>;
DEFINE FIELD claims_checked ON verification_check TYPE array<string> DEFAULT [];
DEFINE FIELD result ON verification_check TYPE object DEFAULT {};
DEFINE FIELD evidence ON verification_check TYPE option<object>;
DEFINE FIELD confidence ON verification_check TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD created_at ON verification_check TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON verification_check TYPE option<object>;

DEFINE INDEX verification_entity_idx ON verification_check FIELDS entity UNIQUE;
DEFINE INDEX verification_target_idx ON verification_check FIELDS target;
DEFINE INDEX verification_type_idx ON verification_check FIELDS verification_type;
DEFINE INDEX verification_status_idx ON verification_check FIELDS status;

-- ------------------------------------------------------------
-- Security Event
-- ------------------------------------------------------------

DEFINE TABLE security_event SCHEMAFULL;

DEFINE FIELD event_type ON security_event TYPE string
  ASSERT $value IN [
    "authentication_success",
    "authentication_failure",
    "authorization_allowed",
    "authorization_denied",
    "verification_passed",
    "verification_failed",
    "credential_created",
    "credential_rotated",
    "credential_revoked",
    "session_created",
    "session_revoked",
    "policy_violation",
    "suspicious_activity",
    "break_glass_used"
  ];

DEFINE FIELD identity ON security_event TYPE option<record<identity>>;
DEFINE FIELD resource ON security_event TYPE option<record<entity>>;
DEFINE FIELD session ON security_event TYPE option<record<security_session>>;
DEFINE FIELD severity ON security_event TYPE string DEFAULT "info" ASSERT $value IN ["info", "low", "medium", "high", "critical"];
DEFINE FIELD reason ON security_event TYPE option<string>;
DEFINE FIELD evidence ON security_event TYPE option<object>;
DEFINE FIELD created_at ON security_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON security_event TYPE option<object>;

DEFINE INDEX security_event_type_idx ON security_event FIELDS event_type;
DEFINE INDEX security_event_identity_idx ON security_event FIELDS identity;
DEFINE INDEX security_event_resource_idx ON security_event FIELDS resource;
DEFINE INDEX security_event_severity_idx ON security_event FIELDS severity;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_authentication_event(
  $identity: option<record<identity>>,
  $credential: option<record<credential>>,
  $authn_type: string,
  $result: string,
  $reason: option<string>,
  $evidence: option<object>
) {
  LET $event = CREATE authentication_event SET
    identity = $identity,
    credential = $credential,
    authn_type = $authn_type,
    result = $result,
    reason = $reason,
    evidence = $evidence;

  CREATE security_event SET
    event_type = IF $result = "success" THEN "authentication_success" ELSE "authentication_failure" END,
    identity = $identity,
    severity = IF $result = "success" THEN "info" ELSE "medium" END,
    reason = $reason,
    evidence = $evidence;

  RETURN $event;
};

DEFINE FUNCTION fn::record_authorization_decision(
  $entity: record<entity>,
  $subject: option<record<identity>>,
  $action_name: option<string>,
  $resource: option<record<entity>>,
  $engine: string,
  $decision: string,
  $reason: option<string>,
  $confidence: option<number>
) {
  LET $authz = CREATE authorization_decision SET
    entity = $entity,
    subject = $subject,
    action_name = $action_name,
    resource = $resource,
    engine = $engine,
    decision = $decision,
    reason = $reason,
    confidence = $confidence;

  CREATE security_event SET
    event_type = IF $decision = "allow" THEN "authorization_allowed" ELSE "authorization_denied" END,
    identity = $subject,
    resource = $resource,
    severity = IF $decision = "allow" THEN "info" ELSE "high" END,
    reason = $reason;

  RETURN $authz;
};

DEFINE FUNCTION fn::record_verification_check(
  $entity: record<entity>,
  $target: record<entity>,
  $verifier: option<record<identity>>,
  $verification_type: string,
  $status: string,
  $method: option<string>,
  $result: object,
  $evidence: option<object>,
  $confidence: option<number>
) {
  LET $check = CREATE verification_check SET
    entity = $entity,
    target = $target,
    verifier = $verifier,
    verification_type = $verification_type,
    status = $status,
    method = $method,
    result = $result,
    evidence = $evidence,
    confidence = $confidence;

  CREATE security_event SET
    event_type = IF $status = "passed" THEN "verification_passed" ELSE "verification_failed" END,
    identity = $verifier,
    resource = $target,
    severity = IF $status = "passed" THEN "info" ELSE "medium" END,
    evidence = $evidence;

  RETURN $check;
};

DEFINE FUNCTION fn::security_session_is_active($session: record<security_session>) {
  LET $s = SELECT * FROM ONLY $session;
  RETURN $s.status = "active"
    AND ($s.expires_at = NONE OR $s.expires_at > time::now())
    AND $s.revoked_at = NONE;
};
