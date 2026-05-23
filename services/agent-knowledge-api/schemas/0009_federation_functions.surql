DEFINE TABLE agent_registry_listings SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_registry_listings TYPE option<record<tenants>>;
DEFINE FIELD registry_id ON agent_registry_listings TYPE record<agent_registries>;
DEFINE FIELD external_agent_profile_id ON agent_registry_listings TYPE record<external_agent_profiles>;
DEFINE FIELD listed_at ON agent_registry_listings TYPE datetime DEFAULT time::now();
DEFINE FIELD listing_status ON agent_registry_listings TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON agent_registry_listings TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_registry_listings TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentRegistryListing'];

DEFINE TABLE agent_registry_attestations SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_registry_attestations TYPE option<record<tenants>>;
DEFINE FIELD registry_id ON agent_registry_attestations TYPE record<agent_registries>;
DEFINE FIELD subject_id ON agent_registry_attestations TYPE string;
DEFINE FIELD issuer_id ON agent_registry_attestations TYPE string;
DEFINE FIELD attestation_kind ON agent_registry_attestations TYPE string;
DEFINE FIELD claim ON agent_registry_attestations TYPE object;
DEFINE FIELD proof ON agent_registry_attestations TYPE option<object>;
DEFINE FIELD verified ON agent_registry_attestations TYPE bool DEFAULT false;
DEFINE FIELD revoked ON agent_registry_attestations TYPE bool DEFAULT false;
DEFINE FIELD observed_at ON agent_registry_attestations TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON agent_registry_attestations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_registry_attestations TYPE array<string> DEFAULT ['schema:Claim', 'agx:AgentRegistryAttestation'];

DEFINE TABLE agent_identity_links SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_identity_links TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON agent_identity_links TYPE string;
DEFINE FIELD linked_id ON agent_identity_links TYPE string;
DEFINE FIELD link_kind ON agent_identity_links TYPE string;
DEFINE FIELD evidence_id ON agent_identity_links TYPE option<record<trust_evidence>>;
DEFINE FIELD verified ON agent_identity_links TYPE bool DEFAULT false;
DEFINE FIELD observed_at ON agent_identity_links TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON agent_identity_links TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_identity_links TYPE array<string> DEFAULT ['schema:Action', 'agx:AgentIdentityLink'];
DEFINE INDEX agent_identity_links_unique ON agent_identity_links FIELDS tenant_id, subject_id, linked_id, link_kind UNIQUE;

DEFINE TABLE agent_capability_claims SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_capability_claims TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON agent_capability_claims TYPE string;
DEFINE FIELD capability ON agent_capability_claims TYPE string;
DEFINE FIELD issuer_id ON agent_capability_claims TYPE string;
DEFINE FIELD confidence ON agent_capability_claims TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD evidence_ids ON agent_capability_claims TYPE array<record<trust_evidence>> DEFAULT [];
DEFINE FIELD verified ON agent_capability_claims TYPE bool DEFAULT false;
DEFINE FIELD revoked ON agent_capability_claims TYPE bool DEFAULT false;
DEFINE FIELD observed_at ON agent_capability_claims TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON agent_capability_claims TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_capability_claims TYPE array<string> DEFAULT ['schema:Claim', 'agx:AgentCapabilityClaim'];

