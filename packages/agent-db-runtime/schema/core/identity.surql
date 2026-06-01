-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Identity Schema
-- ============================================================

-- Purpose:
-- Identity is the root of authentication, authorization, verification,
-- credentials, claims, lifecycle, and trust for humans, agents, services,
-- organizations, tenants, and environments.

DEFINE TABLE identity SCHEMAFULL;

DEFINE FIELD entity ON identity TYPE record<entity>;
DEFINE FIELD identity_type ON identity TYPE string
  ASSERT $value IN [
    "human",
    "agent",
    "service_account",
    "api_key",
    "organization",
    "tenant",
    "team",
    "role",
    "group",
    "environment",
    "system",
    "external_subject"
  ];

DEFINE FIELD subject ON identity TYPE string;
DEFINE FIELD display_name ON identity TYPE option<string>;
DEFINE FIELD email ON identity TYPE option<string>;
DEFINE FIELD issuer ON identity TYPE option<string>;
DEFINE FIELD provider ON identity TYPE option<string>;
DEFINE FIELD provider_subject ON identity TYPE option<string>;

DEFINE FIELD lifecycle_state ON identity TYPE string DEFAULT "onboarding"
  ASSERT $value IN [
    "onboarding",
    "active",
    "probation",
    "leave",
    "suspended",
    "terminated",
    "alumni",
    "archived"
  ];

DEFINE FIELD assurance_level ON identity TYPE string DEFAULT "low"
  ASSERT $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD verified ON identity TYPE bool DEFAULT false;
DEFINE FIELD verified_at ON identity TYPE option<datetime>;
DEFINE FIELD verification_method ON identity TYPE option<string>;
DEFINE FIELD verification_evidence ON identity TYPE option<object>;

DEFINE FIELD did ON identity TYPE option<string>;
DEFINE FIELD public_keys ON identity TYPE array<object> DEFAULT [];
DEFINE FIELD claims ON identity TYPE object DEFAULT {};
DEFINE FIELD attributes ON identity TYPE object DEFAULT {};

DEFINE FIELD created_at ON identity TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON identity TYPE datetime VALUE time::now();
DEFINE FIELD valid_from ON identity TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON identity TYPE option<datetime>;
DEFINE FIELD metadata ON identity TYPE option<object>;

DEFINE INDEX identity_subject_idx ON identity FIELDS subject UNIQUE;
DEFINE INDEX identity_type_idx ON identity FIELDS identity_type;
DEFINE INDEX identity_lifecycle_idx ON identity FIELDS lifecycle_state;
DEFINE INDEX identity_entity_idx ON identity FIELDS entity UNIQUE;

-- ------------------------------------------------------------
-- Credential
-- ------------------------------------------------------------

DEFINE TABLE credential SCHEMAFULL;

DEFINE FIELD identity ON credential TYPE record<identity>;
DEFINE FIELD credential_type ON credential TYPE string
  ASSERT $value IN [
    "passwordless",
    "api_key",
    "oauth_token",
    "oidc_subject",
    "saml_subject",
    "did_document",
    "verifiable_credential",
    "ssh_key",
    "x509_certificate",
    "secret_reference",
    "mcp_tool_credential",
    "external_provider_token"
  ];

DEFINE FIELD status ON credential TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "revoked", "expired", "rotating", "archived"];

DEFINE FIELD issuer ON credential TYPE option<string>;
DEFINE FIELD subject ON credential TYPE string;
DEFINE FIELD audience ON credential TYPE array<string> DEFAULT [];
DEFINE FIELD scopes ON credential TYPE array<string> DEFAULT [];
DEFINE FIELD claims ON credential TYPE object DEFAULT {};

-- Never store raw secrets here. Store only references to a vault/secret manager.
DEFINE FIELD secret_ref ON credential TYPE option<string>;
DEFINE FIELD fingerprint ON credential TYPE option<string>;
DEFINE FIELD proof ON credential TYPE option<object>;

DEFINE FIELD issued_at ON credential TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON credential TYPE option<datetime>;
DEFINE FIELD revoked_at ON credential TYPE option<datetime>;
DEFINE FIELD created_at ON credential TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON credential TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON credential TYPE option<object>;

