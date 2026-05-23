DEFINE TABLE ap2_protocol_standards SCHEMAFULL;
DEFINE FIELD tenant_id ON ap2_protocol_standards TYPE option<record<tenants>>;
DEFINE FIELD key ON ap2_protocol_standards TYPE string;
DEFINE FIELD name ON ap2_protocol_standards TYPE string;
DEFINE FIELD standard_uri ON ap2_protocol_standards TYPE string;
DEFINE FIELD provider ON ap2_protocol_standards TYPE string DEFAULT 'google';
DEFINE FIELD standard_version ON ap2_protocol_standards TYPE string DEFAULT 'latest';
DEFINE FIELD status ON ap2_protocol_standards TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON ap2_protocol_standards TYPE array<string> DEFAULT ['google:agents-to-payments-ap2'];
DEFINE FIELD jsonld_context ON ap2_protocol_standards TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ap2_protocol_standards TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AP2ProtocolStandard'];
DEFINE FIELD created_at ON ap2_protocol_standards TYPE datetime DEFAULT time::now();
DEFINE INDEX ap2_protocol_standards_key_unique ON ap2_protocol_standards FIELDS tenant_id, key, standard_version UNIQUE;

DEFINE TABLE payment_providers SCHEMAFULL;
DEFINE FIELD tenant_id ON payment_providers TYPE option<record<tenants>>;
DEFINE FIELD key ON payment_providers TYPE string;
DEFINE FIELD name ON payment_providers TYPE string;
DEFINE FIELD provider_kind ON payment_providers TYPE string;
DEFINE FIELD endpoint_uri ON payment_providers TYPE option<string>;
DEFINE FIELD supported_currencies ON payment_providers TYPE array<string> DEFAULT [];
DEFINE FIELD supported_payment_methods ON payment_providers TYPE array<string> DEFAULT [];
DEFINE FIELD status ON payment_providers TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON payment_providers TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON payment_providers TYPE array<string> DEFAULT ['schema:Organization', 'agx:PaymentProvider'];
DEFINE FIELD created_at ON payment_providers TYPE datetime DEFAULT time::now();
DEFINE INDEX payment_providers_key_unique ON payment_providers FIELDS tenant_id, key UNIQUE;

DEFINE TABLE ap2_payment_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON ap2_payment_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON ap2_payment_policies TYPE string;
DEFINE FIELD name ON ap2_payment_policies TYPE string;
DEFINE FIELD max_amount_minor ON ap2_payment_policies TYPE int DEFAULT 0;
DEFINE FIELD currency ON ap2_payment_policies TYPE string DEFAULT 'USD';
DEFINE FIELD require_human_approval ON ap2_payment_policies TYPE bool DEFAULT true;
DEFINE FIELD require_human_approval_above_minor ON ap2_payment_policies TYPE int DEFAULT 0;
DEFINE FIELD require_authorization_api_grant ON ap2_payment_policies TYPE bool DEFAULT true;
DEFINE FIELD require_relationship_access ON ap2_payment_policies TYPE bool DEFAULT true;
DEFINE FIELD require_opa_policy_allow ON ap2_payment_policies TYPE bool DEFAULT true;
DEFINE FIELD require_compliance_gate ON ap2_payment_policies TYPE bool DEFAULT true;
DEFINE FIELD require_signed_mandates ON ap2_payment_policies TYPE bool DEFAULT true;
DEFINE FIELD allowed_merchant_categories ON ap2_payment_policies TYPE array<string> DEFAULT [];
DEFINE FIELD denied_merchant_categories ON ap2_payment_policies TYPE array<string> DEFAULT [];
DEFINE FIELD enabled ON ap2_payment_policies TYPE bool DEFAULT true;
DEFINE FIELD source_grounding_refs ON ap2_payment_policies TYPE array<string> DEFAULT ['google:agents-to-payments-ap2'];
DEFINE FIELD jsonld_context ON ap2_payment_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ap2_payment_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AP2PaymentPolicy'];
DEFINE FIELD created_at ON ap2_payment_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX ap2_payment_policies_key_unique ON ap2_payment_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE ap2_payment_mandates SCHEMAFULL;
DEFINE FIELD tenant_id ON ap2_payment_mandates TYPE option<record<tenants>>;
DEFINE FIELD mandate_ref ON ap2_payment_mandates TYPE string;
DEFINE FIELD mandate_kind ON ap2_payment_mandates TYPE string;
DEFINE FIELD agent_identity_subject_id ON ap2_payment_mandates TYPE record<agent_identity_subjects>;
DEFINE FIELD human_owner_id ON ap2_payment_mandates TYPE string;
DEFINE FIELD payment_provider_id ON ap2_payment_mandates TYPE option<record<payment_providers>>;
DEFINE FIELD merchant_id ON ap2_payment_mandates TYPE option<string>;
DEFINE FIELD merchant_category ON ap2_payment_mandates TYPE option<string>;
DEFINE FIELD amount_minor ON ap2_payment_mandates TYPE int;
DEFINE FIELD currency ON ap2_payment_mandates TYPE string;
DEFINE FIELD constraints ON ap2_payment_mandates TYPE array<object> DEFAULT [];
DEFINE FIELD purpose ON ap2_payment_mandates TYPE string;
DEFINE FIELD signed_payload_hash ON ap2_payment_mandates TYPE string;
DEFINE FIELD signature_payload ON ap2_payment_mandates TYPE object DEFAULT {};
DEFINE FIELD status ON ap2_payment_mandates TYPE string DEFAULT 'pending';
DEFINE FIELD decision_log_id ON ap2_payment_mandates TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON ap2_payment_mandates TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON ap2_payment_mandates TYPE option<datetime>;
DEFINE FIELD jsonld_context ON ap2_payment_mandates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ap2_payment_mandates TYPE array<string> DEFAULT ['schema:Permit', 'agx:AP2PaymentMandate'];
DEFINE INDEX ap2_payment_mandates_ref_unique ON ap2_payment_mandates FIELDS tenant_id, mandate_ref UNIQUE;

