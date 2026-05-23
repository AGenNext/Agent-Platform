DEFINE TABLE authorization_contexts SCHEMAFULL;
DEFINE FIELD tenant_id ON authorization_contexts TYPE option<record<tenants>>;
DEFINE FIELD authorization_request_id ON authorization_contexts TYPE record<authorization_api_requests>;
DEFINE FIELD context_type ON authorization_contexts TYPE string;
DEFINE FIELD context_properties ON authorization_contexts TYPE object DEFAULT {};
DEFINE FIELD subject_ref ON authorization_contexts TYPE option<record<agent_identity_subjects>>;
DEFINE FIELD session_id ON authorization_contexts TYPE option<record<agent_identity_sessions>>;
DEFINE FIELD resource_type ON authorization_contexts TYPE option<string>;
DEFINE FIELD resource_id ON authorization_contexts TYPE option<string>;
DEFINE FIELD action ON authorization_contexts TYPE option<string>;
DEFINE FIELD environment ON authorization_contexts TYPE object DEFAULT {};
DEFINE FIELD purpose ON authorization_contexts TYPE option<string>;
DEFINE FIELD risk_level ON authorization_contexts TYPE string DEFAULT 'medium';
DEFINE FIELD evidence_ids ON authorization_contexts TYPE array<record> DEFAULT [];
DEFINE FIELD standard_ref ON authorization_contexts TYPE string DEFAULT 'https://openid.net/specs/authorization-api-1_0.html#name-context';
DEFINE FIELD jsonld_context ON authorization_contexts TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON authorization_contexts TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AuthorizationContext'];
DEFINE FIELD created_at ON authorization_contexts TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::record_authorization_context($tenant_id, $authorization_request_id, $context_type, $context_properties, $subject_ref, $session_id, $resource_type, $resource_id, $action, $environment, $purpose, $risk_level, $evidence_ids) {
  LET $request = SELECT * FROM $authorization_request_id;
  IF count($request) = 0 THEN { THROW 'authorization_api_request_not_found'; };
  IF $context_type = NONE OR string::len($context_type) = 0 THEN { THROW 'authorization_context_type_required'; };
  RETURN CREATE authorization_contexts CONTENT { tenant_id: $tenant_id, authorization_request_id: $authorization_request_id, context_type: $context_type, context_properties: $context_properties, subject_ref: $subject_ref, session_id: $session_id, resource_type: $resource_type, resource_id: $resource_id, action: $action, environment: $environment, purpose: $purpose, risk_level: $risk_level, evidence_ids: $evidence_ids, standard_ref: 'https://openid.net/specs/authorization-api-1_0.html#name-context', created_at: time::now() };
};

DEFINE FUNCTION fn::evaluate_authorization_api_request_with_full_context($authorization_request_id, $actor_id, $authorization_context_id, $action_properties_id, $compliance_gate_decision_id) {
  LET $request = SELECT * FROM $authorization_request_id;
  IF count($request) = 0 THEN { THROW 'authorization_api_request_not_found'; };
  LET $ctx = SELECT * FROM $authorization_context_id;
  IF count($ctx) = 0 THEN { THROW 'authorization_context_not_found'; };
  IF $ctx[0].authorization_request_id != $authorization_request_id THEN { THROW 'authorization_context_request_mismatch'; };
  LET $decision = fn::evaluate_authorization_api_request_with_context($authorization_request_id, $actor_id, $action_properties_id, { context_id: $authorization_context_id, risk_level: $ctx[0].risk_level, purpose: $ctx[0].purpose, context_properties: $ctx[0].context_properties }, $compliance_gate_decision_id);
  UPDATE $decision.id SET token_claims += { authorization_context_id: $authorization_context_id, authorization_context_standard_ref: 'https://openid.net/specs/authorization-api-1_0.html#name-context' };
  RETURN SELECT * FROM $decision.id;
};

DEFINE FUNCTION fn::require_authorization_context($authorization_request_id) {
  LET $ctx = SELECT * FROM authorization_contexts WHERE authorization_request_id = $authorization_request_id LIMIT 1;
  IF count($ctx) = 0 THEN { THROW 'authorization_context_required'; };
  RETURN true;
};
