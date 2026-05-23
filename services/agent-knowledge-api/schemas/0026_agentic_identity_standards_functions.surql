DEFINE TABLE identity_standards SCHEMAFULL;
DEFINE FIELD tenant_id ON identity_standards TYPE option<record<tenants>>;
DEFINE FIELD key ON identity_standards TYPE string;
DEFINE FIELD name ON identity_standards TYPE string;
DEFINE FIELD standard_kind ON identity_standards TYPE string;
DEFINE FIELD version ON identity_standards TYPE string;
DEFINE FIELD authority_uri ON identity_standards TYPE string;
DEFINE FIELD status ON identity_standards TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON identity_standards TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON identity_standards TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON identity_standards TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:IdentityStandard'];
DEFINE FIELD created_at ON identity_standards TYPE datetime DEFAULT time::now();
DEFINE INDEX identity_standards_key_unique ON identity_standards FIELDS tenant_id, key, version UNIQUE;

DEFINE TABLE agent_identity_subjects SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_identity_subjects TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON agent_identity_subjects TYPE string;
DEFINE FIELD subject_kind ON agent_identity_subjects TYPE string;
DEFINE FIELD agent_id ON agent_identity_subjects TYPE option<record<agents>>;
DEFINE FIELD application_id ON agent_identity_subjects TYPE option<record<applications>>;
DEFINE FIELD human_owner_id ON agent_identity_subjects TYPE option<string>;
DEFINE FIELD service_principal_id ON agent_identity_subjects TYPE option<string>;
DEFINE FIELD did ON agent_identity_subjects TYPE option<string>;
DEFINE FIELD issuer ON agent_identity_subjects TYPE string;
DEFINE FIELD status ON agent_identity_subjects TYPE string DEFAULT 'active';
DEFINE FIELD assurance_level ON agent_identity_subjects TYPE string DEFAULT 'low';
DEFINE FIELD jsonld_context ON agent_identity_subjects TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_identity_subjects TYPE array<string> DEFAULT ['schema:Thing', 'agx:AgentIdentitySubject'];
DEFINE FIELD created_at ON agent_identity_subjects TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON agent_identity_subjects TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_identity_subjects_subject_unique ON agent_identity_subjects FIELDS tenant_id, subject_id UNIQUE;

DEFINE TABLE agent_identity_credentials SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_identity_credentials TYPE option<record<tenants>>;
DEFINE FIELD subject_ref ON agent_identity_credentials TYPE record<agent_identity_subjects>;
DEFINE FIELD standard_id ON agent_identity_credentials TYPE record<identity_standards>;
DEFINE FIELD credential_kind ON agent_identity_credentials TYPE string;
DEFINE FIELD issuer ON agent_identity_credentials TYPE string;
DEFINE FIELD audience ON agent_identity_credentials TYPE array<string> DEFAULT [];
DEFINE FIELD claims ON agent_identity_credentials TYPE object DEFAULT {};
DEFINE FIELD proof ON agent_identity_credentials TYPE object DEFAULT {};
DEFINE FIELD credential_hash ON agent_identity_credentials TYPE string;
DEFINE FIELD hash_algorithm ON agent_identity_credentials TYPE string DEFAULT 'sha256';
DEFINE FIELD verified ON agent_identity_credentials TYPE bool DEFAULT false;
DEFINE FIELD revoked ON agent_identity_credentials TYPE bool DEFAULT false;
DEFINE FIELD issued_at ON agent_identity_credentials TYPE datetime;
DEFINE FIELD expires_at ON agent_identity_credentials TYPE option<datetime>;
DEFINE FIELD jsonld_context ON agent_identity_credentials TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_identity_credentials TYPE array<string> DEFAULT ['schema:DigitalDocument', 'agx:AgentIdentityCredential'];
DEFINE FIELD created_at ON agent_identity_credentials TYPE datetime DEFAULT time::now();

DEFINE TABLE agent_identity_sessions SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_identity_sessions TYPE option<record<tenants>>;
DEFINE FIELD subject_ref ON agent_identity_sessions TYPE record<agent_identity_subjects>;
DEFINE FIELD credential_id ON agent_identity_sessions TYPE option<record<agent_identity_credentials>>;
DEFINE FIELD session_kind ON agent_identity_sessions TYPE string DEFAULT 'agent_runtime_session';
DEFINE FIELD audience ON agent_identity_sessions TYPE string;
DEFINE FIELD delegated_by ON agent_identity_sessions TYPE option<string>;
DEFINE FIELD delegation_chain ON agent_identity_sessions TYPE array<object> DEFAULT [];
DEFINE FIELD scopes ON agent_identity_sessions TYPE array<string> DEFAULT [];
DEFINE FIELD status ON agent_identity_sessions TYPE string DEFAULT 'active';
DEFINE FIELD started_at ON agent_identity_sessions TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON agent_identity_sessions TYPE option<datetime>;
DEFINE FIELD jsonld_context ON agent_identity_sessions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_identity_sessions TYPE array<string> DEFAULT ['schema:Action', 'agx:AgentIdentitySession'];

