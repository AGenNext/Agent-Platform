-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Schema / Type / Meta-Model Schema
-- ============================================================

-- Purpose:
-- The schema layer defines types, classes, inheritance, acceptable values,
-- validation rules, protocol/framework/standard references, versions,
-- and environments. This lets the runtime reason about what things are,
-- what they inherit, what values are allowed, and which rules govern them.

DEFINE TABLE schema_definition SCHEMAFULL;

DEFINE FIELD entity ON schema_definition TYPE record<entity>;
DEFINE FIELD schema_kind ON schema_definition TYPE string
  ASSERT $value IN [
    "type",
    "class",
    "schema",
    "field",
    "enum",
    "validation_rule",
    "protocol",
    "framework",
    "standard",
    "version",
    "environment",
    "namespace",
    "taxonomy",
    "ontology"
  ];

DEFINE FIELD name ON schema_definition TYPE string;
DEFINE FIELD code ON schema_definition TYPE string;
DEFINE FIELD description ON schema_definition TYPE option<string>;
DEFINE FIELD status ON schema_definition TYPE string DEFAULT "draft"
  ASSERT $value IN ["draft", "active", "inactive", "deprecated", "archived"];

DEFINE FIELD parent ON schema_definition TYPE option<record<schema_definition>>;
DEFINE FIELD inherits_from ON schema_definition TYPE array<record<schema_definition>> DEFAULT [];
DEFINE FIELD extends ON schema_definition TYPE array<record<schema_definition>> DEFAULT [];
DEFINE FIELD equivalent_to ON schema_definition TYPE array<string> DEFAULT [];
DEFINE FIELD similar_to ON schema_definition TYPE array<string> DEFAULT [];
DEFINE FIELD aliases ON schema_definition TYPE array<string> DEFAULT [];

DEFINE FIELD version ON schema_definition TYPE string DEFAULT "0.1.0";
DEFINE FIELD version_of ON schema_definition TYPE option<record<schema_definition>>;
DEFINE FIELD namespace ON schema_definition TYPE option<string>;
DEFINE FIELD external_ref ON schema_definition TYPE option<string>;
DEFINE FIELD schema_org_type ON schema_definition TYPE option<string>;

DEFINE FIELD definition ON schema_definition TYPE object DEFAULT {};
DEFINE FIELD allowed_values ON schema_definition TYPE array<object> DEFAULT [];
DEFINE FIELD constraints ON schema_definition TYPE array<object> DEFAULT [];
DEFINE FIELD examples ON schema_definition TYPE array<object> DEFAULT [];

DEFINE FIELD applies_to_entity_types ON schema_definition TYPE array<string> DEFAULT [];
DEFINE FIELD applies_to_environments ON schema_definition TYPE array<string> DEFAULT [];
DEFINE FIELD governed_by ON schema_definition TYPE array<record<governance_object>> DEFAULT [];

DEFINE FIELD created_at ON schema_definition TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON schema_definition TYPE datetime VALUE time::now();
DEFINE FIELD valid_from ON schema_definition TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON schema_definition TYPE option<datetime>;
DEFINE FIELD metadata ON schema_definition TYPE option<object>;

DEFINE INDEX schema_definition_entity_idx ON schema_definition FIELDS entity UNIQUE;
DEFINE INDEX schema_definition_kind_idx ON schema_definition FIELDS schema_kind;
DEFINE INDEX schema_definition_code_idx ON schema_definition FIELDS code UNIQUE;
DEFINE INDEX schema_definition_status_idx ON schema_definition FIELDS status;
DEFINE INDEX schema_definition_name_idx ON schema_definition FIELDS name SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Validation Result
-- ------------------------------------------------------------

DEFINE TABLE validation_result SCHEMAFULL;

DEFINE FIELD target ON validation_result TYPE record<entity>;
DEFINE FIELD schema_definition ON validation_result TYPE option<record<schema_definition>>;
DEFINE FIELD validation_type ON validation_result TYPE string
  ASSERT $value IN [
    "schema",
    "field",
    "type",
    "class",
    "enum",
    "relationship",
    "policy",
    "protocol",
    "standard",
    "environment",
    "version",
    "completeness",
    "internal_alignment",
    "external_conformance"
  ];