DEFINE TABLE ap2_payment_intents SCHEMAFULL;
DEFINE FIELD tenant_id ON ap2_payment_intents TYPE option<record<tenants>>;
DEFINE FIELD intent_ref ON ap2_payment_intents TYPE string;
DEFINE FIELD mandate_id ON ap2_payment_intents TYPE record<ap2_payment_mandates>;
DEFINE FIELD agent_identity_subject_id ON ap2_payment_intents TYPE record<agent_identity_subjects>;
DEFINE FIELD payment_provider_id ON ap2_payment_intents TYPE record<payment_providers>;
DEFINE FIELD merchant_id ON ap2_payment_intents TYPE string;
DEFINE FIELD merchant_category ON ap2_payment_intents TYPE option<string>;
DEFINE FIELD amount_minor ON ap2_payment_intents TYPE int;
DEFINE FIELD currency ON ap2_payment_intents TYPE string;
DEFINE FIELD line_items ON ap2_payment_intents TYPE array<object> DEFAULT [];
DEFINE FIELD status ON ap2_payment_intents TYPE string DEFAULT 'created';
DEFINE FIELD authorization_decision_id ON ap2_payment_intents TYPE option<record<authorization_access_evaluation_decisions>>;
DEFINE FIELD policy_decision_result_id ON ap2_payment_intents TYPE option<record<policy_decision_results>>;
DEFINE FIELD relationship_access_check_id ON ap2_payment_intents TYPE option<record<relationship_access_checks>>;
DEFINE FIELD compliance_gate_decision_id ON ap2_payment_intents TYPE option<record<compliance_gate_decisions>>;
DEFINE FIELD human_response_status ON ap2_payment_intents TYPE string DEFAULT 'pending';
DEFINE FIELD decision_log_id ON ap2_payment_intents TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON ap2_payment_intents TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON ap2_payment_intents TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON ap2_payment_intents TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ap2_payment_intents TYPE array<string> DEFAULT ['schema:PayAction', 'agx:AP2PaymentIntent'];
DEFINE INDEX ap2_payment_intents_ref_unique ON ap2_payment_intents FIELDS tenant_id, intent_ref UNIQUE;

DEFINE TABLE ap2_payment_authorizations SCHEMAFULL;
DEFINE FIELD tenant_id ON ap2_payment_authorizations TYPE option<record<tenants>>;
DEFINE FIELD payment_intent_id ON ap2_payment_authorizations TYPE record<ap2_payment_intents>;
DEFINE FIELD authorization_ref ON ap2_payment_authorizations TYPE string;
DEFINE FIELD provider_authorization_ref ON ap2_payment_authorizations TYPE option<string>;
DEFINE FIELD amount_minor ON ap2_payment_authorizations TYPE int;
DEFINE FIELD currency ON ap2_payment_authorizations TYPE string;
DEFINE FIELD status ON ap2_payment_authorizations TYPE string DEFAULT 'authorized';
DEFINE FIELD authorization_payload_hash ON ap2_payment_authorizations TYPE string;
DEFINE FIELD created_at ON ap2_payment_authorizations TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON ap2_payment_authorizations TYPE option<datetime>;
DEFINE FIELD jsonld_context ON ap2_payment_authorizations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ap2_payment_authorizations TYPE array<string> DEFAULT ['schema:PayAction', 'agx:AP2PaymentAuthorization'];
DEFINE INDEX ap2_payment_authorizations_ref_unique ON ap2_payment_authorizations FIELDS tenant_id, authorization_ref UNIQUE;

