DEFINE TABLE mcp_protocol_standards SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_protocol_standards TYPE option<record<tenants>>;
DEFINE FIELD key ON mcp_protocol_standards TYPE string;
DEFINE FIELD name ON mcp_protocol_standards TYPE string;
DEFINE FIELD standard_uri ON mcp_protocol_standards TYPE string;
DEFINE FIELD standard_version ON mcp_protocol_standards TYPE string DEFAULT 'latest';
DEFINE FIELD status ON mcp_protocol_standards TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON mcp_protocol_standards TYPE array<string> DEFAULT ['modelcontextprotocol:specification'];
DEFINE FIELD jsonld_context ON mcp_protocol_standards TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON mcp_protocol_standards TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:MCPProtocolStandard'];
DEFINE FIELD created_at ON mcp_protocol_standards TYPE datetime DEFAULT time::now();
DEFINE INDEX mcp_protocol_standards_key_unique ON mcp_protocol_standards FIELDS tenant_id, key, standard_version UNIQUE;

DEFINE TABLE mcp_servers SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_servers TYPE option<record<tenants>>;
DEFINE FIELD key ON mcp_servers TYPE string;
DEFINE FIELD name ON mcp_servers TYPE string;
DEFINE FIELD description ON mcp_servers TYPE string;
DEFINE FIELD server_kind ON mcp_servers TYPE string DEFAULT 'remote';
DEFINE FIELD endpoint_uri ON mcp_servers TYPE option<string>;
DEFINE FIELD transport ON mcp_servers TYPE string DEFAULT 'streamable_http';
DEFINE FIELD protocol_version ON mcp_servers TYPE string DEFAULT 'latest';
DEFINE FIELD authentication ON mcp_servers TYPE object DEFAULT {};
DEFINE FIELD authorization_policy ON mcp_servers TYPE object DEFAULT { require_access_evaluation: true, require_policy_allow: true, require_relationship_access: true };
DEFINE FIELD health_status ON mcp_servers TYPE string DEFAULT 'unknown';
DEFINE FIELD status ON mcp_servers TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON mcp_servers TYPE array<string> DEFAULT ['modelcontextprotocol:specification'];
DEFINE FIELD jsonld_context ON mcp_servers TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON mcp_servers TYPE array<string> DEFAULT ['schema:WebAPI', 'agx:MCPServer'];
DEFINE FIELD created_at ON mcp_servers TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON mcp_servers TYPE datetime DEFAULT time::now();
DEFINE INDEX mcp_servers_key_unique ON mcp_servers FIELDS tenant_id, key UNIQUE;

DEFINE TABLE mcp_capability_manifests SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_capability_manifests TYPE option<record<tenants>>;
DEFINE FIELD mcp_server_id ON mcp_capability_manifests TYPE record<mcp_servers>;
DEFINE FIELD manifest_ref ON mcp_capability_manifests TYPE string;
DEFINE FIELD protocol_version ON mcp_capability_manifests TYPE string DEFAULT 'latest';
DEFINE FIELD server_info ON mcp_capability_manifests TYPE object DEFAULT {};
DEFINE FIELD capabilities ON mcp_capability_manifests TYPE object DEFAULT {};
DEFINE FIELD tools ON mcp_capability_manifests TYPE array<object> DEFAULT [];
DEFINE FIELD resources ON mcp_capability_manifests TYPE array<object> DEFAULT [];
DEFINE FIELD prompts ON mcp_capability_manifests TYPE array<object> DEFAULT [];
DEFINE FIELD manifest_hash ON mcp_capability_manifests TYPE string;
DEFINE FIELD status ON mcp_capability_manifests TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON mcp_capability_manifests TYPE datetime DEFAULT time::now();
DEFINE INDEX mcp_capability_manifests_ref_unique ON mcp_capability_manifests FIELDS tenant_id, manifest_ref UNIQUE;

