DEFINE TABLE ucp_protocol_standards SCHEMAFULL;
DEFINE FIELD tenant_id ON ucp_protocol_standards TYPE option<record<tenants>>;
DEFINE FIELD key ON ucp_protocol_standards TYPE string;
DEFINE FIELD name ON ucp_protocol_standards TYPE string;
DEFINE FIELD standard_uri ON ucp_protocol_standards TYPE string;
DEFINE FIELD provider ON ucp_protocol_standards TYPE string DEFAULT 'google';
DEFINE FIELD standard_version ON ucp_protocol_standards TYPE string DEFAULT 'latest';
DEFINE FIELD status ON ucp_protocol_standards TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON ucp_protocol_standards TYPE array<string> DEFAULT ['google:universal-commerce-protocol-ucp'];
DEFINE FIELD jsonld_context ON ucp_protocol_standards TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ucp_protocol_standards TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:UCPProtocolStandard'];
DEFINE FIELD created_at ON ucp_protocol_standards TYPE datetime DEFAULT time::now();
DEFINE INDEX ucp_protocol_standards_key_unique ON ucp_protocol_standards FIELDS tenant_id, key, standard_version UNIQUE;

DEFINE TABLE commerce_providers SCHEMAFULL;
DEFINE FIELD tenant_id ON commerce_providers TYPE option<record<tenants>>;
DEFINE FIELD key ON commerce_providers TYPE string;
DEFINE FIELD name ON commerce_providers TYPE string;
DEFINE FIELD provider_kind ON commerce_providers TYPE string;
DEFINE FIELD endpoint_uri ON commerce_providers TYPE option<string>;
DEFINE FIELD supported_catalog_types ON commerce_providers TYPE array<string> DEFAULT [];
DEFINE FIELD supported_checkout_methods ON commerce_providers TYPE array<string> DEFAULT [];
DEFINE FIELD supported_fulfillment_methods ON commerce_providers TYPE array<string> DEFAULT [];
DEFINE FIELD status ON commerce_providers TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON commerce_providers TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON commerce_providers TYPE array<string> DEFAULT ['schema:Organization', 'agx:CommerceProvider'];
DEFINE FIELD created_at ON commerce_providers TYPE datetime DEFAULT time::now();
DEFINE INDEX commerce_providers_key_unique ON commerce_providers FIELDS tenant_id, key UNIQUE;

DEFINE TABLE ucp_commerce_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON ucp_commerce_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON ucp_commerce_policies TYPE string;
DEFINE FIELD name ON ucp_commerce_policies TYPE string;
DEFINE FIELD max_cart_amount_minor ON ucp_commerce_policies TYPE int DEFAULT 10000;
DEFINE FIELD currency ON ucp_commerce_policies TYPE string DEFAULT 'USD';
DEFINE FIELD require_price_integrity_hash ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD require_inventory_confirmation ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD require_merchant_trust ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD min_merchant_trust_score ON ucp_commerce_policies TYPE number DEFAULT 0.70 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD require_ap2_payment_capture ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD require_human_approval ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD require_human_approval_above_minor ON ucp_commerce_policies TYPE int DEFAULT 0;
DEFINE FIELD require_authorization_api_grant ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD require_opa_policy_allow ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD require_relationship_access ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD require_compliance_gate ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD allowed_categories ON ucp_commerce_policies TYPE array<string> DEFAULT [];
DEFINE FIELD denied_categories ON ucp_commerce_policies TYPE array<string> DEFAULT [];
DEFINE FIELD enabled ON ucp_commerce_policies TYPE bool DEFAULT true;
DEFINE FIELD source_grounding_refs ON ucp_commerce_policies TYPE array<string> DEFAULT ['google:universal-commerce-protocol-ucp'];
DEFINE FIELD jsonld_context ON ucp_commerce_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ucp_commerce_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:UCPCommercePolicy'];
DEFINE FIELD created_at ON ucp_commerce_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX ucp_commerce_policies_key_unique ON ucp_commerce_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE ucp_product_offers SCHEMAFULL;
DEFINE FIELD tenant_id ON ucp_product_offers TYPE option<record<tenants>>;
DEFINE FIELD offer_ref ON ucp_product_offers TYPE string;
DEFINE FIELD commerce_provider_id ON ucp_product_offers TYPE record<commerce_providers>;
DEFINE FIELD merchant_id ON ucp_product_offers TYPE string;
DEFINE FIELD merchant_category ON ucp_product_offers TYPE option<string>;
DEFINE FIELD product_id ON ucp_product_offers TYPE string;
DEFINE FIELD product_name ON ucp_product_offers TYPE string;
DEFINE FIELD description ON ucp_product_offers TYPE string;
DEFINE FIELD category ON ucp_product_offers TYPE option<string>;
DEFINE FIELD price_minor ON ucp_product_offers TYPE int;
DEFINE FIELD currency ON ucp_product_offers TYPE string;
DEFINE FIELD availability ON ucp_product_offers TYPE string DEFAULT 'unknown';
DEFINE FIELD fulfillment_options ON ucp_product_offers TYPE array<object> DEFAULT [];
DEFINE FIELD price_valid_until ON ucp_product_offers TYPE option<datetime>;
DEFINE FIELD offer_payload_hash ON ucp_product_offers TYPE string;
DEFINE FIELD source_uri ON ucp_product_offers TYPE option<string>;
DEFINE FIELD trust_score_id ON ucp_product_offers TYPE option<record<trust_scores>>;
DEFINE FIELD jsonld_context ON ucp_product_offers TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ucp_product_offers TYPE array<string> DEFAULT ['schema:Offer', 'agx:UCPProductOffer'];
DEFINE FIELD created_at ON ucp_product_offers TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON ucp_product_offers TYPE datetime DEFAULT time::now();
DEFINE INDEX ucp_product_offers_ref_unique ON ucp_product_offers FIELDS tenant_id, offer_ref UNIQUE;

