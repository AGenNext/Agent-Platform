-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Protocol Schema
-- ============================================================

-- Purpose:
-- Protocol defines interoperable communication and execution contracts.
-- It covers MCP, A2A, AuthZEN, OpenFGA, SCIM, OIDC, SAML, DID/VC,
-- AP2, UCP, HTTP, gRPC, Webhook, Email, Slack, GitHub, and internal
-- platform protocols. Actions, workflows, tools, agents, services, and
-- registries can declare protocol conformance through this model.

DEFINE TABLE protocol SCHEMAFULL;

DEFINE FIELD entity ON protocol TYPE record<entity>;
DEFINE FIELD owner ON protocol TYPE option<record<identity>>;
DEFINE FIELD protocol_type ON protocol TYPE string
  ASSERT $value IN [
    "mcp",
    "a2a",
    "authzen",
    "openfga",
    "opa",
    "scim",
    "oidc",
    "saml",
    "did",
    "verifiable_credential",
    "ap2",
    "ucp",
    "http",
    "grpc",
    "websocket",
    "webhook",
    "email",
    "slack",
    "github",
    "git",
    "bpmn",
    "dmn",
    "langgraph",
    "internal"
  ];

DEFINE FIELD name ON protocol TYPE string;
DEFINE FIELD description ON protocol TYPE option<string>;
DEFINE FIELD status ON protocol TYPE string DEFAULT "draft"
  ASSERT $value IN ["draft", "active", "inactive", "deprecated", "archived"];

DEFINE FIELD version ON protocol TYPE string DEFAULT "0.1.0";
DEFINE FIELD external_ref ON protocol TYPE option<string>;
DEFINE FIELD transport ON protocol TYPE option<string>;
DEFINE FIELD message_types ON protocol TYPE array<object> DEFAULT [];
DEFINE FIELD operations ON protocol TYPE array<object> DEFAULT [];
DEFINE FIELD capabilities ON protocol TYPE array<string> DEFAULT [];
DEFINE FIELD authentication ON protocol TYPE option<object>;
DEFINE FIELD authorization ON protocol TYPE option<object>;
DEFINE FIELD verification ON protocol TYPE option<object>;
DEFINE FIELD schemas ON protocol TYPE array<record<schema_definition>> DEFAULT [];
DEFINE FIELD compliance_refs ON protocol TYPE array<record<governance_object>> DEFAULT [];
DEFINE FIELD examples ON protocol TYPE array<object> DEFAULT [];

DEFINE FIELD created_at ON protocol TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON protocol TYPE datetime VALUE time::now();
DEFINE FIELD valid_from ON protocol TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON protocol TYPE option<datetime>;
DEFINE FIELD metadata ON protocol TYPE option<object>;

DEFINE INDEX protocol_entity_idx ON protocol FIELDS entity UNIQUE;
DEFINE INDEX protocol_type_idx ON protocol FIELDS protocol_type;
DEFINE INDEX protocol_status_idx ON protocol FIELDS status;
DEFINE INDEX protocol_name_idx ON protocol FIELDS name SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Protocol Binding
-- ------------------------------------------------------------

DEFINE TABLE protocol_binding SCHEMAFULL;

DEFINE FIELD protocol ON protocol_binding TYPE record<protocol>;
DEFINE FIELD subject ON protocol_binding TYPE record<entity>;
DEFINE FIELD binding_type ON protocol_binding TYPE string
  ASSERT $value IN [
    "agent_supports_protocol",
    "tool_supports_protocol",
    "workflow_uses_protocol",
    "action_uses_protocol",
    "service_exposes_protocol",
    "registry_uses_protocol",
    "environment_allows_protocol",
    "credential_uses_protocol",
    "artifact_conforms_to_protocol"
  ];

DEFINE FIELD status ON protocol_binding TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "pending", "failed", "deprecated", "archived"];

DEFINE FIELD endpoint ON protocol_binding TYPE option<string>;
DEFINE FIELD config ON protocol_binding TYPE object DEFAULT {};
DEFINE FIELD credential_refs ON protocol_binding TYPE array<record<credential>> DEFAULT [];
DEFINE FIELD capabilities ON protocol_binding TYPE array<string> DEFAULT [];
DEFINE FIELD conformance_result ON protocol_binding TYPE option<record<validation_result>>;
DEFINE FIELD trust_assessment ON protocol_binding TYPE option<record<trust_assessment>>;
DEFINE FIELD created_at ON protocol_binding TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON protocol_binding TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON protocol_binding TYPE option<object>;

