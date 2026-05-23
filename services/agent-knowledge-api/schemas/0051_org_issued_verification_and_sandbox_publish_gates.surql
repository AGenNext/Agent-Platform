-- AGenNext Platform
-- 0051: Organization-issued identity verification and sandbox publish gates
-- Purpose: individual trials get sandbox-only access until organization-backed verification allows web/public publishing.

DEFINE TABLE verification_issuers SCHEMAFULL;
DEFINE FIELD issuer_key ON verification_issuers TYPE string;
DEFINE FIELD issuer_name ON verification_issuers TYPE string;
DEFINE FIELD issuer_kind ON verification_issuers TYPE string;
DEFINE FIELD issuer_tenant_id ON verification_issuers TYPE option<record<tenants>>;
DEFINE FIELD issuer_domain ON verification_issuers TYPE option<string>;
DEFINE FIELD authority_level ON verification_issuers TYPE string DEFAULT 'standard';
DEFINE FIELD verification_methods ON verification_issuers TYPE array<string> DEFAULT [];
DEFINE FIELD status ON verification_issuers TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON verification_issuers TYPE datetime DEFAULT time::now();
DEFINE INDEX verification_issuer_key_unique ON verification_issuers FIELDS issuer_key UNIQUE;

DEFINE TABLE organization_issued_identity_proofs SCHEMAFULL;
DEFINE FIELD person_id ON organization_issued_identity_proofs TYPE record<identity_persons>;
DEFINE FIELD issuer_id ON organization_issued_identity_proofs TYPE record<verification_issuers>;
DEFINE FIELD proof_kind ON organization_issued_identity_proofs TYPE string;
DEFINE FIELD verified_claims ON organization_issued_identity_proofs TYPE object DEFAULT {};
DEFINE FIELD assurance_level ON organization_issued_identity_proofs TYPE string DEFAULT 'standard';
DEFINE FIELD evidence_refs ON organization_issued_identity_proofs TYPE array<string> DEFAULT [];
DEFINE FIELD issued_at ON organization_issued_identity_proofs TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON organization_issued_identity_proofs TYPE option<datetime>;
DEFINE FIELD revocation_status ON organization_issued_identity_proofs TYPE string DEFAULT 'active';
DEFINE FIELD revoked_at ON organization_issued_identity_proofs TYPE option<datetime>;
DEFINE FIELD created_at ON organization_issued_identity_proofs TYPE datetime DEFAULT time::now();

DEFINE TABLE publishing_capability_grants SCHEMAFULL;
DEFINE FIELD person_id ON publishing_capability_grants TYPE record<identity_persons>;
DEFINE FIELD tenant_id ON publishing_capability_grants TYPE option<record<tenants>>;
DEFINE FIELD profile_id ON publishing_capability_grants TYPE option<record<identity_profiles>>;
DEFINE FIELD capability ON publishing_capability_grants TYPE string;
DEFINE FIELD scope ON publishing_capability_grants TYPE string DEFAULT 'sandbox';
DEFINE FIELD grant_reason ON publishing_capability_grants TYPE string;
DEFINE FIELD proof_id ON publishing_capability_grants TYPE option<record<organization_issued_identity_proofs>>;
DEFINE FIELD status ON publishing_capability_grants TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON publishing_capability_grants TYPE datetime DEFAULT time::now();