DEFINE INDEX credential_identity_idx ON credential FIELDS identity;
DEFINE INDEX credential_subject_idx ON credential FIELDS subject;
DEFINE INDEX credential_type_idx ON credential FIELDS credential_type;
DEFINE INDEX credential_status_idx ON credential FIELDS status;

-- ------------------------------------------------------------
-- Authorization Binding
-- ------------------------------------------------------------

DEFINE TABLE auth_binding SCHEMAFULL;

DEFINE FIELD subject ON auth_binding TYPE record<identity>;
DEFINE FIELD relation ON auth_binding TYPE string
  ASSERT $value IN [
    "owner",
    "admin",
    "member",
    "viewer",
    "editor",
    "operator",
    "approver",
    "reviewer",
    "executor",
    "issuer",
    "verifier",
    "delegate",
    "service_account",
    "agent_worker"
  ];

DEFINE FIELD object ON auth_binding TYPE record<entity>;
DEFINE FIELD condition ON auth_binding TYPE option<object>;
DEFINE FIELD source ON auth_binding TYPE option<string>;
DEFINE FIELD valid_from ON auth_binding TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON auth_binding TYPE option<datetime>;
DEFINE FIELD created_at ON auth_binding TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON auth_binding TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON auth_binding TYPE option<object>;

DEFINE INDEX auth_binding_subject_idx ON auth_binding FIELDS subject;
DEFINE INDEX auth_binding_object_idx ON auth_binding FIELDS object;
DEFINE INDEX auth_binding_relation_idx ON auth_binding FIELDS relation;

-- ------------------------------------------------------------
-- Identity Verification Event
-- ------------------------------------------------------------

DEFINE TABLE identity_verification SCHEMAFULL;

DEFINE FIELD identity ON identity_verification TYPE record<identity>;
DEFINE FIELD status ON identity_verification TYPE string
  ASSERT $value IN ["passed", "failed", "pending", "expired", "revoked"];

DEFINE FIELD method ON identity_verification TYPE string;
DEFINE FIELD verifier ON identity_verification TYPE option<string>;
DEFINE FIELD evidence ON identity_verification TYPE option<object>;
DEFINE FIELD claims_checked ON identity_verification TYPE array<string> DEFAULT [];
DEFINE FIELD result ON identity_verification TYPE object DEFAULT {};
DEFINE FIELD created_at ON identity_verification TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON identity_verification TYPE option<object>;

DEFINE INDEX identity_verification_identity_idx ON identity_verification FIELDS identity;
DEFINE INDEX identity_verification_status_idx ON identity_verification FIELDS status;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::identity_is_active($identity: record<identity>) {
  LET $id = SELECT * FROM ONLY $identity;
  RETURN $id.lifecycle_state = "active" AND $id.verified = true;
};

DEFINE FUNCTION fn::credential_is_usable($credential: record<credential>) {
  LET $cred = SELECT * FROM ONLY $credential;
  RETURN $cred.status = "active"
    AND ($cred.expires_at = NONE OR $cred.expires_at > time::now())
    AND $cred.revoked_at = NONE;
};

DEFINE FUNCTION fn::verify_identity(
  $identity: record<identity>,
  $method: string,
  $verifier: option<string>,
  $evidence: option<object>
) {
  UPDATE $identity SET
    verified = true,
    verified_at = time::now(),
    verification_method = $method,
    verification_evidence = $evidence;

  RETURN CREATE identity_verification SET
    identity = $identity,
    status = "passed",
    method = $method,
    verifier = $verifier,
    evidence = $evidence,
    result = { verified: true };
};

DEFINE FUNCTION fn::suspend_identity(
  $identity: record<identity>,
  $reason: string
) {
  UPDATE $identity SET lifecycle_state = "suspended";

  RETURN CREATE identity_verification SET
    identity = $identity,
    status = "revoked",
    method = "lifecycle_change",
    evidence = { reason: $reason },
    result = { lifecycle_state: "suspended" };
};