DEFINE INDEX protocol_binding_protocol_idx ON protocol_binding FIELDS protocol;
DEFINE INDEX protocol_binding_subject_idx ON protocol_binding FIELDS subject;
DEFINE INDEX protocol_binding_type_idx ON protocol_binding FIELDS binding_type;
DEFINE INDEX protocol_binding_status_idx ON protocol_binding FIELDS status;

-- ------------------------------------------------------------
-- Protocol Message
-- ------------------------------------------------------------

DEFINE TABLE protocol_message SCHEMAFULL;

DEFINE FIELD protocol ON protocol_message TYPE record<protocol>;
DEFINE FIELD binding ON protocol_message TYPE option<record<protocol_binding>>;
DEFINE FIELD sender ON protocol_message TYPE option<record<identity>>;
DEFINE FIELD receiver ON protocol_message TYPE option<record<identity>>;
DEFINE FIELD message_type ON protocol_message TYPE string;
DEFINE FIELD direction ON protocol_message TYPE string DEFAULT "outbound" ASSERT $value IN ["inbound", "outbound", "internal"];
DEFINE FIELD status ON protocol_message TYPE string DEFAULT "created"
  ASSERT $value IN ["created", "sent", "received", "processed", "failed", "rejected", "archived"];

DEFINE FIELD payload ON protocol_message TYPE object DEFAULT {};
DEFINE FIELD headers ON protocol_message TYPE object DEFAULT {};
DEFINE FIELD correlation_id ON protocol_message TYPE option<string>;
DEFINE FIELD idempotency_key ON protocol_message TYPE option<string>;
DEFINE FIELD evidence ON protocol_message TYPE option<object>;
DEFINE FIELD error ON protocol_message TYPE option<object>;
DEFINE FIELD created_at ON protocol_message TYPE datetime DEFAULT time::now();
DEFINE FIELD processed_at ON protocol_message TYPE option<datetime>;
DEFINE FIELD metadata ON protocol_message TYPE option<object>;

DEFINE INDEX protocol_message_protocol_idx ON protocol_message FIELDS protocol;
DEFINE INDEX protocol_message_binding_idx ON protocol_message FIELDS binding;
DEFINE INDEX protocol_message_type_idx ON protocol_message FIELDS message_type;
DEFINE INDEX protocol_message_status_idx ON protocol_message FIELDS status;
DEFINE INDEX protocol_message_correlation_idx ON protocol_message FIELDS correlation_id;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::bind_protocol(
  $protocol: record<protocol>,
  $subject: record<entity>,
  $binding_type: string,
  $endpoint: option<string>,
  $config: object,
  $capabilities: array<string>
) {
  RETURN CREATE protocol_binding SET
    protocol = $protocol,
    subject = $subject,
    binding_type = $binding_type,
    endpoint = $endpoint,
    config = $config,
    capabilities = $capabilities,
    status = "active";
};

DEFINE FUNCTION fn::record_protocol_message(
  $protocol: record<protocol>,
  $binding: option<record<protocol_binding>>,
  $sender: option<record<identity>>,
  $receiver: option<record<identity>>,
  $message_type: string,
  $direction: string,
  $payload: object,
  $correlation_id: option<string>
) {
  RETURN CREATE protocol_message SET
    protocol = $protocol,
    binding = $binding,
    sender = $sender,
    receiver = $receiver,
    message_type = $message_type,
    direction = $direction,
    payload = $payload,
    correlation_id = $correlation_id,
    status = "created";
};

DEFINE FUNCTION fn::protocol_binding_is_usable($binding: record<protocol_binding>) {
  LET $b = SELECT * FROM ONLY $binding;
  RETURN $b.status = "active";
};

DEFINE FUNCTION fn::protocol_is_active($protocol: record<protocol>) {
  LET $p = SELECT * FROM ONLY $protocol;
  RETURN $p.status = "active"
    AND ($p.valid_to = NONE OR $p.valid_to > time::now());
};
