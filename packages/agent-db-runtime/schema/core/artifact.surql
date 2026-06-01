-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Artifact Schema
-- ============================================================

-- Purpose:
-- Artifact represents durable outputs and externalized work products:
-- documents, reports, code, pull requests, contracts, invoices,
-- presentations, datasets, models, workflow definitions, policy files,
-- decision records, evaluation reports, knowledge entries, and generated
-- outputs. Artifacts connect work execution to the outside world.

DEFINE TABLE artifact SCHEMAFULL;

DEFINE FIELD entity ON artifact TYPE record<entity>;
DEFINE FIELD owner ON artifact TYPE option<record<identity>>;
DEFINE FIELD produced_by_task ON artifact TYPE option<record<task>>;
DEFINE FIELD produced_by_decision ON artifact TYPE option<record<decision>>;
DEFINE FIELD produced_by_workflow_run ON artifact TYPE option<record<workflow_run>>;
DEFINE FIELD source_memory ON artifact TYPE option<record<memory>>;
DEFINE FIELD source_knowledge ON artifact TYPE option<record<knowledge_item>>;

DEFINE FIELD artifact_type ON artifact TYPE string
  ASSERT $value IN [
    "document",
    "report",
    "blog",
    "prd",
    "code",
    "pull_request",
    "contract",
    "invoice",
    "presentation",
    "dataset",
    "model",
    "workflow_definition",
    "policy_artifact",
    "decision_record",
    "evaluation_report",
    "knowledge_base_entry",
    "image",
    "video",
    "audio",
    "spreadsheet",
    "diagram",
    "configuration",
    "schema",
    "api_spec",
    "runbook",
    "playbook",
    "generated_output"
  ];

DEFINE FIELD status ON artifact TYPE string DEFAULT "draft"
  ASSERT $value IN [
    "draft",
    "generated",
    "reviewing",
    "approved",
    "published",
    "deployed",
    "superseded",
    "deprecated",
    "archived",
    "deleted"
  ];

DEFINE FIELD title ON artifact TYPE string;
DEFINE FIELD description ON artifact TYPE option<string>;
DEFINE FIELD mime_type ON artifact TYPE option<string>;
DEFINE FIELD format ON artifact TYPE option<string>;
DEFINE FIELD uri ON artifact TYPE option<string>;
DEFINE FIELD storage_ref ON artifact TYPE option<string>;
DEFINE FIELD checksum ON artifact TYPE option<string>;
DEFINE FIELD size_bytes ON artifact TYPE option<int>;

DEFINE FIELD version ON artifact TYPE string DEFAULT "0.1.0";
DEFINE FIELD version_of ON artifact TYPE option<record<artifact>>;
DEFINE FIELD content_snapshot ON artifact TYPE option<object>;
DEFINE FIELD content_text ON artifact TYPE option<string>;
DEFINE FIELD schema_refs ON artifact TYPE array<record<schema_definition>> DEFAULT [];
DEFINE FIELD governed_by ON artifact TYPE array<record<governance_object>> DEFAULT [];
DEFINE FIELD trust_assessment ON artifact TYPE option<record<trust_assessment>>;
DEFINE FIELD evaluation ON artifact TYPE option<record<evaluation>>;

DEFINE FIELD visibility ON artifact TYPE string DEFAULT "internal"
  ASSERT $value IN ["public", "internal", "confidential", "restricted", "secret"];

DEFINE FIELD tags ON artifact TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON artifact TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON artifact TYPE datetime VALUE time::now();
DEFINE FIELD published_at ON artifact TYPE option<datetime>;
DEFINE FIELD archived_at ON artifact TYPE option<datetime>;
DEFINE FIELD metadata ON artifact TYPE option<object>;

DEFINE INDEX artifact_entity_idx ON artifact FIELDS entity UNIQUE;
DEFINE INDEX artifact_owner_idx ON artifact FIELDS owner;
DEFINE INDEX artifact_type_idx ON artifact FIELDS artifact_type;
DEFINE INDEX artifact_status_idx ON artifact FIELDS status;
DEFINE INDEX artifact_title_idx ON artifact FIELDS title SEARCH ANALYZER ascii BM25;
DEFINE INDEX artifact_text_idx ON artifact FIELDS content_text SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Artifact Event
-- ------------------------------------------------------------

DEFINE TABLE artifact_event SCHEMAFULL;

DEFINE FIELD artifact ON artifact_event TYPE record<artifact>;
DEFINE FIELD event_type ON artifact_event TYPE string
  ASSERT $value IN [
    "created",
    "generated",
    "updated",
    "submitted_for_review",
    "approved",
    "rejected",
    "published",
    "deployed",
    "superseded",
    "deprecated",
    "archived",
    "deleted",
    "version_created",
    "evaluation_attached",
    "trust_attached"
  ];

DEFINE FIELD actor ON artifact_event TYPE option<record<identity>>;
DEFINE FIELD reason ON artifact_event TYPE option<string>;
DEFINE FIELD payload ON artifact_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON artifact_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON artifact_event TYPE option<object>;

DEFINE INDEX artifact_event_artifact_idx ON artifact_event FIELDS artifact;
DEFINE INDEX artifact_event_type_idx ON artifact_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_artifact(
  $entity: record<entity>,
  $artifact_type: string,
  $title: string,
  $owner: option<record<identity>>,
  $uri: option<string>,
  $storage_ref: option<string>,
  $content_snapshot: option<object>,
  $content_text: option<string>
) {
  LET $created = CREATE artifact SET
    entity = $entity,
    artifact_type = $artifact_type,
    title = $title,
    owner = $owner,
    uri = $uri,
    storage_ref = $storage_ref,
    content_snapshot = $content_snapshot,
    content_text = $content_text,
    status = "generated";

  CREATE artifact_event SET
    artifact = $created.id,
    event_type = "created",
    actor = $owner,
    payload = { artifact_type: $artifact_type, uri: $uri, storage_ref: $storage_ref };

  RETURN $created;
};

DEFINE FUNCTION fn::publish_artifact(
  $artifact: record<artifact>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $updated = UPDATE $artifact SET
    status = "published",
    published_at = time::now();

  CREATE artifact_event SET
    artifact = $artifact,
    event_type = "published",
    actor = $actor,
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::archive_artifact(
  $artifact: record<artifact>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $updated = UPDATE $artifact SET
    status = "archived",
    archived_at = time::now();

  CREATE artifact_event SET
    artifact = $artifact,
    event_type = "archived",
    actor = $actor,
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::artifact_is_usable($artifact: record<artifact>) {
  LET $a = SELECT * FROM ONLY $artifact;
  RETURN $a.status IN ["generated", "approved", "published", "deployed"];
};
