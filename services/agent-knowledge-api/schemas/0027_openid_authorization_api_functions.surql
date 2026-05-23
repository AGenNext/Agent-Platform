DEFINE TABLE authorization_api_servers SCHEMAFULL;
DEFINE FIELD tenant_id ON authorization_api_servers TYPE option<record<tenants>>;
DEFINE FIELD key ON authorization_api_servers TYPE string;
DEFINE FIELD issuer ON authorization_api_servers TYPE string;
DEFINE FIELD authorization_api_uri ON authorization_api_servers TYPE string;
DEFINE FIELD jwks_uri ON authorization_api_servers TYPE option<string>;
DEFINE FIELD status ON authorization_api_servers TYPE string DEFAULT 'active';
DEFINE FIELD standard_ref ON authorization_api_servers TYPE string DEFAULT 'https://openid.net/specs/authorization-api-1_0.html';
DEFINE FIELD jsonld_context ON authorization_api_servers TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON authorization_api_servers TYPE array<string> DEFAULT ['schema:WebAPI', 'agx:AuthorizationAPIServer'];
DEFINE FIELD created_at ON authorization_api_servers TYPE datetime DEFAULT time::now();
DEFINE INDEX authorization_api_servers_key_unique ON authorization_api_servers FIELDS tenant_id, key UNIQUE;

DEFINE TABLE authorization_api_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON authorization_api_requests TYPE option<record<tenants>>;
DEFINE FIELD authorization_server_id ON authorization_api_requests TYPE record<authorization_api_servers>;
DEFINE FIELD subject_ref ON authorization_api_requests TYPE record<agent_identity_subjects>;
DEFINE FIELD session_id ON authorization_api_requests TYPE option<record<agent_identity_sessions>>;
DEFINE FIELD resource_type ON authorization_api_requests TYPE string;
DEFINE FIELD resource_id ON authorization_api_requests TYPE string;
DEFINE FIELD action ON authorization_api_requests TYPE string;
DEFINE FIELD requested_scopes ON authorization_api_requests TYPE array<string> DEFAULT [];
DEFINE FIELD claims ON authorization_api_requests TYPE object DEFAULT {};
DEFINE FIELD request_hash ON authorization_api_requests TYPE string;
DEFINE FIELD status ON authorization_api_requests TYPE string DEFAULT 'pending';
DEFINE FIELD decision_id ON authorization_api_requests TYPE option<record<authorization_api_decisions>>;
DEFINE FIELD created_at ON authorization_api_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON authorization_api_requests TYPE option<datetime>;
DEFINE FIELD jsonld_context ON authorization_api_requests TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON authorization_api_requests TYPE array<string> DEFAULT ['schema:AuthorizeAction', 'agx:AuthorizationAPIRequest'];

DEFINE TABLE authorization_api_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON authorization_api_decisions TYPE option<record<tenants>>;
DEFINE FIELD authorization_request_id ON authorization_api_decisions TYPE record<authorization_api_requests>;
DEFINE FIELD subject_ref ON authorization_api_decisions TYPE record<agent_identity_subjects>;
DEFINE FIELD decision ON authorization_api_decisions TYPE string;
DEFINE FIELD reason ON authorization_api_decisions TYPE string;
DEFINE FIELD granted_scopes ON authorization_api_decisions TYPE array<string> DEFAULT [];
DEFINE FIELD denied_scopes ON authorization_api_decisions TYPE array<string> DEFAULT [];
DEFINE FIELD decision_token_hash ON authorization_api_decisions TYPE option<string>;
DEFINE FIELD token_claims ON authorization_api_decisions TYPE object DEFAULT {};
DEFINE FIELD trust_score_id ON authorization_api_decisions TYPE option<record<trust_scores>>;
DEFINE FIELD decision_log_id ON authorization_api_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON authorization_api_decisions TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON authorization_api_decisions TYPE option<datetime>;
DEFINE FIELD jsonld_context ON authorization_api_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON authorization_api_decisions TYPE array<string> DEFAULT ['schema:AuthorizeAction', 'agx:AuthorizationAPIDecision'];