DEFINE TABLE agent_identity_access_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_identity_access_decisions TYPE option<record<tenants>>;
DEFINE FIELD subject_ref ON agent_identity_access_decisions TYPE record<agent_identity_subjects>;
DEFINE FIELD session_id ON agent_identity_access_decisions TYPE option<record<agent_identity_sessions>>;
DEFINE FIELD resource_type ON agent_identity_access_decisions TYPE string;
DEFINE FIELD resource_id ON agent_identity_access_decisions TYPE string;
DEFINE FIELD action ON agent_identity_access_decisions TYPE string;
DEFINE FIELD decision ON agent_identity_access_decisions TYPE string;
DEFINE FIELD reason ON agent_identity_access_decisions TYPE string;
DEFINE FIELD trust_score_id ON agent_identity_access_decisions TYPE option<record<trust_scores>>;
DEFINE FIELD compliance_gate_decision_id ON agent_identity_access_decisions TYPE option<record<compliance_gate_decisions>>;
DEFINE FIELD decision_log_id ON agent_identity_access_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON agent_identity_access_decisions TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON agent_identity_access_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_identity_access_decisions TYPE array<string> DEFAULT ['schema:Action', 'agx:AgentIdentityAccessDecision'];

UPSERT identity_standards:openid_agentic_ai_2025 CONTENT { tenant_id: NONE, key: 'openid_agentic_ai', name: 'OpenID Identity Management for Agentic AI', standard_kind: 'agent_identity', version: '2025-10', authority_uri: 'https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf', status: 'active', source_grounding_refs: ['openid:agentic-ai-identity:2025-10'] };
UPSERT identity_standards:microsoft_entra_agentic_identity_2025 CONTENT { tenant_id: NONE, key: 'microsoft_entra_agentic_identity', name: 'Microsoft Perspective on Agentic Identity Standards', standard_kind: 'agent_identity', version: '2025', authority_uri: 'https://techcommunity.microsoft.com/blog/microsoft-entra-blog/microsoft%E2%80%99s-perspective-on-agentic-identity-standards/2111910', status: 'active', source_grounding_refs: ['microsoft:entra-agentic-identity:2025'] };
UPSERT identity_standards:arxiv_2505_19301 CONTENT { tenant_id: NONE, key: 'agentic_identity_research_2505_19301', name: 'Agentic Identity Research', standard_kind: 'research_grounding', version: '2505.19301v1', authority_uri: 'https://arxiv.org/html/2505.19301v1', status: 'active', source_grounding_refs: ['arxiv:2505.19301v1'] };