DEFINE FIELD status ON validation_result TYPE string
  ASSERT $value IN ["passed", "failed", "warning", "skipped", "needs_review"];

DEFINE FIELD severity ON validation_result TYPE string DEFAULT "info"
  ASSERT $value IN ["info", "low", "medium", "high", "critical"];

DEFINE FIELD message ON validation_result TYPE string;
DEFINE FIELD path ON validation_result TYPE option<string>;
DEFINE FIELD expected ON validation_result TYPE option<object>;
DEFINE FIELD actual ON validation_result TYPE option<object>;
DEFINE FIELD evidence ON validation_result TYPE option<object>;
DEFINE FIELD created_at ON validation_result TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON validation_result TYPE option<object>;

DEFINE INDEX validation_target_idx ON validation_result FIELDS target;
DEFINE INDEX validation_schema_idx ON validation_result FIELDS schema_definition;
DEFINE INDEX validation_status_idx ON validation_result FIELDS status;
DEFINE INDEX validation_type_idx ON validation_result FIELDS validation_type;

-- ------------------------------------------------------------
-- Environment
-- ------------------------------------------------------------

DEFINE TABLE runtime_environment SCHEMAFULL;

DEFINE FIELD entity ON runtime_environment TYPE record<entity>;
DEFINE FIELD name ON runtime_environment TYPE string;
DEFINE FIELD environment_type ON runtime_environment TYPE string
  ASSERT $value IN [
    "local",
    "dev",
    "test",
    "staging",
    "production",
    "sandbox",
    "air_gapped",
    "edge",
    "customer_managed",
    "cloud_managed"
  ];

DEFINE FIELD status ON runtime_environment TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "maintenance", "degraded", "archived"];

DEFINE FIELD region ON runtime_environment TYPE option<string>;
DEFINE FIELD tenant ON runtime_environment TYPE option<string>;
DEFINE FIELD runtime ON runtime_environment TYPE option<string>;
DEFINE FIELD constraints ON runtime_environment TYPE array<object> DEFAULT [];
DEFINE FIELD allowed_protocols ON runtime_environment TYPE array<string> DEFAULT [];
DEFINE FIELD allowed_tools ON runtime_environment TYPE array<string> DEFAULT [];
DEFINE FIELD policy_refs ON runtime_environment TYPE array<record<governance_object>> DEFAULT [];
DEFINE FIELD metadata ON runtime_environment TYPE option<object>;
DEFINE FIELD created_at ON runtime_environment TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON runtime_environment TYPE datetime VALUE time::now();

DEFINE INDEX runtime_environment_entity_idx ON runtime_environment FIELDS entity UNIQUE;
DEFINE INDEX runtime_environment_type_idx ON runtime_environment FIELDS environment_type;
DEFINE INDEX runtime_environment_status_idx ON runtime_environment FIELDS status;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_validation(
  $target: record<entity>,
  $schema_definition: option<record<schema_definition>>,
  $validation_type: string,
  $status: string,
  $severity: string,
  $message: string,
  $path: option<string>,
  $expected: option<object>,
  $actual: option<object>
) {
  RETURN CREATE validation_result SET
    target = $target,
    schema_definition = $schema_definition,
    validation_type = $validation_type,
    status = $status,
    severity = $severity,
    message = $message,
    path = $path,
    expected = $expected,
    actual = $actual;
};

DEFINE FUNCTION fn::schema_is_active($schema_definition: record<schema_definition>) {
  LET $schema = SELECT * FROM ONLY $schema_definition;
  RETURN $schema.status = "active"
    AND ($schema.valid_to = NONE OR $schema.valid_to > time::now());
};

DEFINE FUNCTION fn::environment_allows_protocol(
  $environment: record<runtime_environment>,
  $protocol: string
) {
  LET $env = SELECT * FROM ONLY $environment;
  RETURN array::len($env.allowed_protocols) = 0 OR $protocol IN $env.allowed_protocols;
};
