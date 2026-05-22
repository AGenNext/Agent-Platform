DEFINE TABLE relationship_authorization_engines SCHEMAFULL;
DEFINE FIELD tenant_id ON relationship_authorization_engines TYPE option<record<tenants>>;
DEFINE FIELD key ON relationship_authorization_engines TYPE string;
DEFINE FIELD name ON relationship_authorization_engines TYPE string;
DEFINE FIELD engine_kind ON relationship_authorization_engines TYPE string DEFAULT 'openfga';
DEFINE FIELD endpoint_uri ON relationship_authorization_engines TYPE option<string>;
DEFINE FIELD store_id ON relationship_authorization_engines TYPE option<string>;
DEFINE FIELD status ON relationship_authorization_engines TYPE string DEFAULT 'active';
DEFINE FIELD standard_ref ON relationship_authorization_engines TYPE string DEFAULT 'https://openfga.dev/';
DEFINE FIELD source_grounding_refs ON relationship_authorization_engines TYPE array<string> DEFAULT ['openfga:relationship-authorization'];
DEFINE FIELD jsonld_context ON relationship_authorization_engines TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON relationship_authorization_engines TYPE array<string> DEFAULT ['schema:SoftwareApplication', 'agx:RelationshipAuthorizationEngine'];
DEFINE FIELD created_at ON relationship_authorization_engines TYPE datetime DEFAULT time::now();
DEFINE INDEX relationship_authorization_engines_key_unique ON relationship_authorization_engines FIELDS tenant_id, key UNIQUE;

DEFINE TABLE relationship_authorization_models SCHEMAFULL;
DEFINE FIELD tenant_id ON relationship_authorization_models TYPE option<record<tenants>>;
DEFINE FIELD engine_id ON relationship_authorization_models TYPE record<relationship_authorization_engines>;
DEFINE FIELD key ON relationship_authorization_models TYPE string;
DEFINE FIELD name ON relationship_authorization_models TYPE string;
DEFINE FIELD model_version ON relationship_authorization_models TYPE string;
DEFINE FIELD model_hash ON relationship_authorization_models TYPE string;
DEFINE FIELD model_dsl ON relationship_authorization_models TYPE string;
DEFINE FIELD model_json ON relationship_authorization_models TYPE object DEFAULT {};
DEFINE FIELD status ON relationship_authorization_models TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON relationship_authorization_models TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON relationship_authorization_models TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:RelationshipAuthorizationModel'];
DEFINE FIELD created_at ON relationship_authorization_models TYPE datetime DEFAULT time::now();
DEFINE INDEX relationship_authorization_models_key_unique ON relationship_authorization_models FIELDS tenant_id, key, model_version UNIQUE;

DEFINE TABLE relationship_tuples SCHEMAFULL;
DEFINE FIELD tenant_id ON relationship_tuples TYPE option<record<tenants>>;
DEFINE FIELD model_id ON relationship_tuples TYPE record<relationship_authorization_models>;
DEFINE FIELD user_ref ON relationship_tuples TYPE string;
DEFINE FIELD relation ON relationship_tuples TYPE string;
DEFINE FIELD object_ref ON relationship_tuples TYPE string;
DEFINE FIELD condition_context ON relationship_tuples TYPE object DEFAULT {};
DEFINE FIELD source_ref ON relationship_tuples TYPE option<record>;
DEFINE FIELD status ON relationship_tuples TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON relationship_tuples TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON relationship_tuples TYPE option<datetime>;
DEFINE FIELD jsonld_context ON relationship_tuples TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON relationship_tuples TYPE array<string> DEFAULT ['schema:Action', 'agx:RelationshipTuple'];
DEFINE INDEX relationship_tuples_unique ON relationship_tuples FIELDS tenant_id, model_id, user_ref, relation, object_ref UNIQUE;

DEFINE TABLE relationship_access_checks SCHEMAFULL;
DEFINE FIELD tenant_id ON relationship_access_checks TYPE option<record<tenants>>;
DEFINE FIELD model_id ON relationship_access_checks TYPE record<relationship_authorization_models>;
DEFINE FIELD user_ref ON relationship_access_checks TYPE string;
DEFINE FIELD relation ON relationship_access_checks TYPE string;
DEFINE FIELD object_ref ON relationship_access_checks TYPE string;
DEFINE FIELD contextual_tuples ON relationship_access_checks TYPE array<object> DEFAULT [];
DEFINE FIELD context ON relationship_access_checks TYPE object DEFAULT {};
DEFINE FIELD allowed ON relationship_access_checks TYPE bool DEFAULT false;
DEFINE FIELD reason ON relationship_access_checks TYPE string;
DEFINE FIELD matching_tuple_ids ON relationship_access_checks TYPE array<record<relationship_tuples>> DEFAULT [];
DEFINE FIELD decision_log_id ON relationship_access_checks TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON relationship_access_checks TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON relationship_access_checks TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON relationship_access_checks TYPE array<string> DEFAULT ['schema:AuthorizeAction', 'agx:RelationshipAccessCheck'];