DEFINE FUNCTION fn::register_agent_identity_subject($tenant_id, $subject_id, $subject_kind, $agent_id, $application_id, $human_owner_id, $service_principal_id, $did, $issuer, $assurance_level) {
  LET $existing = SELECT * FROM agent_identity_subjects WHERE tenant_id = $tenant_id AND subject_id = $subject_id LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE agent_identity_subjects CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, subject_kind: $subject_kind, agent_id: $agent_id, application_id: $application_id, human_owner_id: $human_owner_id, service_principal_id: $service_principal_id, did: $did, issuer: $issuer, status: 'active', assurance_level: $assurance_level, created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::record_agent_identity_credential($tenant_id, $subject_ref, $standard_id, $credential_kind, $issuer, $audience, $claims, $proof, $credential_hash, $issued_at, $expires_at) {
  IF $credential_hash = NONE OR string::len($credential_hash) = 0 THEN { THROW 'credential_hash_required'; };
  LET $subject = SELECT * FROM $subject_ref;
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  LET $standard = SELECT * FROM $standard_id;
  IF count($standard) = 0 THEN { THROW 'identity_standard_not_found'; };
  RETURN CREATE agent_identity_credentials CONTENT { tenant_id: $tenant_id, subject_ref: $subject_ref, standard_id: $standard_id, credential_kind: $credential_kind, issuer: $issuer, audience: $audience, claims: $claims, proof: $proof, credential_hash: $credential_hash, verified: false, revoked: false, issued_at: $issued_at, expires_at: $expires_at, created_at: time::now() };
};

DEFINE FUNCTION fn::verify_agent_identity_credential($credential_id, $verifier_id, $verified, $reason) {
  LET $credential = SELECT * FROM $credential_id;
  IF count($credential) = 0 THEN { THROW 'agent_identity_credential_not_found'; };
  UPDATE $credential_id SET verified = $verified;
  CREATE trust_evidence CONTENT { tenant_id: $credential[0].tenant_id, subject_id: string::concat($credential[0].subject_ref), evidence_kind: 'identity_proof', source_id: $verifier_id, weight: IF $verified THEN 1 ELSE 0 END, confidence: 0.9, payload: { credential_id: $credential_id, reason: $reason }, observed_at: time::now(), source_grounding_refs: ['openid:agentic-ai-identity:2025-10', 'microsoft:entra-agentic-identity:2025'], jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence'] };
  RETURN SELECT * FROM $credential_id;
};

DEFINE FUNCTION fn::start_agent_identity_session($tenant_id, $subject_ref, $credential_id, $audience, $delegated_by, $delegation_chain, $scopes, $expires_at) {
  LET $subject = SELECT * FROM $subject_ref;
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  IF $subject[0].status != 'active' THEN { THROW 'agent_identity_subject_not_active'; };
  IF $credential_id != NONE THEN {
    LET $credential = SELECT * FROM $credential_id;
    IF count($credential) = 0 THEN { THROW 'agent_identity_credential_not_found'; };
    IF !$credential[0].verified OR $credential[0].revoked THEN { THROW 'agent_identity_credential_not_valid'; };
  };
  RETURN CREATE agent_identity_sessions CONTENT { tenant_id: $tenant_id, subject_ref: $subject_ref, credential_id: $credential_id, audience: $audience, delegated_by: $delegated_by, delegation_chain: $delegation_chain, scopes: $scopes, status: 'active', started_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::evaluate_agent_identity_access($tenant_id, $subject_ref, $session_id, $resource_type, $resource_id, $action, $required_scope, $required_assurance_level, $actor_id) {
  LET $subject = SELECT * FROM $subject_ref;
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  LET $session = IF $session_id = NONE THEN [] ELSE SELECT * FROM $session_id END;
  IF $session_id != NONE AND count($session) = 0 THEN { THROW 'agent_identity_session_not_found'; };
  IF $session_id != NONE AND $session[0].status != 'active' THEN { THROW 'agent_identity_session_not_active'; };
  LET $scope_pass = IF $session_id = NONE THEN false ELSE $required_scope INSIDE $session[0].scopes END;
  LET $assurance_pass = IF $required_assurance_level = 'low' THEN true ELSE IF $required_assurance_level = 'medium' THEN $subject[0].assurance_level IN ['medium', 'high'] ELSE $subject[0].assurance_level = 'high' END END;
  LET $trust = fn::compute_trust_v1($tenant_id, string::concat($subject_ref), $actor_id, { type: 'agent_identity_access', resource_type: $resource_type, action: $action });
  LET $decision = IF $scope_pass AND $assurance_pass AND $trust.score >= 0.70 THEN 'allow' ELSE 'deny' END;
  LET $reason = IF $decision = 'allow' THEN 'identity_access_requirements_passed' ELSE 'identity_access_requirements_failed' END;
  LET $decision_log = fn::log_decision_context($tenant_id, 'agent_identity_access', string::concat($subject_ref), $actor_id, NONE, NONE, { subject_ref: $subject_ref, session_id: $session_id, resource_type: $resource_type, resource_id: $resource_id, action: $action }, {}, {}, {}, { trust_score: $trust.score }, {}, {}, { required_scope: $required_scope, required_assurance_level: $required_assurance_level }, [{ kind: 'scope_required', value: $required_scope }, { kind: 'assurance_required', value: $required_assurance_level }, { kind: 'trust_threshold', value: 0.70 }], { scope_pass: $scope_pass, assurance_pass: $assurance_pass, trust_score: $trust.score }, [{ decision: 'allow' }, { decision: 'deny' }], { decision: $decision }, [], 'agent_identity_access_evaluated', { reason: $reason }, [$trust.id], NONE, [], false);
  RETURN CREATE agent_identity_access_decisions CONTENT { tenant_id: $tenant_id, subject_ref: $subject_ref, session_id: $session_id, resource_type: $resource_type, resource_id: $resource_id, action: $action, decision: $decision, reason: $reason, trust_score_id: $trust.id, decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::require_agent_identity_access_allowed($access_decision_id) {
  LET $decision = SELECT * FROM $access_decision_id;
  IF count($decision) = 0 THEN { THROW 'agent_identity_access_decision_required'; };
  IF $decision[0].decision != 'allow' THEN { THROW 'agent_identity_access_denied'; };
  RETURN true;
};