DEFINE TABLE mcp_tool_registrations SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_tool_registrations TYPE option<record<tenants>>;
DEFINE FIELD mcp_server_id ON mcp_tool_registrations TYPE record<mcp_servers>;
DEFINE FIELD manifest_id ON mcp_tool_registrations TYPE option<record<mcp_capability_manifests>>;
DEFINE FIELD tool_name ON mcp_tool_registrations TYPE string;
DEFINE FIELD description ON mcp_tool_registrations TYPE string;
DEFINE FIELD input_schema ON mcp_tool_registrations TYPE object DEFAULT {};
DEFINE FIELD output_schema ON mcp_tool_registrations TYPE object DEFAULT {};
DEFINE FIELD risk_level ON mcp_tool_registrations TYPE string DEFAULT 'medium';
DEFINE FIELD required_scopes ON mcp_tool_registrations TYPE array<string> DEFAULT [];
DEFINE FIELD required_relationship ON mcp_tool_registrations TYPE option<string>;
DEFINE FIELD status ON mcp_tool_registrations TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON mcp_tool_registrations TYPE datetime DEFAULT time::now();
DEFINE INDEX mcp_tool_registrations_unique ON mcp_tool_registrations FIELDS tenant_id, mcp_server_id, tool_name UNIQUE;

DEFINE TABLE mcp_resource_registrations SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_resource_registrations TYPE option<record<tenants>>;
DEFINE FIELD mcp_server_id ON mcp_resource_registrations TYPE record<mcp_servers>;
DEFINE FIELD manifest_id ON mcp_resource_registrations TYPE option<record<mcp_capability_manifests>>;
DEFINE FIELD resource_uri ON mcp_resource_registrations TYPE string;
DEFINE FIELD name ON mcp_resource_registrations TYPE string;
DEFINE FIELD description ON mcp_resource_registrations TYPE string;
DEFINE FIELD mime_type ON mcp_resource_registrations TYPE option<string>;
DEFINE FIELD annotations ON mcp_resource_registrations TYPE object DEFAULT {};
DEFINE FIELD required_scopes ON mcp_resource_registrations TYPE array<string> DEFAULT [];
DEFINE FIELD data_classification ON mcp_resource_registrations TYPE string DEFAULT 'internal';
DEFINE FIELD status ON mcp_resource_registrations TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON mcp_resource_registrations TYPE datetime DEFAULT time::now();
DEFINE INDEX mcp_resource_registrations_unique ON mcp_resource_registrations FIELDS tenant_id, mcp_server_id, resource_uri UNIQUE;

DEFINE TABLE mcp_prompt_registrations SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_prompt_registrations TYPE option<record<tenants>>;
DEFINE FIELD mcp_server_id ON mcp_prompt_registrations TYPE record<mcp_servers>;
DEFINE FIELD manifest_id ON mcp_prompt_registrations TYPE option<record<mcp_capability_manifests>>;
DEFINE FIELD prompt_name ON mcp_prompt_registrations TYPE string;
DEFINE FIELD description ON mcp_prompt_registrations TYPE string;
DEFINE FIELD arguments_schema ON mcp_prompt_registrations TYPE object DEFAULT {};
DEFINE FIELD risk_level ON mcp_prompt_registrations TYPE string DEFAULT 'medium';
DEFINE FIELD status ON mcp_prompt_registrations TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON mcp_prompt_registrations TYPE datetime DEFAULT time::now();
DEFINE INDEX mcp_prompt_registrations_unique ON mcp_prompt_registrations FIELDS tenant_id, mcp_server_id, prompt_name UNIQUE;