DEFINE TABLE ap2_payment_captures SCHEMAFULL;
DEFINE FIELD tenant_id ON ap2_payment_captures TYPE option<record<tenants>>;
DEFINE FIELD payment_authorization_id ON ap2_payment_captures TYPE record<ap2_payment_authorizations>;
DEFINE FIELD capture_ref ON ap2_payment_captures TYPE string;
DEFINE FIELD provider_capture_ref ON ap2_payment_captures TYPE option<string>;
DEFINE FIELD amount_minor ON ap2_payment_captures TYPE int;
DEFINE FIELD currency ON ap2_payment_captures TYPE string;
DEFINE FIELD status ON ap2_payment_captures TYPE string DEFAULT 'captured';
DEFINE FIELD capture_payload_hash ON ap2_payment_captures TYPE string;
DEFINE FIELD created_at ON ap2_payment_captures TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON ap2_payment_captures TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ap2_payment_captures TYPE array<string> DEFAULT ['schema:PayAction', 'agx:AP2PaymentCapture'];
DEFINE INDEX ap2_payment_captures_ref_unique ON ap2_payment_captures FIELDS tenant_id, capture_ref UNIQUE;

UPSERT ap2_protocol_standards:google_ap2_latest CONTENT { tenant_id: NONE, key: 'google_ap2', name: 'Agents to Payments Protocol', standard_uri: 'https://cloud.google.com/blog/products/ai-machine-learning/announcing-agents-to-payments-ap2-protocol', provider: 'google', standard_version: 'latest', status: 'active', source_grounding_refs: ['google:agents-to-payments-ap2'] };
UPSERT ap2_payment_policies:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default AP2 Payment Policy', max_amount_minor: 10000, currency: 'USD', require_human_approval: true, require_human_approval_above_minor: 0, require_authorization_api_grant: true, require_relationship_access: true, require_opa_policy_allow: true, require_compliance_gate: true, require_signed_mandates: true, allowed_merchant_categories: [], denied_merchant_categories: [], enabled: true, source_grounding_refs: ['google:agents-to-payments-ap2'] };