DEFINE TABLE authorization_api_token_exchanges SCHEMAFULL;
DEFINE FIELD tenant_id ON authorization_api_token_exchanges TYPE option<record<tenants>>;
DEFINE FIELD decision_id ON authorization_api_token_exchanges TYPE record<authorization_api_decisions>;
DEFINE FIELD subject_ref ON authorization_api_token_exchanges TYPE record<agent_identity_subjects>;
DEFINE FIELD token_kind ON authorization_api_token_exchanges TYPE string DEFAULT 'access_token';
DEFINE FIELD token_hash ON authorization_api_token_exchanges TYPE string;
DEFINE FIELD audience ON authorization_api_token_exchanges TYPE array<string> DEFAULT [];
DEFINE FIELD scopes ON authorization_api_token_exchanges TYPE array<string> DEFAULT [];
DEFINE FIELD status ON authorization_api_token_exchanges TYPE string DEFAULT 'active';
DEFINE FIELD issued_at ON authorization_api_token_exchanges TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON authorization_api_token_exchanges TYPE option<datetime>;
DEFINE FIELD revoked_at ON authorization_api_token_exchanges TYPE option<datetime>;
DEFINE FIELD jsonld_context ON authorization_api_token_exchanges TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON authorization_api_token_exchanges TYPE array<string> DEFAULT ['schema:DigitalDocument', 'agx:AuthorizationAPITokenExchange'];

UPSERT identity_standards:openid_authorization_api_1_0 CONTENT { tenant_id: NONE, key: 'openid_authorization_api', name: 'OpenID Authorization API', standard_kind: 'authorization_api', version: '1.0', authority_uri: 'https://openid.net/specs/authorization-api-1_0.html', status: 'active', source_grounding_refs: ['openid:authorization-api:1.0'] };

DEFINE FUNCTION fn::register_authorization_api_server($tenant_id, $key, $issuer, $authorization_api_uri, $jwks_uri) {
  LET $existing = SELECT * FROM authorization_api_servers WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE authorization_api_servers CONTENT { tenant_id: $tenant_id, key: $key, issuer: $issuer, authorization_api_uri: $authorization_api_uri, jwks_uri: $jwks_uri, status: 'active', standard_ref: 'https://openid.net/specs/authorization-api-1_0.html', created_at: time::now() };
};

