DEFINE TABLE policy_engines SCHEMAFULL;
DEFINE FIELD tenant_id ON policy_engines TYPE option<record<tenants>>;
DEFINE FIELD key ON policy_engines TYPE string;
DEFINE FIELD name ON policy_engines TYPE string;
DEFINE FIELD engine_kind ON policy_engines TYPE string DEFAULT 'open_policy_agent';
DEFINE FIELD endpoint_uri ON policy_engines TYPE option<string>;
DEFINE FIELD bundle_uri ON policy_engines TYPE option<string>;
DEFINE FIELD status ON policy_engines TYPE string DEFAULT 'active';
DEFINE FIELD standard_ref ON policy_engines TYPE string DEFAULT 'https://www.openpolicyagent.org/';
DEFINE FIELD source_grounding_refs ON policy_engines TYPE array<string> DEFAULT ['opa:open-policy-agent'];
DEFINE FIELD jsonld_context ON policy_engines TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON policy_engines TYPE array<string> DEFAULT ['schema:SoftwareApplication', 'agx:PolicyEngine'];
DEFINE FIELD created_at ON policy_engines TYPE datetime DEFAULT time::now();
DEFINE INDEX policy_engines_key_unique ON policy_engines FIELDS tenant_id, key UNIQUE;

DEFINE TABLE policy_bundles SCHEMAFULL;
DEFINE FIELD tenant_id ON policy_bundles TYPE option<record<tenants>>;
DEFINE FIELD policy_engine_id ON policy_bundles TYPE record<policy_engines>;
DEFINE FIELD key ON policy_bundles TYPE string;
DEFINE FIELD name ON policy_bundles TYPE string;
DEFINE FIELD bundle_version ON policy_bundles TYPE string;
DEFINE FIELD bundle_hash ON policy_bundles TYPE string;
DEFINE FIELD bundle_uri ON policy_bundles TYPE option<string>;
DEFINE FIELD rego_modules ON policy_bundles TYPE array<object> DEFAULT [];
DEFINE FIELD status ON policy_bundles TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON policy_bundles TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON policy_bundles TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:PolicyBundle'];
DEFINE FIELD created_at ON policy_bundles TYPE datetime DEFAULT time::now();
DEFINE INDEX policy_bundles_key_unique ON policy_bundles FIELDS tenant_id, key, bundle_version UNIQUE;

DEFINE TABLE policy_decision_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON policy_decision_requests TYPE option<record<tenants>>;
DEFINE FIELD policy_engine_id ON policy_decision_requests TYPE record<policy_engines>;
DEFINE FIELD policy_bundle_id ON policy_decision_requests TYPE option<record<policy_bundles>>;
DEFINE FIELD subject_id ON policy_decision_requests TYPE string;
DEFINE FIELD input ON policy_decision_requests TYPE object DEFAULT {};
DEFINE FIELD query_path ON policy_decision_requests TYPE string DEFAULT 'data.agx.authz.allow';
DEFINE FIELD input_hash ON policy_decision_requests TYPE string;
DEFINE FIELD status ON policy_decision_requests TYPE string DEFAULT 'pending';
DEFINE FIELD created_at ON policy_decision_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON policy_decision_requests TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON policy_decision_requests TYPE array<string> DEFAULT ['schema:Action', 'agx:PolicyDecisionRequest'];

DEFINE TABLE policy_decision_results SCHEMAFULL;
DEFINE FIELD tenant_id ON policy_decision_results TYPE option<record<tenants>>;
DEFINE FIELD policy_decision_request_id ON policy_decision_results TYPE record<policy_decision_requests>;
DEFINE FIELD decision ON policy_decision_results TYPE string;
DEFINE FIELD allowed ON policy_decision_results TYPE bool DEFAULT false;
DEFINE FIELD result ON policy_decision_results TYPE object DEFAULT {};
DEFINE FIELD obligations ON policy_decision_results TYPE array<object> DEFAULT [];
DEFINE FIELD reasons ON policy_decision_results TYPE array<string> DEFAULT [];
DEFINE FIELD decision_id ON policy_decision_results TYPE option<string>;
DEFINE FIELD decision_log_id ON policy_decision_results TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON policy_decision_results TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON policy_decision_results TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON policy_decision_results TYPE array<string> DEFAULT ['schema:Action', 'agx:PolicyDecisionResult'];

UPSERT policy_engines:opa_default CONTENT { tenant_id: NONE, key: 'opa_default', name: 'Default Open Policy Agent Engine', engine_kind: 'open_policy_agent', endpoint_uri: NONE, bundle_uri: NONE, status: 'active', standard_ref: 'https://www.openpolicyagent.org/', source_grounding_refs: ['opa:open-policy-agent'] };

DEFINE FUNCTION fn::register_policy_engine($tenant_id, $key, $name, $engine_kind, $endpoint_uri, $bundle_uri) {
  LET $existing = SELECT * FROM policy_engines WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE policy_engines CONTENT { tenant_id: $tenant_id, key: $key, name: $name, engine_kind: $engine_kind, endpoint_uri: $endpoint_uri, bundle_uri: $bundle_uri, status: 'active', standard_ref: 'https://www.openpolicyagent.org/', source_grounding_refs: ['opa:open-policy-agent'], created_at: time::now() };
};

