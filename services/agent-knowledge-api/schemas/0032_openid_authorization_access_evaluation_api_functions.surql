DEFINE TABLE authorization_access_evaluation_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON authorization_access_evaluation_requests TYPE option<record<tenants>>;
DEFINE FIELD authorization_server_id ON authorization_access_evaluation_requests TYPE record<authorization_api_servers>;
DEFINE FIELD authorization_request_id ON authorization_access_evaluation_requests TYPE option<record<authorization_api_requests>>;
DEFINE FIELD authorization_context_id ON authorization_access_evaluation_requests TYPE option<record<authorization_contexts>>;
DEFINE FIELD action_properties_id ON authorization_access_evaluation_requests TYPE option<record<authorization_action_properties>>;
DEFINE FIELD subject_ref ON authorization_access_evaluation_requests TYPE record<agent_identity_subjects>;
DEFINE FIELD session_id ON authorization_access_evaluation_requests TYPE option<record<agent_identity_sessions>>;
DEFINE FIELD resource_type ON authorization_access_evaluation_requests TYPE string;
DEFINE FIELD resource_id ON authorization_access_evaluation_requests TYPE string;
DEFINE FIELD action ON authorization_access_evaluation_requests TYPE string;
DEFINE FIELD requested_scopes ON authorization_access_evaluation_requests TYPE array<string> DEFAULT [];
DEFINE FIELD evaluation_context ON authorization_access_evaluation_requests TYPE object DEFAULT {};
DEFINE FIELD request_hash ON authorization_access_evaluation_requests TYPE string;
DEFINE FIELD status ON authorization_access_evaluation_requests TYPE string DEFAULT 'pending';
DEFINE FIELD access_evaluation_decision_id ON authorization_access_evaluation_requests TYPE option<record<authorization_access_evaluation_decisions>>;
DEFINE FIELD standard_ref ON authorization_access_evaluation_requests TYPE string DEFAULT 'https://openid.net/specs/authorization-api-1_0.html#name-access-evaluation-api';
DEFINE FIELD jsonld_context ON authorization_access_evaluation_requests TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON authorization_access_evaluation_requests TYPE array<string> DEFAULT ['schema:AuthorizeAction', 'agx:AuthorizationAccessEvaluationRequest'];
DEFINE FIELD created_at ON authorization_access_evaluation_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON authorization_access_evaluation_requests TYPE option<datetime>;

DEFINE TABLE authorization_access_evaluation_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON authorization_access_evaluation_decisions TYPE option<record<tenants>>;
DEFINE FIELD access_evaluation_request_id ON authorization_access_evaluation_decisions TYPE record<authorization_access_evaluation_requests>;
DEFINE FIELD authorization_decision_id ON authorization_access_evaluation_decisions TYPE option<record<authorization_api_decisions>>;
DEFINE FIELD subject_ref ON authorization_access_evaluation_decisions TYPE record<agent_identity_subjects>;
DEFINE FIELD decision ON authorization_access_evaluation_decisions TYPE string;
DEFINE FIELD reason ON authorization_access_evaluation_decisions TYPE string;
DEFINE FIELD granted_actions ON authorization_access_evaluation_decisions TYPE array<object> DEFAULT [];
DEFINE FIELD denied_actions ON authorization_access_evaluation_decisions TYPE array<object> DEFAULT [];
DEFINE FIELD obligations ON authorization_access_evaluation_decisions TYPE array<object> DEFAULT [];
DEFINE FIELD advice ON authorization_access_evaluation_decisions TYPE array<object> DEFAULT [];
DEFINE FIELD token_claims ON authorization_access_evaluation_decisions TYPE object DEFAULT {};
DEFINE FIELD trust_score_id ON authorization_access_evaluation_decisions TYPE option<record<trust_scores>>;
DEFINE FIELD reliability_profile_id ON authorization_access_evaluation_decisions TYPE option<record<reliability_profiles>>;
DEFINE FIELD compliance_gate_decision_id ON authorization_access_evaluation_decisions TYPE option<record<compliance_gate_decisions>>;
DEFINE FIELD decision_context_id ON authorization_access_evaluation_decisions TYPE option<record<authorization_decision_contexts>>;
DEFINE FIELD decision_log_id ON authorization_access_evaluation_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD standard_ref ON authorization_access_evaluation_decisions TYPE string DEFAULT 'https://openid.net/specs/authorization-api-1_0.html#name-access-evaluation-api';
DEFINE FIELD jsonld_context ON authorization_access_evaluation_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON authorization_access_evaluation_decisions TYPE array<string> DEFAULT ['schema:AuthorizeAction', 'agx:AuthorizationAccessEvaluationDecision'];
DEFINE FIELD created_at ON authorization_access_evaluation_decisions TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON authorization_access_evaluation_decisions TYPE option<datetime>;

