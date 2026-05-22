-- AGenNext Platform
-- 0052: Business entity verification for individual publishers
-- Purpose: allow individuals to publish publicly when they have verified business ownership through a recognized organization or registry.

DEFINE TABLE business_entity_verification_proofs SCHEMAFULL;
DEFINE FIELD person_id ON business_entity_verification_proofs TYPE record<identity_persons>;
DEFINE FIELD issuer_id ON business_entity_verification_proofs TYPE record<verification_issuers>;
DEFINE FIELD jurisdiction ON business_entity_verification_proofs TYPE string;
DEFINE FIELD entity_kind ON business_entity_verification_proofs TYPE string;
DEFINE FIELD entity_name ON business_entity_verification_proofs TYPE string;
DEFINE FIELD registration_number ON business_entity_verification_proofs TYPE string;
DEFINE FIELD registration_authority ON business_entity_verification_proofs TYPE string;
DEFINE FIELD owner_claims ON business_entity_verification_proofs TYPE object DEFAULT {};
DEFINE FIELD verified_claims ON business_entity_verification_proofs TYPE object DEFAULT {};
DEFINE FIELD assurance_level ON business_entity_verification_proofs TYPE string DEFAULT 'business_verified';
DEFINE FIELD evidence_refs ON business_entity_verification_proofs TYPE array<string> DEFAULT [];
DEFINE FIELD status ON business_entity_verification_proofs TYPE string DEFAULT 'active';
DEFINE FIELD issued_at ON business_entity_verification_proofs TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON business_entity_verification_proofs TYPE option<datetime>;
DEFINE FIELD revoked_at ON business_entity_verification_proofs TYPE option<datetime>;
DEFINE FIELD created_at ON business_entity_verification_proofs TYPE datetime DEFAULT time::now();
DEFINE INDEX business_entity_registration_unique ON business_entity_verification_proofs FIELDS jurisdiction, registration_authority, registration_number UNIQUE;

DEFINE FUNCTION fn::record_business_entity_verification_proof(
  $person_id: record<identity_persons>,
  $issuer_id: record<verification_issuers>,
  $jurisdiction: string,
  $entity_kind: string,
  $entity_name: string,
  $registration_number: string,
  $registration_authority: string,
  $owner_claims: object,
  $verified_claims: object,
  $evidence_refs: array<string>,
  $expires_at: option<datetime>
) {
  LET $issuer = SELECT * FROM ONLY $issuer_id;
  IF $issuer = NONE THEN { THROW 'verification_issuer_not_found'; };
  IF $issuer.issuer_kind = 'self_asserted' THEN { THROW 'registry_or_organization_issuer_required'; };

  RETURN CREATE business_entity_verification_proofs CONTENT {
    person_id: $person_id,
    issuer_id: $issuer_id,
    jurisdiction: $jurisdiction,
    entity_kind: $entity_kind,
    entity_name: $entity_name,
    registration_number: $registration_number,
    registration_authority: $registration_authority,
    owner_claims: $owner_claims,
    verified_claims: $verified_claims,
    assurance_level: 'business_verified',
    evidence_refs: $evidence_refs,
    status: 'active',
    issued_at: time::now(),
    expires_at: $expires_at,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::grant_publish_capability_from_business_entity(
  $person_id: record<identity_persons>,
  $tenant_id: option<record<tenants>>,
  $profile_id: option<record<identity_profiles>>,
  $business_proof_id: record<business_entity_verification_proofs>,
  $scope: string
) {
  LET $proof = SELECT * FROM ONLY $business_proof_id;
  IF $proof = NONE THEN { THROW 'business_entity_proof_not_found'; };
  IF $proof.person_id != $person_id THEN { THROW 'business_entity_proof_person_mismatch'; };
  IF $proof.status != 'active' THEN { THROW 'business_entity_proof_not_active'; };

  RETURN CREATE publishing_capability_grants CONTENT {
    person_id: $person_id,
    tenant_id: $tenant_id,
    profile_id: $profile_id,
    capability: 'publish_web',
    scope: $scope,
    grant_reason: 'verified_business_entity_owned_by_individual',
    proof_id: NONE,
    status: 'active',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::business_entity_verification_context($person_id: record<identity_persons>) {
  RETURN {
    active_business_entities: SELECT * FROM business_entity_verification_proofs WHERE person_id = $person_id AND status = 'active',
    publish_grants: SELECT * FROM publishing_capability_grants WHERE person_id = $person_id AND capability = 'publish_web' AND status = 'active'
  };
};

-- Example issuer records can represent GST registries, Secretaries of State, Companies House,
-- MCA India, payment/KYC providers, or marketplace aggregators that verify business ownership.