DEFINE FUNCTION fn::register_policy_bundle($tenant_id, $policy_engine_id, $key, $name, $bundle_version, $bundle_hash, $bundle_uri, $rego_modules) {
  LET $engine = SELECT * FROM $policy_engine_id;
  IF count($engine) = 0 THEN { THROW 'policy_engine_not_found'; };
  IF $bundle_hash = NONE OR string::len($bundle_hash) = 0 THEN { THROW 'policy_bundle_hash_required'; };
  RETURN CREATE policy_bundles CONTENT { tenant_id: $tenant_id, policy_engine_id: $policy_engine_id, key: $key, name: $name, bundle_version: $bundle_version, bundle_hash: $bundle_hash, bundle_uri: $bundle_uri, rego_modules: $rego_modules, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::create_policy_decision_request($tenant_id, $policy_engine_id, $policy_bundle_id, $subject_id, $input, $query_path, $input_hash) {
  LET $engine = SELECT * FROM $policy_engine_id;
  IF count($engine) = 0 THEN { THROW 'policy_engine_not_found'; };
  IF $input_hash = NONE OR string::len($input_hash) = 0 THEN { THROW 'policy_decision_input_hash_required'; };
  RETURN CREATE policy_decision_requests CONTENT { tenant_id: $tenant_id, policy_engine_id: $policy_engine_id, policy_bundle_id: $policy_bundle_id, subject_id: $subject_id, input: $input, query_path: $query_path, input_hash: $input_hash, status: 'pending', created_at: time::now() };
};

DEFINE FUNCTION fn::record_policy_decision_result($tenant_id, $policy_decision_request_id, $decision, $allowed, $result, $obligations, $reasons, $external_decision_id, $actor_id) {
  LET $request = SELECT * FROM $policy_decision_request_id;
  IF count($request) = 0 THEN { THROW 'policy_decision_request_not_found'; };
  LET $decision_log = fn::log_decision_context($tenant_id, 'opa_policy_decision', $request[0].subject_id, $actor_id, NONE, NONE, { policy_decision_request_id: $policy_decision_request_id, query_path: $request[0].query_path, input_hash: $request[0].input_hash }, {}, {}, {}, {}, {}, {}, { policy_engine_id: $request[0].policy_engine_id, policy_bundle_id: $request[0].policy_bundle_id, standard_ref: 'https://www.openpolicyagent.org/' }, [{ kind: 'policy_as_code_required' }, { kind: 'opa_decision_required' }], { allowed: $allowed, decision: $decision, obligations: $obligations, reasons: $reasons }, [{ decision: 'allow' }, { decision: 'deny' }], { decision: $decision, allowed: $allowed }, [], 'opa_policy_decision_recorded', { external_decision_id: $external_decision_id, result: $result }, [$policy_decision_request_id], NONE, [], false);
  LET $record = CREATE policy_decision_results CONTENT { tenant_id: $tenant_id, policy_decision_request_id: $policy_decision_request_id, decision: $decision, allowed: $allowed, result: $result, obligations: $obligations, reasons: $reasons, decision_id: $external_decision_id, decision_log_id: $decision_log.id, created_at: time::now() };
  UPDATE $policy_decision_request_id SET status = 'completed';
  RETURN $record;
};

DEFINE FUNCTION fn::evaluate_internal_opa_fallback($tenant_id, $subject_id, $resource_type, $resource_id, $action, $scopes, $required_scope, $risk_level, $actor_id) {
  LET $engine = policy_engines:opa_default;
  LET $input = { subject_id: $subject_id, resource_type: $resource_type, resource_id: $resource_id, action: $action, scopes: $scopes, required_scope: $required_scope, risk_level: $risk_level };
  LET $request = fn::create_policy_decision_request($tenant_id, $engine, NONE, $subject_id, $input, 'data.agx.authz.allow', rand::uuid());
  LET $scope_pass = $required_scope INSIDE $scopes;
  LET $risk_pass = $risk_level NOT IN ['critical_blocked', 'prohibited'];
  LET $allowed = $scope_pass AND $risk_pass;
  RETURN fn::record_policy_decision_result($tenant_id, $request.id, IF $allowed THEN 'allow' ELSE 'deny' END, $allowed, { scope_pass: $scope_pass, risk_pass: $risk_pass }, IF $allowed THEN [{ kind: 'audit_log_required' }] ELSE [] END, IF $allowed THEN [] ELSE ['scope_or_risk_policy_failed'] END, NONE, $actor_id);
};

DEFINE FUNCTION fn::require_policy_allowed($policy_decision_result_id) {
  LET $result = SELECT * FROM $policy_decision_result_id;
  IF count($result) = 0 THEN { THROW 'policy_decision_result_required'; };
  IF !$result[0].allowed THEN { THROW 'policy_decision_denied'; };
  RETURN true;
};