DEFINE FUNCTION fn::register_agent_registry($name, $registry_url, $trust_score) {
  LET $existing = SELECT * FROM agent_registries WHERE registry_url = $registry_url LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };

  RETURN CREATE agent_registries CONTENT {
    name: $name,
    registry_url: $registry_url,
    trust_score: $trust_score,
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:DataCatalog', 'agx:AgentRegistry'],
    source_grounding_refs: ['schemaorg:vocabulary'],
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::import_external_agent_profile($tenant_id, $registry_id, $external_id, $semantic_id, $did, $same_as, $profile_jsonld) {
  LET $registry = SELECT * FROM $registry_id;
  IF count($registry) = 0 THEN { THROW 'registry_not_found'; };

  LET $profile = CREATE external_agent_profiles CONTENT {
    registry_id: $registry_id,
    external_id: $external_id,
    semantic_id: $semantic_id,
    did: $did,
    same_as: $same_as,
    profile_jsonld: $profile_jsonld,
    imported_as_claim: true,
    verified: false,
    revoked: false,
    observed_at: time::now()
  };

  CREATE agent_registry_listings CONTENT {
    tenant_id: $tenant_id,
    registry_id: $registry_id,
    external_agent_profile_id: $profile.id,
    listing_status: 'active',
    listed_at: time::now()
  };

  CREATE trust_evidence CONTENT {
    tenant_id: $tenant_id,
    subject_id: $semantic_id,
    evidence_kind: 'registry_reliability',
    source_id: string::concat($registry_id),
    weight: IF $registry[0].trust_score = NONE THEN 0.5 ELSE $registry[0].trust_score END,
    confidence: 0.6,
    payload: { external_id: $external_id, did: $did, same_as: $same_as },
    observed_at: time::now(),
    source_grounding_refs: ['schemaorg:vocabulary'],
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence']
  };

  RETURN $profile;
};

DEFINE FUNCTION fn::record_identity_link($tenant_id, $subject_id, $linked_id, $link_kind, $verified, $confidence) {
  LET $evidence = CREATE trust_evidence CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    evidence_kind: 'identity_proof',
    source_id: $linked_id,
    weight: $confidence,
    confidence: $confidence,
    payload: { linked_id: $linked_id, link_kind: $link_kind, verified: $verified },
    observed_at: time::now(),
    source_grounding_refs: ['schemaorg:vocabulary'],
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence']
  };

  RETURN CREATE agent_identity_links CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    linked_id: $linked_id,
    link_kind: $link_kind,
    evidence_id: $evidence.id,
    verified: $verified,
    observed_at: time::now()
  };
};

DEFINE FUNCTION fn::record_agent_capability_claim($tenant_id, $subject_id, $capability, $issuer_id, $confidence, $verified) {
  LET $evidence = CREATE trust_evidence CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    evidence_kind: 'evidence_strength',
    source_id: $issuer_id,
    weight: $confidence,
    confidence: $confidence,
    payload: { capability: $capability, verified: $verified },
    observed_at: time::now(),
    source_grounding_refs: ['schemaorg:vocabulary'],
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence']
  };

  RETURN CREATE agent_capability_claims CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    capability: $capability,
    issuer_id: $issuer_id,
    confidence: $confidence,
    evidence_ids: [$evidence.id],
    verified: $verified,
    revoked: false,
    observed_at: time::now()
  };
};

DEFINE FUNCTION fn::revoke_external_agent($tenant_id, $subject_id, $issuer_id, $reason) {
  CREATE trust_evidence CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    evidence_kind: 'revocation',
    source_id: $issuer_id,
    weight: 1,
    confidence: 1,
    payload: { reason: $reason },
    observed_at: time::now(),
    source_grounding_refs: [],
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence']
  };

  UPDATE external_agent_profiles SET revoked = true WHERE semantic_id = $subject_id;
  UPDATE agent_capability_claims SET revoked = true WHERE subject_id = $subject_id;

  RETURN { revoked: true, subject_id: $subject_id, reason: $reason };
};

DEFINE FUNCTION fn::materialize_external_agent($tenant_id, $profile_id, $name) {
  LET $profile = SELECT * FROM $profile_id;
  IF count($profile) = 0 THEN { THROW 'external_profile_not_found'; };
  IF $profile[0].revoked THEN { THROW 'external_profile_revoked'; };

  LET $trust = fn::compute_trust_v1($tenant_id, $profile[0].semantic_id, 'system:federation', { type: 'federated_agent_import' });
  IF $trust.score < 0.70 THEN { THROW 'external_agent_trust_too_low'; };

  RETURN CREATE agents CONTENT {
    tenant_id: $tenant_id,
    name: $name,
    semantic_id: $profile[0].semantic_id,
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:SoftwareApplication', 'agx:Agent'],
    source_grounding_refs: ['schemaorg:vocabulary'],
    default_modules_loaded: false,
    trust_policy_id: trust_policies:default,
    created_at: time::now(),
    updated_at: time::now()
  };
};