DEFINE TABLE publish_gate_decisions SCHEMAFULL;
DEFINE FIELD person_id ON publish_gate_decisions TYPE record<identity_persons>;
DEFINE FIELD tenant_id ON publish_gate_decisions TYPE option<record<tenants>>;
DEFINE FIELD resource_ref ON publish_gate_decisions TYPE string;
DEFINE FIELD publish_target ON publish_gate_decisions TYPE string;
DEFINE FIELD decision ON publish_gate_decisions TYPE string;
DEFINE FIELD reason ON publish_gate_decisions TYPE string;
DEFINE FIELD proof_ids ON publish_gate_decisions TYPE array<record<organization_issued_identity_proofs>> DEFAULT [];
DEFINE FIELD created_at ON publish_gate_decisions TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::register_verification_issuer(
  $issuer_key: string,
  $issuer_name: string,
  $issuer_kind: string,
  $issuer_tenant_id: option<record<tenants>>,
  $issuer_domain: option<string>,
  $authority_level: string,
  $verification_methods: array<string>
) {
  RETURN UPSERT type::thing('verification_issuers', $issuer_key) CONTENT {
    issuer_key: $issuer_key,
    issuer_name: $issuer_name,
    issuer_kind: $issuer_kind,
    issuer_tenant_id: $issuer_tenant_id,
    issuer_domain: $issuer_domain,
    authority_level: $authority_level,
    verification_methods: $verification_methods,
    status: 'active',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::record_organization_issued_identity_proof(
  $person_id: record<identity_persons>,
  $issuer_id: record<verification_issuers>,
  $proof_kind: string,
  $verified_claims: object,
  $assurance_level: string,
  $evidence_refs: array<string>,
  $expires_at: option<datetime>
) {
  LET $issuer = SELECT * FROM ONLY $issuer_id;
  IF $issuer = NONE THEN { THROW 'verification_issuer_not_found'; };
  IF $issuer.issuer_kind = 'self_asserted' THEN { THROW 'organization_issued_proof_required'; };

  RETURN CREATE organization_issued_identity_proofs CONTENT {
    person_id: $person_id,
    issuer_id: $issuer_id,
    proof_kind: $proof_kind,
    verified_claims: $verified_claims,
    assurance_level: $assurance_level,
    evidence_refs: $evidence_refs,
    issued_at: time::now(),
    expires_at: $expires_at,
    revocation_status: 'active',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::grant_publish_capability_from_proof(
  $person_id: record<identity_persons>,
  $tenant_id: option<record<tenants>>,
  $profile_id: option<record<identity_profiles>>,
  $capability: string,
  $scope: string,
  $proof_id: record<organization_issued_identity_proofs>
) {
  LET $proof = SELECT * FROM ONLY $proof_id;
  IF $proof = NONE THEN { THROW 'identity_proof_not_found'; };
  IF $proof.person_id != $person_id THEN { THROW 'identity_proof_person_mismatch'; };
  IF $proof.revocation_status != 'active' THEN { THROW 'identity_proof_not_active'; };

  RETURN CREATE publishing_capability_grants CONTENT {
    person_id: $person_id,
    tenant_id: $tenant_id,
    profile_id: $profile_id,
    capability: $capability,
    scope: $scope,
    grant_reason: 'organization_issued_identity_verified',
    proof_id: $proof_id,
    status: 'active',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::evaluate_publish_gate(
  $person_id: record<identity_persons>,
  $tenant_id: option<record<tenants>>,
  $resource_ref: string,
  $publish_target: string
) {
  IF $publish_target = 'sandbox' THEN {
    RETURN CREATE publish_gate_decisions CONTENT {
      person_id: $person_id,
      tenant_id: $tenant_id,
      resource_ref: $resource_ref,
      publish_target: $publish_target,
      decision: 'allow',
      reason: 'sandbox_access_allowed_before_identity_verification',
      proof_ids: [],
      created_at: time::now()
    };
  };

  LET $grants = SELECT * FROM publishing_capability_grants
    WHERE person_id = $person_id
      AND status = 'active'
      AND capability = 'publish_web'
      AND (scope = $publish_target OR scope = 'public_web' OR scope = 'all')
      AND (tenant_id = $tenant_id OR tenant_id = NONE);

  IF count($grants) = 0 THEN {
    RETURN CREATE publish_gate_decisions CONTENT {
      person_id: $person_id,
      tenant_id: $tenant_id,
      resource_ref: $resource_ref,
      publish_target: $publish_target,
      decision: 'deny',
      reason: 'organization_issued_identity_verification_required_for_web_publish',
      proof_ids: [],
      created_at: time::now()
    };
  };

  RETURN CREATE publish_gate_decisions CONTENT {
    person_id: $person_id,
    tenant_id: $tenant_id,
    resource_ref: $resource_ref,
    publish_target: $publish_target,
    decision: 'allow',
    reason: 'publish_capability_granted_by_organization_issued_identity_proof',
    proof_ids: $grants.proof_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::require_publish_allowed(
  $person_id: record<identity_persons>,
  $tenant_id: option<record<tenants>>,
  $resource_ref: string,
  $publish_target: string
) {
  LET $decision = fn::evaluate_publish_gate($person_id, $tenant_id, $resource_ref, $publish_target);
  IF $decision.decision != 'allow' THEN {
    THROW $decision.reason;
  };
  RETURN $decision;
};