DEFINE TABLE ucp_carts SCHEMAFULL;
DEFINE FIELD tenant_id ON ucp_carts TYPE option<record<tenants>>;
DEFINE FIELD cart_ref ON ucp_carts TYPE string;
DEFINE FIELD agent_identity_subject_id ON ucp_carts TYPE record<agent_identity_subjects>;
DEFINE FIELD human_owner_id ON ucp_carts TYPE string;
DEFINE FIELD commerce_provider_id ON ucp_carts TYPE record<commerce_providers>;
DEFINE FIELD status ON ucp_carts TYPE string DEFAULT 'created';
DEFINE FIELD currency ON ucp_carts TYPE string;
DEFINE FIELD subtotal_minor ON ucp_carts TYPE int DEFAULT 0;
DEFINE FIELD estimated_tax_minor ON ucp_carts TYPE int DEFAULT 0;
DEFINE FIELD estimated_shipping_minor ON ucp_carts TYPE int DEFAULT 0;
DEFINE FIELD total_minor ON ucp_carts TYPE int DEFAULT 0;
DEFINE FIELD cart_payload_hash ON ucp_carts TYPE string;
DEFINE FIELD authorization_decision_id ON ucp_carts TYPE option<record<authorization_access_evaluation_decisions>>;
DEFINE FIELD policy_decision_result_id ON ucp_carts TYPE option<record<policy_decision_results>>;
DEFINE FIELD relationship_access_check_id ON ucp_carts TYPE option<record<relationship_access_checks>>;
DEFINE FIELD compliance_gate_decision_id ON ucp_carts TYPE option<record<compliance_gate_decisions>>;
DEFINE FIELD decision_log_id ON ucp_carts TYPE option<record<decision_context_logs>>;
DEFINE FIELD human_response_status ON ucp_carts TYPE string DEFAULT 'pending';
DEFINE FIELD created_at ON ucp_carts TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON ucp_carts TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON ucp_carts TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ucp_carts TYPE array<string> DEFAULT ['schema:Order', 'agx:UCPCart'];
DEFINE INDEX ucp_carts_ref_unique ON ucp_carts FIELDS tenant_id, cart_ref UNIQUE;

DEFINE TABLE ucp_cart_items SCHEMAFULL;
DEFINE FIELD tenant_id ON ucp_cart_items TYPE option<record<tenants>>;
DEFINE FIELD cart_id ON ucp_cart_items TYPE record<ucp_carts>;
DEFINE FIELD offer_id ON ucp_cart_items TYPE record<ucp_product_offers>;
DEFINE FIELD quantity ON ucp_cart_items TYPE int DEFAULT 1;
DEFINE FIELD unit_price_minor ON ucp_cart_items TYPE int;
DEFINE FIELD currency ON ucp_cart_items TYPE string;
DEFINE FIELD line_total_minor ON ucp_cart_items TYPE int;
DEFINE FIELD item_payload_hash ON ucp_cart_items TYPE string;
DEFINE FIELD created_at ON ucp_cart_items TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON ucp_cart_items TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ucp_cart_items TYPE array<string> DEFAULT ['schema:OrderItem', 'agx:UCPCartItem'];

