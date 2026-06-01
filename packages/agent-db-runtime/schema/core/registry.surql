-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Registry / Catalog / Discovery Schema
-- ============================================================

-- Purpose:
-- Registry makes platform assets discoverable, publishable, certifiable,
-- versioned, deprecated, and governed. It supports Agent Registry,
-- Skill Registry, Tool Registry, Protocol Registry, Model Registry,
-- Artifact Registry, Knowledge Registry, Workflow Registry, and Service
-- Registry patterns.

DEFINE TABLE registry SCHEMAFULL;

DEFINE FIELD entity ON registry TYPE record<entity>;
DEFINE FIELD owner ON registry TYPE option<record<identity>>;
DEFINE FIELD registry_type ON registry TYPE string
  ASSERT $value IN [
    "agent_registry",
    "skill_registry",
    "tool_registry",
    "protocol_registry",
    "model_registry",
    "artifact_registry",
    "knowledge_registry",
    "workflow_registry",
    "service_registry",
    "policy_registry",
    "schema_registry",
    "integration_registry",
    "marketplace",
    "catalog",
    "directory"
  ];

DEFINE FIELD name ON registry TYPE string;
DEFINE FIELD description ON registry TYPE option<string>;
DEFINE FIELD status ON registry TYPE string DEFAULT "active"
  ASSERT $value IN ["draft", "active", "inactive", "maintenance", "deprecated", "archived"];

DEFINE FIELD visibility ON registry TYPE string DEFAULT "internal"
  ASSERT $value IN ["public", "internal", "private", "restricted"];

DEFINE FIELD governance_refs ON registry TYPE array<record<governance_object>> DEFAULT [];
DEFINE FIELD allowed_entry_types ON registry TYPE array<string> DEFAULT [];
DEFINE FIELD publication_rules ON registry TYPE array<object> DEFAULT [];
DEFINE FIELD certification_rules ON registry TYPE array<object> DEFAULT [];
DEFINE FIELD discovery_config ON registry TYPE object DEFAULT {};
DEFINE FIELD metadata ON registry TYPE option<object>;
DEFINE FIELD created_at ON registry TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON registry TYPE datetime VALUE time::now();

DEFINE INDEX registry_entity_idx ON registry FIELDS entity UNIQUE;
DEFINE INDEX registry_type_idx ON registry FIELDS registry_type;
DEFINE INDEX registry_status_idx ON registry FIELDS status;
DEFINE INDEX registry_name_idx ON registry FIELDS name SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Registry Entry
-- ------------------------------------------------------------

DEFINE TABLE registry_entry SCHEMAFULL;

DEFINE FIELD registry ON registry_entry TYPE record<registry>;
DEFINE FIELD entity ON registry_entry TYPE record<entity>;
DEFINE FIELD publisher ON registry_entry TYPE option<record<identity>>;
DEFINE FIELD entry_type ON registry_entry TYPE string
  ASSERT $value IN [
    "agent",
    "skill",
    "tool",
    "protocol",
    "model",
    "artifact",
    "knowledge",
    "workflow",
    "service",
    "policy",
    "schema",
    "integration",
    "dataset",
    "template",
    "connector",
    "runtime"
  ];

DEFINE FIELD name ON registry_entry TYPE string;
DEFINE FIELD description ON registry_entry TYPE option<string>;
DEFINE FIELD status ON registry_entry TYPE string DEFAULT "draft"
  ASSERT $value IN [
    "draft",
    "submitted",
    "reviewing",
    "published",
    "certified",
    "rejected",
    "deprecated",
    "suspended",
    "archived"
  ];

