-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Memory Schema
-- ============================================================

-- Purpose:
-- Memory defines what the platform remembers, retrieves, summarizes,
-- compresses, promotes, demotes, archives, expires, forgets, links,
-- and reconciles. Memory is governed, scoped, auditable, and connected
-- to identity, task, decision, knowledge, evaluation, and trust.

DEFINE TABLE memory SCHEMAFULL;

DEFINE FIELD entity ON memory TYPE record<entity>;
DEFINE FIELD owner ON memory TYPE option<record<identity>>;
DEFINE FIELD subject ON memory TYPE option<record<entity>>;
DEFINE FIELD source_task ON memory TYPE option<record<task>>;
DEFINE FIELD source_decision ON memory TYPE option<record<decision>>;
DEFINE FIELD source_evaluation ON memory TYPE option<record<evaluation>>;
DEFINE FIELD source_trust_assessment ON memory TYPE option<record<trust_assessment>>;

DEFINE FIELD memory_type ON memory TYPE string
  ASSERT $value IN [
    "working",
    "short_term",
    "long_term",
    "episodic",
    "semantic",
    "procedural",
    "organizational",
    "team",
    "agent",
    "user",
    "task",
    "decision",
    "knowledge",
    "tool_usage",
    "evaluation",
    "trust"
  ];

DEFINE FIELD status ON memory TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "compressed", "archived", "expired", "forgotten", "disputed", "superseded"];

DEFINE FIELD title ON memory TYPE string;
DEFINE FIELD summary ON memory TYPE option<string>;
DEFINE FIELD content ON memory TYPE object DEFAULT {};
DEFINE FIELD embedding_ref ON memory TYPE option<string>;
DEFINE FIELD vector ON memory TYPE option<array<number>>;
DEFINE FIELD keywords ON memory TYPE array<string> DEFAULT [];
DEFINE FIELD tags ON memory TYPE array<string> DEFAULT [];

DEFINE FIELD importance ON memory TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD confidence ON memory TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD sensitivity ON memory TYPE string DEFAULT "internal" ASSERT $value IN ["public", "internal", "confidential", "restricted", "secret"];
DEFINE FIELD retention_policy ON memory TYPE option<object>;
DEFINE FIELD access_policy_refs ON memory TYPE array<record<governance_object>> DEFAULT [];

DEFINE FIELD valid_from ON memory TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON memory TYPE option<datetime>;
DEFINE FIELD expires_at ON memory TYPE option<datetime>;
DEFINE FIELD last_accessed_at ON memory TYPE option<datetime>;
DEFINE FIELD access_count ON memory TYPE int DEFAULT 0;
DEFINE FIELD created_at ON memory TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON memory TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON memory TYPE option<object>;

DEFINE INDEX memory_entity_idx ON memory FIELDS entity UNIQUE;
DEFINE INDEX memory_owner_idx ON memory FIELDS owner;
DEFINE INDEX memory_subject_idx ON memory FIELDS subject;
DEFINE INDEX memory_type_idx ON memory FIELDS memory_type;
DEFINE INDEX memory_status_idx ON memory FIELDS status;
DEFINE INDEX memory_importance_idx ON memory FIELDS importance;
DEFINE INDEX memory_title_idx ON memory FIELDS title SEARCH ANALYZER ascii BM25;
DEFINE INDEX memory_summary_idx ON memory FIELDS summary SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Memory Event
-- ------------------------------------------------------------

DEFINE TABLE memory_event SCHEMAFULL;

DEFINE FIELD memory ON memory_event TYPE record<memory>;
DEFINE FIELD event_type ON memory_event TYPE string
  ASSERT $value IN [
    "stored",
    "retrieved",
    "summarized",
    "compressed",
    "promoted",
    "demoted",
    "archived",
    "expired",
    "forgotten",
    "linked",
    "reconciled",
    "disputed",
    "superseded"
  ];

DEFINE FIELD actor ON memory_event TYPE option<record<identity>>;
DEFINE FIELD reason ON memory_event TYPE option<string>;
DEFINE FIELD payload ON memory_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON memory_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON memory_event TYPE option<object>;

DEFINE INDEX memory_event_memory_idx ON memory_event FIELDS memory;
DEFINE INDEX memory_event_type_idx ON memory_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::store_memory(
  $entity: record<entity>,
  $owner: option<record<identity>>,
  $subject: option<record<entity>>,
  $memory_type: string,
  $title: string,
  $summary: option<string>,
  $content: object,
  $importance: number,
  $confidence: option<number>
) {
  LET $created = CREATE memory SET
    entity = $entity,
    owner = $owner,
    subject = $subject,
    memory_type = $memory_type,
    title = $title,
    summary = $summary,
    content = $content,
    importance = $importance,
    confidence = $confidence,
    status = "active";

  CREATE memory_event SET
    memory = $created.id,
    event_type = "stored",
    actor = $owner,
    payload = { memory_type: $memory_type, importance: $importance, confidence: $confidence };

  RETURN $created;
};

DEFINE FUNCTION fn::retrieve_memory($memory: record<memory>, $actor: option<record<identity>>) {
  UPDATE $memory SET
    last_accessed_at = time::now(),
    access_count = access_count + 1;

  CREATE memory_event SET
    memory = $memory,
    event_type = "retrieved",
    actor = $actor;

  RETURN SELECT * FROM ONLY $memory;
};

DEFINE FUNCTION fn::promote_memory(
  $memory: record<memory>,
  $new_type: string,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $updated = UPDATE $memory SET memory_type = $new_type;

  CREATE memory_event SET
    memory = $memory,
    event_type = "promoted",
    actor = $actor,
    reason = $reason,
    payload = { new_type: $new_type };

  RETURN $updated;
};

DEFINE FUNCTION fn::compress_memory(
  $memory: record<memory>,
  $summary: string,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $updated = UPDATE $memory SET
    status = "compressed",
    summary = $summary;

  CREATE memory_event SET
    memory = $memory,
    event_type = "compressed",
    actor = $actor,
    reason = $reason,
    payload = { summary: $summary };

  RETURN $updated;
};

DEFINE FUNCTION fn::forget_memory(
  $memory: record<memory>,
  $actor: option<record<identity>>,
  $reason: string
) {
  LET $updated = UPDATE $memory SET
    status = "forgotten",
    content = {},
    summary = NONE,
    vector = NONE,
    embedding_ref = NONE,
    valid_to = time::now();

  CREATE memory_event SET
    memory = $memory,
    event_type = "forgotten",
    actor = $actor,
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::memory_is_usable($memory: record<memory>) {
  LET $m = SELECT * FROM ONLY $memory;
  RETURN $m.status IN ["active", "compressed"]
    AND ($m.expires_at = NONE OR $m.expires_at > time::now())
    AND ($m.valid_to = NONE OR $m.valid_to > time::now());
};