DEFINE FUNCTION fn::create_authorization_api_request($tenant_id, $authorization_server_id, $subject_ref, $session_id, $resource_type, $resource_id, $action, $requested_scopes, $claims, $request_hash, $expires_at) {
  LET $server = SELECT * FROM $authorization_server_id;
  LET $subject = SELECT * FROM $subject_ref;
  IF count($server) = 0 THEN { THROW 'authorization_api_server_not_found'; };
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  IF $request_hash = NONE OR string::len($request_hash) = 0 THEN { THROW 'authorization_request_hash_required'; };
  RETURN CREATE authorization_api_requests CONTENT { tenant_id: $tenant_id, authorization_server_id: $authorization_server_id, subject_ref: $subject_ref, session_id: $session_id, resource_type: $resource_type, resource_id: $resource_id, action: $action, requested_scopes: $requested_scopes, claims: $claims, request_hash: $request_hash, status: 'pending', created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::evaluate_authorization_api_request($authorization_request_id, $actor_id) {
  LET $request = SELECT * FROM $authorization_request_id;
  IF count($request) = 0 THEN { THROW 'authorization_api_request_not_found'; };
  LET $subject = SELECT * FROM $request[0].subject_ref;
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  LET $session = IF $request[0].session_id = NONE THEN [] ELSE SELECT * FROM $request[0].session_id END;
  LET $scope_pass = IF count($session) = 0 THEN false ELSE count(array::difference($request[0].requested_scopes, $session[0].scopes)) = 0 END;
  LET $trust = fn::compute_trust_v1($request[0].tenant_id, string::concat($request[0].subject_ref), $actor_id, { type: 'openid_authorization_api', resource_type: $request[0].resource_type, action: $request[0].action });
  LET $decision = IF $scope_pass AND $trust.score >= 0.70 THEN 'grant' ELSE 'deny' END;
  LET $denied_scopes = IF $scope_pass THEN [] ELSE array::difference($request[0].requested_scopes, IF count($session) = 0 THEN [] ELSE $session[0].scopes END) END;
  LET $decision_log = fn::log_decision_context($request[0].tenant_id, 'openid_authorization_api_decision', string::concat($request[0].subject_ref), $actor_id, NONE, NONE, { authorization_request_id: $authorization_request_id, requested_scopes: $request[0].requested_scopes, resource_type: $request[0].resource_type, resource_id: $request[0].resource_id, action: $request[0].action }, {}, {}, {}, { trust_score: $trust.score }, {}, {}, { standard: 'https://openid.net/specs/authorization-api-1_0.html' }, [{ kind: 'requested_scopes_must_be_in_session' }, { kind: 'trust_threshold', value: 0.70 }], { scope_pass: $scope_pass, trust_score: $trust.score }, [{ decision: 'grant' }, { decision: 'deny' }], { decision: $decision }, [], 'authorization_api_request_evaluated', { scope_pass: $scope_pass, trust_score: $trust.score, denied_scopes: $denied_scopes }, [$trust.id], NONE, [], false);
  LET $record = CREATE authorization_api_decisions CONTENT { tenant_id: $request[0].tenant_id, authorization_request_id: $authorization_request_id, subject_ref: $request[0].subject_ref, decision: $decision, reason: IF $decision = 'grant' THEN 'authorization_requirements_passed' ELSE 'authorization_requirements_failed' END, granted_scopes: IF $decision = 'grant' THEN $request[0].requested_scopes ELSE [] END, denied_scopes: $denied_scopes, token_claims: { sub: $subject[0].subject_id, aud: $request[0].resource_id, scope: $request[0].requested_scopes, act: $request[0].action, iss: $subject[0].issuer }, trust_score_id: $trust.id, decision_log_id: $decision_log.id, created_at: time::now(), expires_at: $request[0].expires_at };
  UPDATE $authorization_request_id SET status = IF $decision = 'grant' THEN 'granted' ELSE 'denied' END, decision_id = $record.id;
  RETURN $record;
};

DEFINE FUNCTION fn::record_authorization_api_token_exchange($tenant_id, $decision_id, $token_hash, $audience, $expires_at) {
  LET $decision = SELECT * FROM $decision_id;
  IF count($decision) = 0 THEN { THROW 'authorization_api_decision_not_found'; };
  IF $decision[0].decision != 'grant' THEN { THROW 'authorization_not_granted'; };
  IF $token_hash = NONE OR string::len($token_hash) = 0 THEN { THROW 'authorization_token_hash_required'; };
  LET $exchange = CREATE authorization_api_token_exchanges CONTENT { tenant_id: $tenant_id, decision_id: $decision_id, subject_ref: $decision[0].subject_ref, token_kind: 'access_token', token_hash: $token_hash, audience: $audience, scopes: $decision[0].granted_scopes, status: 'active', issued_at: time::now(), expires_at: $expires_at };
  UPDATE $decision_id SET decision_token_hash = $token_hash;
  RETURN $exchange;
};

DEFINE FUNCTION fn::revoke_authorization_api_token($token_exchange_id, $revoked_by, $reason) {
  LET $exchange = SELECT * FROM $token_exchange_id;
  IF count($exchange) = 0 THEN { THROW 'authorization_api_token_exchange_not_found'; };
  UPDATE $token_exchange_id SET status = 'revoked', revoked_at = time::now();
  CREATE trust_evidence CONTENT { tenant_id: $exchange[0].tenant_id, subject_id: string::concat($exchange[0].subject_ref), evidence_kind: 'revocation', source_id: $revoked_by, weight: 1, confidence: 1, payload: { token_exchange_id: $token_exchange_id, reason: $reason }, observed_at: time::now(), source_grounding_refs: ['openid:authorization-api:1.0'], jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence'] };
  RETURN SELECT * FROM $token_exchange_id;
};

DEFINE FUNCTION fn::require_authorization_api_grant($decision_id) {
  LET $decision = SELECT * FROM $decision_id;
  IF count($decision) = 0 THEN { THROW 'authorization_api_decision_required'; };
  IF $decision[0].decision != 'grant' THEN { THROW 'authorization_api_grant_required'; };
  RETURN true;
};