DEFINE TABLE ucp_orders SCHEMAFULL;
DEFINE FIELD tenant_id ON ucp_orders TYPE option<record<tenants>>;
DEFINE FIELD order_ref ON ucp_orders TYPE string;
DEFINE FIELD cart_id ON ucp_orders TYPE record<ucp_carts>;
DEFINE FIELD ap2_payment_capture_id ON ucp_orders TYPE option<record<ap2_payment_captures>>;
DEFINE FIELD commerce_provider_id ON ucp_orders TYPE record<commerce_providers>;
DEFINE FIELD merchant_id ON ucp_orders TYPE string;
DEFINE FIELD status ON ucp_orders TYPE string DEFAULT 'placed';
DEFINE FIELD total_minor ON ucp_orders TYPE int;
DEFINE FIELD currency ON ucp_orders TYPE string;
DEFINE FIELD fulfillment_status ON ucp_orders TYPE string DEFAULT 'pending';
DEFINE FIELD order_payload_hash ON ucp_orders TYPE string;
DEFINE FIELD provider_order_ref ON ucp_orders TYPE option<string>;
DEFINE FIELD decision_log_id ON ucp_orders TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON ucp_orders TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON ucp_orders TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON ucp_orders TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON ucp_orders TYPE array<string> DEFAULT ['schema:Order', 'agx:UCPOrder'];
DEFINE INDEX ucp_orders_ref_unique ON ucp_orders FIELDS tenant_id, order_ref UNIQUE;

UPSERT ucp_protocol_standards:google_ucp_latest CONTENT { tenant_id: NONE, key: 'google_ucp', name: 'Universal Commerce Protocol', standard_uri: 'https://developers.googleblog.com/under-the-hood-universal-commerce-protocol-ucp/', provider: 'google', standard_version: 'latest', status: 'active', source_grounding_refs: ['google:universal-commerce-protocol-ucp'] };
UPSERT ucp_commerce_policies:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default UCP Commerce Policy', max_cart_amount_minor: 10000, currency: 'USD', require_price_integrity_hash: true, require_inventory_confirmation: true, require_merchant_trust: true, min_merchant_trust_score: 0.70, require_ap2_payment_capture: true, require_human_approval: true, require_human_approval_above_minor: 0, require_authorization_api_grant: true, require_opa_policy_allow: true, require_relationship_access: true, require_compliance_gate: true, allowed_categories: [], denied_categories: [], enabled: true, source_grounding_refs: ['google:universal-commerce-protocol-ucp'] };