DEFINE TABLE mcp_sessions SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_sessions TYPE option<record<tenants>>;
DEFINE FIELD session_ref ON mcp_sessions TYPE string;
DEFINE FIELD mcp_server_id ON mcp_sessions TYPE record<mcp_servers>;
DEFINE FIELD agent_identity_subject_id ON mcp_sessions TYPE record<agent_identity_subjects>;
DEFINE FIELD agent_id ON mcp_sessions TYPE option<record<agents>>;
DEFINE FIELD protocol_version ON mcp_sessions TYPE string DEFAULT 'latest';
DEFINE FIELD client_info ON mcp_sessions TYPE object DEFAULT {};
DEFINE FIELD negotiated_capabilities ON mcp_sessions TYPE object DEFAULT {};
DEFINE FIELD authorization_decision_id ON mcp_sessions TYPE option<record<authorization_access_evaluation_decisions>>;
DEFINE FIELD policy_decision_result_id ON mcp_sessions TYPE option<record<policy_decision_results>>;
DEFINE FIELD relationship_access_check_id ON mcp_sessions TYPE option<record<relationship_access_checks>>;
DEFINE FIELD trace_id ON mcp_sessions TYPE option<string>;
DEFINE FIELD status ON mcp_sessions TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON mcp_sessions TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON mcp_sessions TYPE option<datetime>;
DEFINE INDEX mcp_sessions_ref_unique ON mcp_sessions FIELDS tenant_id, session_ref UNIQUE;

DEFINE TABLE mcp_invocations SCHEMAFULL;
DEFINE FIELD tenant_id ON mcp_invocations TYPE option<record<tenants>>;
DEFINE FIELD invocation_ref ON mcp_invocations TYPE string;
DEFINE FIELD mcp_session_id ON mcp_invocations TYPE record<mcp_sessions>;
DEFINE FIELD invocation_kind ON mcp_invocations TYPE string;
DEFINE FIELD target_name ON mcp_invocations TYPE string;
DEFINE FIELD request_payload_hash ON mcp_invocations TYPE string;
DEFINE FIELD request_payload ON mcp_invocations TYPE object DEFAULT {};
DEFINE FIELD response_payload_hash ON mcp_invocations TYPE option<string>;
DEFINE FIELD response_payload ON mcp_invocations TYPE object DEFAULT {};
DEFINE FIELD status ON mcp_invocations TYPE string DEFAULT 'started';
DEFINE FIELD authorization_decision_id ON mcp_invocations TYPE option<record<authorization_access_evaluation_decisions>>;
DEFINE FIELD policy_decision_result_id ON mcp_invocations TYPE option<record<policy_decision_results>>;
DEFINE FIELD relationship_access_check_id ON mcp_invocations TYPE option<record<relationship_access_checks>>;
DEFINE FIELD trace_id ON mcp_invocations TYPE option<string>;
DEFINE FIELD span_id ON mcp_invocations TYPE option<string>;
DEFINE FIELD error ON mcp_invocations TYPE option<object>;
DEFINE FIELD started_at ON mcp_invocations TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON mcp_invocations TYPE option<datetime>;
DEFINE INDEX mcp_invocations_ref_unique ON mcp_invocations FIELDS tenant_id, invocation_ref UNIQUE;

UPSERT mcp_protocol_standards:mcp_latest CONTENT { tenant_id: NONE, key: 'mcp', name: 'Model Context Protocol', standard_uri: 'https://modelcontextprotocol.io/', standard_version: 'latest', status: 'active', source_grounding_refs: ['modelcontextprotocol:specification'] };