DEFINE FIELD version ON registry_entry TYPE string DEFAULT "0.1.0";
DEFINE FIELD version_of ON registry_entry TYPE option<record<registry_entry>>;
DEFINE FIELD target_entity ON registry_entry TYPE record<entity>;
DEFINE FIELD artifact ON registry_entry TYPE option<record<artifact>>;
DEFINE FIELD protocol_bindings ON registry_entry TYPE array<record<protocol_binding>> DEFAULT [];
DEFINE FIELD trust_assessment ON registry_entry TYPE option<record<trust_assessment>>;
DEFINE FIELD evaluations ON registry_entry TYPE array<record<evaluation>> DEFAULT [];
DEFINE FIELD assurance_products ON registry_entry TYPE array<record<assurance_product>> DEFAULT [];
DEFINE FIELD schema_refs ON registry_entry TYPE array<record<schema_definition>> DEFAULT [];
DEFINE FIELD tags ON registry_entry TYPE array<string> DEFAULT [];
DEFINE FIELD categories ON registry_entry TYPE array<string> DEFAULT [];
DEFINE FIELD capabilities ON registry_entry TYPE array<string> DEFAULT [];
DEFINE FIELD pricing_ref ON registry_entry TYPE option<string>;
DEFINE FIELD license_ref ON registry_entry TYPE option<string>;
DEFINE FIELD external_ref ON registry_entry TYPE option<string>;
DEFINE FIELD published_at ON registry_entry TYPE option<datetime>;
DEFINE FIELD deprecated_at ON registry_entry TYPE option<datetime>;
DEFINE FIELD created_at ON registry_entry TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON registry_entry TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON registry_entry TYPE option<object>;

DEFINE INDEX registry_entry_registry_idx ON registry_entry FIELDS registry;
DEFINE INDEX registry_entry_entity_idx ON registry_entry FIELDS entity UNIQUE;
DEFINE INDEX registry_entry_target_idx ON registry_entry FIELDS target_entity;
DEFINE INDEX registry_entry_type_idx ON registry_entry FIELDS entry_type;
DEFINE INDEX registry_entry_status_idx ON registry_entry FIELDS status;
DEFINE INDEX registry_entry_name_idx ON registry_entry FIELDS name SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Registry Event
-- ------------------------------------------------------------

DEFINE TABLE registry_event SCHEMAFULL;

DEFINE FIELD registry_entry ON registry_event TYPE record<registry_entry>;
DEFINE FIELD event_type ON registry_event TYPE string
  ASSERT $value IN [
    "created",
    "submitted",
    "review_started",
    "published",
    "certified",
    "rejected",
    "updated",
    "version_created",
    "deprecated",
    "suspended",
    "archived",
    "discovered",
    "installed",
    "uninstalled"
  ];

DEFINE FIELD actor ON registry_event TYPE option<record<identity>>;
DEFINE FIELD reason ON registry_event TYPE option<string>;
DEFINE FIELD payload ON registry_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON registry_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON registry_event TYPE option<object>;

DEFINE INDEX registry_event_entry_idx ON registry_event FIELDS registry_entry;
DEFINE INDEX registry_event_type_idx ON registry_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::publish_registry_entry(
  $entry: record<registry_entry>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $updated = UPDATE $entry SET
    status = "published",
    published_at = time::now();

  CREATE registry_event SET
    registry_entry = $entry,
    event_type = "published",
    actor = $actor,
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::certify_registry_entry(
  $entry: record<registry_entry>,
  $actor: option<record<identity>>,
  $evaluation: option<record<evaluation>>,
  $trust_assessment: option<record<trust_assessment>>,
  $reason: option<string>
) {
  LET $updated = UPDATE $entry SET
    status = "certified",
    evaluations += IF $evaluation = NONE THEN [] ELSE [$evaluation] END,
    trust_assessment = IF $trust_assessment = NONE THEN trust_assessment ELSE $trust_assessment END;

  CREATE registry_event SET
    registry_entry = $entry,
    event_type = "certified",
    actor = $actor,
    reason = $reason,
    payload = { evaluation: $evaluation, trust_assessment: $trust_assessment };

  RETURN $updated;
};

DEFINE FUNCTION fn::deprecate_registry_entry(
  $entry: record<registry_entry>,
  $actor: option<record<identity>>,
  $reason: string
) {
  LET $updated = UPDATE $entry SET
    status = "deprecated",
    deprecated_at = time::now();

  CREATE registry_event SET
    registry_entry = $entry,
    event_type = "deprecated",
    actor = $actor,
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::registry_entry_is_usable($entry: record<registry_entry>) {
  LET $e = SELECT * FROM ONLY $entry;
  RETURN $e.status IN ["published", "certified"];
};