UPSERT relationship_authorization_engines:openfga_default CONTENT { tenant_id: NONE, key: 'openfga_default', name: 'Default OpenFGA Relationship Authorization Engine', engine_kind: 'openfga', endpoint_uri: NONE, store_id: NONE, status: 'active', standard_ref: 'https://openfga.dev/', source_grounding_refs: ['openfga:relationship-authorization'] };

DEFINE FUNCTION fn::register_relationship_authorization_engine($tenant_id, $key, $name, $endpoint_uri, $store_id) {
  LET $existing = SELECT * FROM relationship_authorization_engines WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE relationship_authorization_engines CONTENT { tenant_id: $tenant_id, key: $key, name: $name, engine_kind: 'openfga', endpoint_uri: $endpoint_uri, store_id: $store_id, status: 'active', standard_ref: 'https://openfga.dev/', source_grounding_refs: ['openfga:relationship-authorization'], created_at: time::now() };
};

DEFINE FUNCTION fn::register_relationship_authorization_model($tenant_id, $engine_id, $key, $name, $model_version, $model_hash, $model_dsl, $model_json) {
  LET $engine = SELECT * FROM $engine_id;
  IF count($engine) = 0 THEN { THROW 'relationship_authorization_engine_not_found'; };
  IF $model_hash = NONE OR string::len($model_hash) = 0 THEN { THROW 'relationship_authorization_model_hash_required'; };
  RETURN CREATE relationship_authorization_models CONTENT { tenant_id: $tenant_id, engine_id: $engine_id, key: $key, name: $name, model_version: $model_version, model_hash: $model_hash, model_dsl: $model_dsl, model_json: $model_json, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::write_relationship_tuple($tenant_id, $model_id, $user_ref, $relation, $object_ref, $condition_context, $source_ref, $expires_at) {
  LET $model = SELECT * FROM $model_id;
  IF count($model) = 0 THEN { THROW 'relationship_authorization_model_not_found'; };
  RETURN CREATE relationship_tuples CONTENT { tenant_id: $tenant_id, model_id: $model_id, user_ref: $user_ref, relation: $relation, object_ref: $object_ref, condition_context: $condition_context, source_ref: $source_ref, status: 'active', created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::check_relationship_access($tenant_id, $model_id, $user_ref, $relation, $object_ref, $contextual_tuples, $context, $actor_id) {
  LET $model = SELECT * FROM $model_id;
  IF count($model) = 0 THEN { THROW 'relationship_authorization_model_not_found'; };
  LET $stored = SELECT * FROM relationship_tuples WHERE tenant_id = $tenant_id AND model_id = $model_id AND user_ref = $user_ref AND relation = $relation AND object_ref = $object_ref AND status = 'active' AND (expires_at = NONE OR expires_at > time::now());
  LET $context_match = count(array::filter($contextual_tuples, |$t| $t.user_ref = $user_ref AND $t.relation = $relation AND $t.object_ref = $object_ref)) > 0;
  LET $allowed = count($stored) > 0 OR $context_match;
  LET $decision_log = fn::log_decision_context($tenant_id, 'openfga_relationship_access_check', $user_ref, $actor_id, NONE, NONE, { user_ref: $user_ref, relation: $relation, object_ref: $object_ref, model_id: $model_id }, {}, {}, {}, {}, {}, {}, { standard_ref: 'https://openfga.dev/', model_hash: $model[0].model_hash }, [{ kind: 'relationship_tuple_required' }, { kind: 'model_version', value: $model[0].model_version }], { stored_tuple_count: count($stored), context_match: $context_match }, [{ decision: 'allow' }, { decision: 'deny' }], { decision: IF $allowed THEN 'allow' ELSE 'deny' END }, [], 'openfga_relationship_access_checked', { allowed: $allowed, matching_tuple_ids: $stored[*].id }, $stored[*].id, NONE, [], false);
  RETURN CREATE relationship_access_checks CONTENT { tenant_id: $tenant_id, model_id: $model_id, user_ref: $user_ref, relation: $relation, object_ref: $object_ref, contextual_tuples: $contextual_tuples, context: $context, allowed: $allowed, reason: IF $allowed THEN 'relationship_tuple_matched' ELSE 'relationship_tuple_not_found' END, matching_tuple_ids: $stored[*].id, decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::require_relationship_access_allowed($relationship_access_check_id) {
  LET $check = SELECT * FROM $relationship_access_check_id;
  IF count($check) = 0 THEN { THROW 'relationship_access_check_required'; };
  IF !$check[0].allowed THEN { THROW 'relationship_access_denied'; };
  RETURN true;
};