DEFINE FUNCTION fn::create_authorization_access_evaluation_request($tenant_id, $authorization_server_id, $authorization_request_id, $authorization_context_id, $action_properties_id, $subject_ref, $session_id, $resource_type, $resource_id, $action, $requested_scopes, $evaluation_context, $request_hash, $expires_at) {
  LET $server = SELECT * FROM $authorization_server_id;
  IF count($server) = 0 THEN { THROW 'authorization_api_server_not_found'; };
  LET $subject = SELECT * FROM $subject_ref;
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  IF $request_hash = NONE OR string::len($request_hash) = 0 THEN { THROW 'access_evaluation_request_hash_required'; };
  IF $authorization_context_id != NONE THEN {
    LET $ctx = SELECT * FROM $authorization_context_id;
    IF count($ctx) = 0 THEN { THROW 'authorization_context_not_found'; };
  };
  IF $action_properties_id != NONE THEN {
    LET $props = SELECT * FROM $action_properties_id;
    IF count($props) = 0 THEN { THROW 'authorization_action_properties_not_found'; };
  };
  RETURN CREATE authorization_access_evaluation_requests CONTENT { tenant_id: $tenant_id, authorization_server_id: $authorization_server_id, authorization_request_id: $authorization_request_id, authorization_context_id: $authorization_context_id, action_properties_id: $action_properties_id, subject_ref: $subject_ref, session_id: $session_id, resource_type: $resource_type, resource_id: $resource_id, action: $action, requested_scopes: $requested_scopes, evaluation_context: $evaluation_context, request_hash: $request_hash, status: 'pending', standard_ref: 'https://openid.net/specs/authorization-api-1_0.html#name-access-evaluation-api', created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::evaluate_authorization_access_evaluation_request($access_evaluation_request_id, $actor_id, $compliance_gate_decision_id) {
  LET $request = SELECT * FROM $access_evaluation_request_id;
  IF count($request) = 0 THEN { THROW 'authorization_access_evaluation_request_not_found'; };
  LET $session = IF $request[0].session_id = NONE THEN [] ELSE SELECT * FROM $request[0].session_id END;
  LET $scope_pass = IF count($request[0].requested_scopes) = 0 THEN true ELSE IF count($session) = 0 THEN false ELSE count(array::difference($request[0].requested_scopes, $session[0].scopes)) = 0 END END;
  LET $trust = fn::compute_trust_v1($request[0].tenant_id, string::concat($request[0].subject_ref), $actor_id, { type: 'openid_access_evaluation_api', resource_type: $request[0].resource_type, action: $request[0].action });
  LET $reliability = fn::compute_reliability($request[0].tenant_id, string::concat($request[0].subject_ref), { type: 'openid_access_evaluation_api', resource_type: $request[0].resource_type, action: $request[0].action }, NONE);
  LET $compliance_pass = IF $compliance_gate_decision_id = NONE THEN true ELSE fn::require_compliance_gate_passed($compliance_gate_decision_id) END;
  LET $context_present = $request[0].authorization_context_id != NONE;
  LET $action_props_present = $request[0].action_properties_id != NONE;
  LET $allowed = $scope_pass AND $trust.score >= 0.70 AND $reliability.reliability_score >= 0.50 AND $compliance_pass AND $context_present AND $action_props_present;
  LET $decision = IF $allowed THEN 'allow' ELSE 'deny' END;
  LET $obligations = IF $allowed THEN [{ kind: 'audit_log_required' }, { kind: 'decision_context_required' }, { kind: 'least_privilege_scope_required' }] ELSE [] END;
  LET $advice = IF $allowed THEN [] ELSE [{ kind: 'remediation', message: 'satisfy scopes trust reliability compliance context and action properties before access' }] END;
  LET $decision_log = fn::log_decision_context($request[0].tenant_id, 'openid_access_evaluation_api_decision', string::concat($request[0].subject_ref), $actor_id, NONE, NONE, { access_evaluation_request_id: $access_evaluation_request_id, requested_scopes: $request[0].requested_scopes, resource_type: $request[0].resource_type, resource_id: $request[0].resource_id, action: $request[0].action }, {}, {}, {}, { trust_score: $trust.score }, { reliability_score: $reliability.reliability_score }, {}, { compliance_gate_decision_id: $compliance_gate_decision_id, standard: 'https://openid.net/specs/authorization-api-1_0.html#name-access-evaluation-api' }, [{ kind: 'scope_pass', value: $scope_pass }, { kind: 'trust_threshold', value: 0.70 }, { kind: 'reliability_threshold', value: 0.50 }, { kind: 'authorization_context_required', value: true }, { kind: 'action_properties_required', value: true }], { scope_pass: $scope_pass, trust_score: $trust.score, reliability_score: $reliability.reliability_score, compliance_pass: $compliance_pass, context_present: $context_present, action_properties_present: $action_props_present }, [{ decision: 'allow' }, { decision: 'deny' }], { decision: $decision }, [], 'authorization_access_evaluation_completed', { obligations: $obligations, advice: $advice }, [$trust.id, $reliability.id], NONE, [], false);
  LET $decision_context = IF $request[0].authorization_request_id = NONE THEN NONE ELSE fn::record_authorization_decision_context($request[0].tenant_id, $request[0].authorization_request_id, NONE, $request[0].action_properties_id, { subject_ref: $request[0].subject_ref, session_id: $request[0].session_id }, { resource_type: $request[0].resource_type, resource_id: $request[0].resource_id }, { action: $request[0].action, requested_scopes: $request[0].requested_scopes }, { authorization_context_id: $request[0].authorization_context_id }, { evaluation_context: $request[0].evaluation_context }, { trust_score_id: $trust.id, trust_score: $trust.score }, { compliance_gate_decision_id: $compliance_gate_decision_id, compliance_pass: $compliance_pass }, { session_id: $request[0].session_id }, { standard_ref: 'https://openid.net/specs/authorization-api-1_0.html#name-access-evaluation-api' }, [$trust.id, $reliability.id]) END;
  LET $record = CREATE authorization_access_evaluation_decisions CONTENT { tenant_id: $request[0].tenant_id, access_evaluation_request_id: $access_evaluation_request_id, authorization_decision_id: NONE, subject_ref: $request[0].subject_ref, decision: $decision, reason: IF $allowed THEN 'access_evaluation_requirements_passed' ELSE 'access_evaluation_requirements_failed' END, granted_actions: IF $allowed THEN [{ resource_type: $request[0].resource_type, resource_id: $request[0].resource_id, action: $request[0].action, scopes: $request[0].requested_scopes }] ELSE [] END, denied_actions: IF $allowed THEN [] ELSE [{ resource_type: $request[0].resource_type, resource_id: $request[0].resource_id, action: $request[0].action, scopes: $request[0].requested_scopes }] END, obligations: $obligations, advice: $advice, token_claims: { sub: string::concat($request[0].subject_ref), aud: $request[0].resource_id, act: $request[0].action, scope: $request[0].requested_scopes, authorization_context_id: $request[0].authorization_context_id, action_properties_id: $request[0].action_properties_id }, trust_score_id: $trust.id, reliability_profile_id: $reliability.id, compliance_gate_decision_id: $compliance_gate_decision_id, decision_context_id: IF $decision_context = NONE THEN NONE ELSE $decision_context.id END, decision_log_id: $decision_log.id, standard_ref: 'https://openid.net/specs/authorization-api-1_0.html#name-access-evaluation-api', created_at: time::now(), expires_at: $request[0].expires_at };
  UPDATE $access_evaluation_request_id SET status = IF $allowed THEN 'allowed' ELSE 'denied' END, access_evaluation_decision_id = $record.id;
  RETURN $record;
};

DEFINE FUNCTION fn::require_access_evaluation_allowed($access_evaluation_decision_id) {
  LET $decision = SELECT * FROM $access_evaluation_decision_id;
  IF count($decision) = 0 THEN { THROW 'authorization_access_evaluation_decision_required'; };
  IF $decision[0].decision != 'allow' THEN { THROW 'authorization_access_evaluation_denied'; };
  RETURN true;
};