DEFINE FUNCTION fn::register_mcp_server($tenant_id, $key, $name, $description, $server_kind, $endpoint_uri, $transport, $protocol_version, $authentication, $authorization_policy) {
  LET $existing = SELECT * FROM mcp_servers WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE mcp_servers CONTENT { tenant_id: $tenant_id, key: $key, name: $name, description: $description, server_kind: $server_kind, endpoint_uri: $endpoint_uri, transport: $transport, protocol_version: $protocol_version, authentication: $authentication, authorization_policy: $authorization_policy, health_status: 'unknown', status: 'active', source_grounding_refs: ['modelcontextprotocol:specification'], created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::record_mcp_capability_manifest($tenant_id, $mcp_server_id, $manifest_ref, $protocol_version, $server_info, $capabilities, $tools, $resources, $prompts, $manifest_hash) {
  LET $server = SELECT * FROM $mcp_server_id;
  IF count($server) = 0 THEN { THROW 'mcp_server_not_found'; };
  IF $manifest_hash = NONE OR string::len($manifest_hash) = 0 THEN { THROW 'mcp_manifest_hash_required'; };
  LET $manifest = CREATE mcp_capability_manifests CONTENT { tenant_id: $tenant_id, mcp_server_id: $mcp_server_id, manifest_ref: $manifest_ref, protocol_version: $protocol_version, server_info: $server_info, capabilities: $capabilities, tools: $tools, resources: $resources, prompts: $prompts, manifest_hash: $manifest_hash, status: 'active', created_at: time::now() };
  FOR $tool IN $tools { CREATE mcp_tool_registrations CONTENT { tenant_id: $tenant_id, mcp_server_id: $mcp_server_id, manifest_id: $manifest.id, tool_name: $tool.name, description: $tool.description ?? '', input_schema: $tool.inputSchema ?? {}, output_schema: $tool.outputSchema ?? {}, risk_level: $tool.risk_level ?? 'medium', required_scopes: $tool.required_scopes ?? [], required_relationship: $tool.required_relationship ?? NONE, status: 'active', created_at: time::now() }; };
  FOR $resource IN $resources { CREATE mcp_resource_registrations CONTENT { tenant_id: $tenant_id, mcp_server_id: $mcp_server_id, manifest_id: $manifest.id, resource_uri: $resource.uri, name: $resource.name ?? $resource.uri, description: $resource.description ?? '', mime_type: $resource.mimeType ?? NONE, annotations: $resource.annotations ?? {}, required_scopes: $resource.required_scopes ?? [], data_classification: $resource.data_classification ?? 'internal', status: 'active', created_at: time::now() }; };
  FOR $prompt IN $prompts { CREATE mcp_prompt_registrations CONTENT { tenant_id: $tenant_id, mcp_server_id: $mcp_server_id, manifest_id: $manifest.id, prompt_name: $prompt.name, description: $prompt.description ?? '', arguments_schema: $prompt.arguments ?? {}, risk_level: $prompt.risk_level ?? 'medium', status: 'active', created_at: time::now() }; };
  RETURN $manifest;
};

DEFINE FUNCTION fn::start_mcp_session($tenant_id, $session_ref, $mcp_server_id, $agent_identity_subject_id, $agent_id, $protocol_version, $client_info, $negotiated_capabilities, $authorization_decision_id, $policy_decision_result_id, $relationship_access_check_id, $trace_id, $expires_at) {
  LET $server = SELECT * FROM $mcp_server_id;
  IF count($server) = 0 THEN { THROW 'mcp_server_not_found'; };
  LET $subject = SELECT * FROM $agent_identity_subject_id;
  IF count($subject) = 0 THEN { THROW 'agent_identity_subject_not_found'; };
  LET $authz = $server[0].authorization_policy;
  IF $authz.require_access_evaluation THEN { fn::require_access_evaluation_allowed($authorization_decision_id); };
  IF $authz.require_policy_allow THEN { fn::require_policy_allowed($policy_decision_result_id); };
  IF $authz.require_relationship_access THEN { fn::require_relationship_access_allowed($relationship_access_check_id); };
  RETURN CREATE mcp_sessions CONTENT { tenant_id: $tenant_id, session_ref: $session_ref, mcp_server_id: $mcp_server_id, agent_identity_subject_id: $agent_identity_subject_id, agent_id: $agent_id, protocol_version: $protocol_version, client_info: $client_info, negotiated_capabilities: $negotiated_capabilities, authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id, trace_id: $trace_id, status: 'active', created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::start_mcp_invocation($tenant_id, $invocation_ref, $mcp_session_id, $invocation_kind, $target_name, $request_payload_hash, $request_payload, $authorization_decision_id, $policy_decision_result_id, $relationship_access_check_id, $span_id) {
  LET $session = SELECT * FROM $mcp_session_id;
  IF count($session) = 0 THEN { THROW 'mcp_session_not_found'; };
  IF $session[0].status != 'active' THEN { THROW 'mcp_session_not_active'; };
  IF $session[0].expires_at != NONE AND $session[0].expires_at <= time::now() THEN { THROW 'mcp_session_expired'; };
  IF $request_payload_hash = NONE OR string::len($request_payload_hash) = 0 THEN { THROW 'mcp_request_payload_hash_required'; };
  LET $server = SELECT * FROM $session[0].mcp_server_id;
  LET $authz = $server[0].authorization_policy;
  IF $authz.require_access_evaluation THEN { fn::require_access_evaluation_allowed($authorization_decision_id); };
  IF $authz.require_policy_allow THEN { fn::require_policy_allowed($policy_decision_result_id); };
  IF $authz.require_relationship_access THEN { fn::require_relationship_access_allowed($relationship_access_check_id); };
  LET $invocation = CREATE mcp_invocations CONTENT { tenant_id: $tenant_id, invocation_ref: $invocation_ref, mcp_session_id: $mcp_session_id, invocation_kind: $invocation_kind, target_name: $target_name, request_payload_hash: $request_payload_hash, request_payload: $request_payload, status: 'started', authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id, trace_id: $session[0].trace_id, span_id: $span_id, started_at: time::now() };
  IF $session[0].trace_id != NONE AND $span_id != NONE THEN { fn::start_trace_span($tenant_id, $session[0].trace_id, $span_id, NONE, 'mcp_invocation', string::concat($invocation_kind, ':', $target_name), { invocation_id: $invocation.id, target_name: $target_name }); };
  RETURN $invocation;
};

DEFINE FUNCTION fn::finish_mcp_invocation($mcp_invocation_id, $status, $response_payload_hash, $response_payload, $error) {
  LET $inv = SELECT * FROM $mcp_invocation_id;
  IF count($inv) = 0 THEN { THROW 'mcp_invocation_not_found'; };
  UPDATE $mcp_invocation_id SET status = $status, response_payload_hash = $response_payload_hash, response_payload = $response_payload, error = $error, completed_at = time::now();
  IF $inv[0].trace_id != NONE AND $inv[0].span_id != NONE THEN { fn::finish_trace_span($inv[0].tenant_id, $inv[0].trace_id, $inv[0].span_id, $status, { response_payload_hash: $response_payload_hash }, $error); };
  fn::record_usage_event($inv[0].tenant_id, rand::uuid(), string::concat($inv[0].mcp_session_id), NONE, NONE, 'mcp_invocation', string::concat($inv[0].invocation_kind, ':', $inv[0].target_name), 1, 0, 'USD', $inv[0].trace_id, { status: $status });
  RETURN SELECT * FROM $mcp_invocation_id;
};

DEFINE FUNCTION fn::record_mcp_health_check($tenant_id, $mcp_server_id, $status, $latency_ms, $details) {
  LET $server = SELECT * FROM $mcp_server_id;
  IF count($server) = 0 THEN { THROW 'mcp_server_not_found'; };
  UPDATE $mcp_server_id SET health_status = $status, updated_at = time::now();
  RETURN fn::record_health_check($tenant_id, rand::uuid(), string::concat('mcp_server:', $server[0].key), $status, $latency_ms, $details);
};

DEFINE FUNCTION fn::require_mcp_invocation_succeeded($mcp_invocation_id) {
  LET $inv = SELECT * FROM $mcp_invocation_id;
  IF count($inv) = 0 THEN { THROW 'mcp_invocation_required'; };
  IF $inv[0].status NOT IN ['completed', 'success'] THEN { THROW 'mcp_invocation_not_successful'; };
  RETURN true;
};