DEFINE FUNCTION fn::register_commerce_provider($tenant_id, $key, $name, $provider_kind, $endpoint_uri, $supported_catalog_types, $supported_checkout_methods, $supported_fulfillment_methods) {
  LET $existing = SELECT * FROM commerce_providers WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE commerce_providers CONTENT { tenant_id: $tenant_id, key: $key, name: $name, provider_kind: $provider_kind, endpoint_uri: $endpoint_uri, supported_catalog_types: $supported_catalog_types, supported_checkout_methods: $supported_checkout_methods, supported_fulfillment_methods: $supported_fulfillment_methods, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::select_ucp_commerce_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM ucp_commerce_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM ucp_commerce_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN ucp_commerce_policies:default;
};

DEFINE FUNCTION fn::record_ucp_product_offer($tenant_id, $commerce_provider_id, $offer_ref, $merchant_id, $merchant_category, $product_id, $product_name, $description, $category, $price_minor, $currency, $availability, $fulfillment_options, $price_valid_until, $offer_payload_hash, $source_uri, $actor_id) {
  LET $provider = SELECT * FROM $commerce_provider_id;
  IF count($provider) = 0 THEN { THROW 'commerce_provider_not_found'; };
  IF $offer_payload_hash = NONE OR string::len($offer_payload_hash) = 0 THEN { THROW 'ucp_offer_payload_hash_required'; };
  LET $trust = fn::compute_trust_v1($tenant_id, string::concat('merchant:', $merchant_id), $actor_id, { type: 'ucp_merchant_offer', category: $category, price_minor: $price_minor, currency: $currency });
  RETURN CREATE ucp_product_offers CONTENT { tenant_id: $tenant_id, offer_ref: $offer_ref, commerce_provider_id: $commerce_provider_id, merchant_id: $merchant_id, merchant_category: $merchant_category, product_id: $product_id, product_name: $product_name, description: $description, category: $category, price_minor: $price_minor, currency: $currency, availability: $availability, fulfillment_options: $fulfillment_options, price_valid_until: $price_valid_until, offer_payload_hash: $offer_payload_hash, source_uri: $source_uri, trust_score_id: $trust.id, created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::create_ucp_cart($tenant_id, $cart_ref, $agent_identity_subject_id, $human_owner_id, $commerce_provider_id, $currency, $cart_payload_hash, $authorization_decision_id, $policy_decision_result_id, $relationship_access_check_id, $compliance_gate_decision_id, $actor_id) {
  IF $cart_payload_hash = NONE OR string::len($cart_payload_hash) = 0 THEN { THROW 'ucp_cart_payload_hash_required'; };
  LET $policy = fn::select_ucp_commerce_policy($tenant_id, 'default');
  IF $policy.require_authorization_api_grant THEN { fn::require_access_evaluation_allowed($authorization_decision_id); };
  IF $policy.require_opa_policy_allow THEN { fn::require_policy_allowed($policy_decision_result_id); };
  IF $policy.require_relationship_access THEN { fn::require_relationship_access_allowed($relationship_access_check_id); };
  IF $policy.require_compliance_gate THEN { fn::require_compliance_gate_passed($compliance_gate_decision_id); };
  LET $decision_log = fn::log_decision_context($tenant_id, 'ucp_cart_created', string::concat($agent_identity_subject_id), $actor_id, NONE, NONE, { cart_ref: $cart_ref, currency: $currency, human_owner_id: $human_owner_id }, {}, {}, {}, {}, {}, {}, { policy_id: $policy.id, authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id, compliance_gate_decision_id: $compliance_gate_decision_id }, [{ kind: 'ucp_authorization_policy_relationship_compliance_required' }, { kind: 'cart_payload_hash_required' }], { cart_payload_hash: $cart_payload_hash }, [{ decision: 'create_cart' }, { decision: 'block_cart' }], { decision: 'create_cart' }, [], 'ucp_cart_authorized_for_creation', { method: 'agx:ucp-commerce-v1' }, [$authorization_decision_id, $policy_decision_result_id, $relationship_access_check_id, $compliance_gate_decision_id], NONE, [], $policy.require_human_approval);
  RETURN CREATE ucp_carts CONTENT { tenant_id: $tenant_id, cart_ref: $cart_ref, agent_identity_subject_id: $agent_identity_subject_id, human_owner_id: $human_owner_id, commerce_provider_id: $commerce_provider_id, status: IF $policy.require_human_approval THEN 'pending_human_approval' ELSE 'open' END, currency: $currency, cart_payload_hash: $cart_payload_hash, authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id, compliance_gate_decision_id: $compliance_gate_decision_id, decision_log_id: $decision_log.id, human_response_status: IF $policy.require_human_approval THEN 'pending' ELSE 'not_required' END, created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::approve_ucp_cart($cart_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $cart = SELECT * FROM $cart_id;
  IF count($cart) = 0 THEN { THROW 'ucp_cart_not_found'; };
  LET $response = fn::record_human_decision_response($cart[0].tenant_id, $cart[0].decision_log_id, NONE, NONE, $human_actor_id, 'ucp_cart_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $cart_id SET status = IF $approval_status = 'approved' THEN 'open' ELSE 'rejected' END, human_response_status = $approval_status, updated_at = time::now();
  RETURN SELECT * FROM $cart_id;
};

DEFINE FUNCTION fn::add_ucp_cart_item($tenant_id, $cart_id, $offer_id, $quantity, $item_payload_hash) {
  LET $cart = SELECT * FROM $cart_id;
  LET $offer = SELECT * FROM $offer_id;
  IF count($cart) = 0 THEN { THROW 'ucp_cart_not_found'; };
  IF count($offer) = 0 THEN { THROW 'ucp_offer_not_found'; };
  IF $cart[0].status != 'open' THEN { THROW 'ucp_cart_not_open'; };
  IF $offer[0].availability NOT IN ['in_stock', 'available'] THEN { THROW 'ucp_offer_not_available'; };
  IF $offer[0].price_valid_until != NONE AND $offer[0].price_valid_until <= time::now() THEN { THROW 'ucp_offer_price_expired'; };
  IF $item_payload_hash = NONE OR string::len($item_payload_hash) = 0 THEN { THROW 'ucp_item_payload_hash_required'; };
  LET $policy = fn::select_ucp_commerce_policy($tenant_id, 'default');
  IF $offer[0].category INSIDE $policy.denied_categories THEN { THROW 'ucp_category_denied'; };
  IF count($policy.allowed_categories) > 0 AND !$offer[0].category INSIDE $policy.allowed_categories THEN { THROW 'ucp_category_not_allowed'; };
  LET $merchant_trust = SELECT * FROM $offer[0].trust_score_id;
  IF $policy.require_merchant_trust AND count($merchant_trust) > 0 AND $merchant_trust[0].score < $policy.min_merchant_trust_score THEN { THROW 'ucp_merchant_trust_too_low'; };
  LET $line_total = $offer[0].price_minor * $quantity;
  IF ($cart[0].total_minor + $line_total) > $policy.max_cart_amount_minor THEN { THROW 'ucp_cart_amount_exceeds_policy'; };
  LET $item = CREATE ucp_cart_items CONTENT { tenant_id: $tenant_id, cart_id: $cart_id, offer_id: $offer_id, quantity: $quantity, unit_price_minor: $offer[0].price_minor, currency: $offer[0].currency, line_total_minor: $line_total, item_payload_hash: $item_payload_hash, created_at: time::now() };
  UPDATE $cart_id SET subtotal_minor += $line_total, total_minor += $line_total, updated_at = time::now();
  RETURN $item;
};

DEFINE FUNCTION fn::place_ucp_order($tenant_id, $order_ref, $cart_id, $ap2_payment_capture_id, $provider_order_ref, $order_payload_hash, $actor_id) {
  LET $cart = SELECT * FROM $cart_id;
  IF count($cart) = 0 THEN { THROW 'ucp_cart_not_found'; };
  IF $cart[0].status != 'open' THEN { THROW 'ucp_cart_not_ready_for_order'; };
  LET $items = SELECT * FROM ucp_cart_items WHERE cart_id = $cart_id;
  IF count($items) = 0 THEN { THROW 'ucp_cart_items_required'; };
  LET $policy = fn::select_ucp_commerce_policy($tenant_id, 'default');
  IF $policy.require_ap2_payment_capture THEN { fn::require_ap2_payment_captured($ap2_payment_capture_id); };
  IF $order_payload_hash = NONE OR string::len($order_payload_hash) = 0 THEN { THROW 'ucp_order_payload_hash_required'; };
  LET $first_offer = SELECT * FROM $items[0].offer_id;
  LET $decision_log = fn::log_decision_context($tenant_id, 'ucp_order_placed', string::concat($cart[0].agent_identity_subject_id), $actor_id, NONE, NONE, { order_ref: $order_ref, cart_id: $cart_id, item_count: count($items), total_minor: $cart[0].total_minor, currency: $cart[0].currency }, {}, {}, {}, {}, {}, {}, { ap2_payment_capture_id: $ap2_payment_capture_id, policy_id: $policy.id }, [{ kind: 'cart_must_be_open' }, { kind: 'ap2_payment_capture_required' }, { kind: 'order_payload_hash_required' }], { order_payload_hash: $order_payload_hash, provider_order_ref: $provider_order_ref }, [{ decision: 'place_order' }, { decision: 'block_order' }], { decision: 'place_order' }, [], 'ucp_order_authorized_for_placement', { method: 'agx:ucp-commerce-v1' }, [$cart_id, $ap2_payment_capture_id], NONE, [], false);
  LET $order = CREATE ucp_orders CONTENT { tenant_id: $tenant_id, order_ref: $order_ref, cart_id: $cart_id, ap2_payment_capture_id: $ap2_payment_capture_id, commerce_provider_id: $cart[0].commerce_provider_id, merchant_id: $first_offer[0].merchant_id, status: 'placed', total_minor: $cart[0].total_minor, currency: $cart[0].currency, fulfillment_status: 'pending', order_payload_hash: $order_payload_hash, provider_order_ref: $provider_order_ref, decision_log_id: $decision_log.id, created_at: time::now(), updated_at: time::now() };
  UPDATE $cart_id SET status = 'ordered', updated_at = time::now();
  fn::record_reliability_event($tenant_id, string::concat($cart[0].agent_identity_subject_id), 'ucp_order', 'success', 1, NONE, string::concat($order.id), { order_ref: $order_ref, total_minor: $cart[0].total_minor, currency: $cart[0].currency });
  RETURN $order;
};

DEFINE FUNCTION fn::update_ucp_order_fulfillment($order_id, $fulfillment_status, $metadata) {
  LET $order = SELECT * FROM $order_id;
  IF count($order) = 0 THEN { THROW 'ucp_order_not_found'; };
  UPDATE $order_id SET fulfillment_status = $fulfillment_status, updated_at = time::now();
  RETURN SELECT * FROM $order_id;
};