DEFINE FUNCTION fn::register_payment_provider($tenant_id, $key, $name, $provider_kind, $endpoint_uri, $supported_currencies, $supported_payment_methods) {
  LET $existing = SELECT * FROM payment_providers WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE payment_providers CONTENT { tenant_id: $tenant_id, key: $key, name: $name, provider_kind: $provider_kind, endpoint_uri: $endpoint_uri, supported_currencies: $supported_currencies, supported_payment_methods: $supported_payment_methods, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::select_ap2_payment_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM ap2_payment_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM ap2_payment_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN ap2_payment_policies:default;
};

DEFINE FUNCTION fn::create_ap2_payment_mandate($tenant_id, $mandate_ref, $mandate_kind, $agent_identity_subject_id, $human_owner_id, $payment_provider_id, $merchant_id, $merchant_category, $amount_minor, $currency, $constraints, $purpose, $signed_payload_hash, $signature_payload, $expires_at, $actor_id) {
  LET $subject = SELECT * FROM $agent_identity_subject_id;
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  IF $signed_payload_hash = NONE OR string::len($signed_payload_hash) = 0 THEN { THROW 'ap2_signed_mandate_hash_required'; };
  LET $decision_log = fn::log_decision_context($tenant_id, 'ap2_payment_mandate_created', string::concat($agent_identity_subject_id), $actor_id, NONE, NONE, { mandate_ref: $mandate_ref, mandate_kind: $mandate_kind, amount_minor: $amount_minor, currency: $currency, merchant_id: $merchant_id, purpose: $purpose }, {}, {}, {}, {}, {}, {}, { standard_ref: 'google:agents-to-payments-ap2' }, [{ kind: 'signed_mandate_required' }, { kind: 'human_owner_required' }, { kind: 'expiry_recommended' }], { signed_payload_hash: $signed_payload_hash, expires_at: $expires_at }, [{ decision: 'create_mandate' }, { decision: 'reject_mandate' }], { decision: 'create_mandate' }, [], 'ap2_payment_mandate_recorded', { signature_payload: $signature_payload }, [$agent_identity_subject_id], NONE, [], true);
  RETURN CREATE ap2_payment_mandates CONTENT { tenant_id: $tenant_id, mandate_ref: $mandate_ref, mandate_kind: $mandate_kind, agent_identity_subject_id: $agent_identity_subject_id, human_owner_id: $human_owner_id, payment_provider_id: $payment_provider_id, merchant_id: $merchant_id, merchant_category: $merchant_category, amount_minor: $amount_minor, currency: $currency, constraints: $constraints, purpose: $purpose, signed_payload_hash: $signed_payload_hash, signature_payload: $signature_payload, status: 'pending', decision_log_id: $decision_log.id, created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::approve_ap2_payment_mandate($mandate_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $mandate = SELECT * FROM $mandate_id;
  IF count($mandate) = 0 THEN { THROW 'ap2_payment_mandate_not_found'; };
  LET $response = fn::record_human_decision_response($mandate[0].tenant_id, $mandate[0].decision_log_id, NONE, NONE, $human_actor_id, 'ap2_payment_mandate_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $mandate_id SET status = IF $approval_status = 'approved' THEN 'active' ELSE 'rejected' END;
  RETURN SELECT * FROM $mandate_id;
};

DEFINE FUNCTION fn::create_ap2_payment_intent($tenant_id, $intent_ref, $mandate_id, $payment_provider_id, $merchant_id, $merchant_category, $amount_minor, $currency, $line_items, $authorization_decision_id, $policy_decision_result_id, $relationship_access_check_id, $compliance_gate_decision_id, $actor_id) {
  LET $mandate = SELECT * FROM $mandate_id;
  IF count($mandate) = 0 THEN { THROW 'ap2_payment_mandate_not_found'; };
  IF $mandate[0].status != 'active' THEN { THROW 'ap2_payment_mandate_not_active'; };
  IF $mandate[0].expires_at != NONE AND $mandate[0].expires_at <= time::now() THEN { THROW 'ap2_payment_mandate_expired'; };
  IF $amount_minor > $mandate[0].amount_minor THEN { THROW 'ap2_payment_amount_exceeds_mandate'; };
  IF $currency != $mandate[0].currency THEN { THROW 'ap2_payment_currency_mismatch'; };
  LET $policy = fn::select_ap2_payment_policy($tenant_id, 'default');
  IF $amount_minor > $policy.max_amount_minor THEN { THROW 'ap2_payment_amount_exceeds_policy'; };
  IF $merchant_category INSIDE $policy.denied_merchant_categories THEN { THROW 'ap2_merchant_category_denied'; };
  IF count($policy.allowed_merchant_categories) > 0 AND !$merchant_category INSIDE $policy.allowed_merchant_categories THEN { THROW 'ap2_merchant_category_not_allowed'; };
  IF $policy.require_authorization_api_grant THEN { fn::require_access_evaluation_allowed($authorization_decision_id); };
  IF $policy.require_opa_policy_allow THEN { fn::require_policy_allowed($policy_decision_result_id); };
  IF $policy.require_relationship_access THEN { fn::require_relationship_access_allowed($relationship_access_check_id); };
  IF $policy.require_compliance_gate THEN { fn::require_compliance_gate_passed($compliance_gate_decision_id); };
  LET $human_required = $policy.require_human_approval OR $amount_minor >= $policy.require_human_approval_above_minor;
  LET $decision_log = fn::log_decision_context($tenant_id, 'ap2_payment_intent_created', string::concat($mandate[0].agent_identity_subject_id), $actor_id, NONE, NONE, { intent_ref: $intent_ref, mandate_id: $mandate_id, merchant_id: $merchant_id, amount_minor: $amount_minor, currency: $currency, line_items: $line_items }, {}, {}, {}, {}, {}, {}, { policy_id: $policy.id, authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id, compliance_gate_decision_id: $compliance_gate_decision_id }, [{ kind: 'mandate_must_be_active' }, { kind: 'amount_within_mandate_and_policy' }, { kind: 'authorization_policy_relationship_compliance_required' }], { amount_minor: $amount_minor, policy_max_amount_minor: $policy.max_amount_minor, human_required: $human_required }, [{ decision: 'create_payment_intent' }, { decision: 'block_payment_intent' }], { decision: 'create_payment_intent' }, [], 'ap2_payment_intent_authorized_for_creation', { method: 'agx:ap2-payments-v1' }, [$mandate_id, $authorization_decision_id, $policy_decision_result_id, $relationship_access_check_id, $compliance_gate_decision_id], NONE, [], $human_required);
  RETURN CREATE ap2_payment_intents CONTENT { tenant_id: $tenant_id, intent_ref: $intent_ref, mandate_id: $mandate_id, agent_identity_subject_id: $mandate[0].agent_identity_subject_id, payment_provider_id: $payment_provider_id, merchant_id: $merchant_id, merchant_category: $merchant_category, amount_minor: $amount_minor, currency: $currency, line_items: $line_items, status: IF $human_required THEN 'pending_human_approval' ELSE 'authorized_to_confirm' END, authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id, compliance_gate_decision_id: $compliance_gate_decision_id, human_response_status: IF $human_required THEN 'pending' ELSE 'not_required' END, decision_log_id: $decision_log.id, created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::approve_ap2_payment_intent($payment_intent_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $intent = SELECT * FROM $payment_intent_id;
  IF count($intent) = 0 THEN { THROW 'ap2_payment_intent_not_found'; };
  LET $response = fn::record_human_decision_response($intent[0].tenant_id, $intent[0].decision_log_id, NONE, NONE, $human_actor_id, 'ap2_payment_intent_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $payment_intent_id SET status = IF $approval_status = 'approved' THEN 'authorized_to_confirm' ELSE 'rejected' END, human_response_status = $approval_status, updated_at = time::now();
  RETURN SELECT * FROM $payment_intent_id;
};

DEFINE FUNCTION fn::authorize_ap2_payment($tenant_id, $payment_intent_id, $authorization_ref, $provider_authorization_ref, $authorization_payload_hash, $expires_at) {
  LET $intent = SELECT * FROM $payment_intent_id;
  IF count($intent) = 0 THEN { THROW 'ap2_payment_intent_not_found'; };
  IF $intent[0].status != 'authorized_to_confirm' THEN { THROW 'ap2_payment_intent_not_authorized_to_confirm'; };
  IF $authorization_payload_hash = NONE OR string::len($authorization_payload_hash) = 0 THEN { THROW 'ap2_payment_authorization_hash_required'; };
  LET $auth = CREATE ap2_payment_authorizations CONTENT { tenant_id: $tenant_id, payment_intent_id: $payment_intent_id, authorization_ref: $authorization_ref, provider_authorization_ref: $provider_authorization_ref, amount_minor: $intent[0].amount_minor, currency: $intent[0].currency, status: 'authorized', authorization_payload_hash: $authorization_payload_hash, created_at: time::now(), expires_at: $expires_at };
  UPDATE $payment_intent_id SET status = 'authorized', updated_at = time::now();
  RETURN $auth;
};

DEFINE FUNCTION fn::capture_ap2_payment($tenant_id, $payment_authorization_id, $capture_ref, $provider_capture_ref, $amount_minor, $capture_payload_hash) {
  LET $auth = SELECT * FROM $payment_authorization_id;
  IF count($auth) = 0 THEN { THROW 'ap2_payment_authorization_not_found'; };
  IF $auth[0].status != 'authorized' THEN { THROW 'ap2_payment_authorization_not_active'; };
  IF $auth[0].expires_at != NONE AND $auth[0].expires_at <= time::now() THEN { THROW 'ap2_payment_authorization_expired'; };
  IF $amount_minor > $auth[0].amount_minor THEN { THROW 'ap2_capture_amount_exceeds_authorization'; };
  IF $capture_payload_hash = NONE OR string::len($capture_payload_hash) = 0 THEN { THROW 'ap2_capture_hash_required'; };
  LET $capture = CREATE ap2_payment_captures CONTENT { tenant_id: $tenant_id, payment_authorization_id: $payment_authorization_id, capture_ref: $capture_ref, provider_capture_ref: $provider_capture_ref, amount_minor: $amount_minor, currency: $auth[0].currency, status: 'captured', capture_payload_hash: $capture_payload_hash, created_at: time::now() };
  UPDATE $payment_authorization_id SET status = 'captured';
  UPDATE $auth[0].payment_intent_id SET status = 'captured', updated_at = time::now();
  RETURN $capture;
};

DEFINE FUNCTION fn::require_ap2_payment_captured($capture_id) {
  LET $capture = SELECT * FROM $capture_id;
  IF count($capture) = 0 THEN { THROW 'ap2_payment_capture_required'; };
  IF $capture[0].status != 'captured' THEN { THROW 'ap2_payment_not_captured'; };
  RETURN true;
};
