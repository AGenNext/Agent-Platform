-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Knowledge Schema
-- ============================================================

-- Purpose:
-- Knowledge is governed canonical information. Memory records what
-- happened or what was remembered; knowledge records what is known,
-- claimed, observed, verified, disputed, derived, cited, and governed.

DEFINE TABLE knowledge_item SCHEMAFULL;

DEFINE FIELD entity ON knowledge_item TYPE record<entity>;
DEFINE FIELD owner ON knowledge_item TYPE option<record<identity>>;
DEFINE FIELD subject ON knowledge_item TYPE option<record<entity>>;
DEFINE FIELD source_memory ON knowledge_item TYPE option<record<memory>>;
DEFINE FIELD source_decision ON knowledge_item TYPE option<record<decision>>;
DEFINE FIELD source_evaluation ON knowledge_item TYPE option<record<evaluation>>;
DEFINE FIELD source_trust_assessment ON knowledge_item TYPE option<record<trust_assessment>>;

DEFINE FIELD knowledge_type ON knowledge_item TYPE string
  ASSERT $value IN [
    "fact",
    "claim",
    "observation",
    "rule",
    "definition",
    "procedure",
    "classification",
    "taxonomy",
    "ontology",
    "entity_attribute",
    "relationship",
    "source",
    "citation",
    "evidence",
    "derived_knowledge",
    "verified_knowledge"
  ];

DEFINE FIELD status ON knowledge_item TYPE string DEFAULT "draft"
  ASSERT $value IN [
    "draft",
    "candidate",
    "canonical",
    "derived",
    "verified",
    "disputed",
    "superseded",
    "deprecated",
    "archived"
  ];

DEFINE FIELD title ON knowledge_item TYPE string;
DEFINE FIELD summary ON knowledge_item TYPE option<string>;
DEFINE FIELD content ON knowledge_item TYPE object DEFAULT {};
DEFINE FIELD statement ON knowledge_item TYPE option<string>;
DEFINE FIELD language ON knowledge_item TYPE string DEFAULT "en";

DEFINE FIELD source_refs ON knowledge_item TYPE array<string> DEFAULT [];
DEFINE FIELD citations ON knowledge_item TYPE array<object> DEFAULT [];
DEFINE FIELD evidence ON knowledge_item TYPE option<object>;
DEFINE FIELD provenance ON knowledge_item TYPE option<object>;
DEFINE FIELD verification_result ON knowledge_item TYPE option<object>;

DEFINE FIELD confidence ON knowledge_item TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD trust_assessment ON knowledge_item TYPE option<record<trust_assessment>>;
DEFINE FIELD schema_refs ON knowledge_item TYPE array<record<schema_definition>> DEFAULT [];
DEFINE FIELD governed_by ON knowledge_item TYPE array<record<governance_object>> DEFAULT [];
DEFINE FIELD tags ON knowledge_item TYPE array<string> DEFAULT [];
DEFINE FIELD keywords ON knowledge_item TYPE array<string> DEFAULT [];

DEFINE FIELD valid_from ON knowledge_item TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON knowledge_item TYPE option<datetime>;
DEFINE FIELD created_at ON knowledge_item TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON knowledge_item TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON knowledge_item TYPE option<object>;

DEFINE INDEX knowledge_entity_idx ON knowledge_item FIELDS entity UNIQUE;
DEFINE INDEX knowledge_owner_idx ON knowledge_item FIELDS owner;
DEFINE INDEX knowledge_subject_idx ON knowledge_item FIELDS subject;
DEFINE INDEX knowledge_type_idx ON knowledge_item FIELDS knowledge_type;
DEFINE INDEX knowledge_status_idx ON knowledge_item FIELDS status;
DEFINE INDEX knowledge_title_idx ON knowledge_item FIELDS title SEARCH ANALYZER ascii BM25;
DEFINE INDEX knowledge_statement_idx ON knowledge_item FIELDS statement SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Knowledge Relation
-- ------------------------------------------------------------

DEFINE TABLE knowledge_relation TYPE RELATION IN knowledge_item OUT knowledge_item SCHEMAFULL;

DEFINE FIELD relation_type ON knowledge_relation TYPE string
  ASSERT $value IN [
    "supports",
    "contradicts",
    "derives_from",
    "cites",
    "explains",
    "classifies",
    "specializes",
    "generalizes",
    "equivalent_to",
    "similar_to",
    "supersedes",
    "depends_on",
    "part_of",
    "related_to"
  ];

DEFINE FIELD confidence ON knowledge_relation TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD evidence ON knowledge_relation TYPE option<object>;
DEFINE FIELD created_at ON knowledge_relation TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON knowledge_relation TYPE option<object>;

DEFINE INDEX knowledge_relation_type_idx ON knowledge_relation FIELDS relation_type;

-- ------------------------------------------------------------
-- Knowledge Event
-- ------------------------------------------------------------

DEFINE TABLE knowledge_event SCHEMAFULL;

DEFINE FIELD knowledge_item ON knowledge_event TYPE record<knowledge_item>;
DEFINE FIELD event_type ON knowledge_event TYPE string
  ASSERT $value IN [
    "created",
    "promoted_to_candidate",
    "verified",
    "made_canonical",
    "disputed",
    "superseded",
    "deprecated",
    "archived",
    "citation_added",
    "evidence_added",
    "classification_added",
    "relation_added"
  ];

DEFINE FIELD actor ON knowledge_event TYPE option<record<identity>>;
DEFINE FIELD reason ON knowledge_event TYPE option<string>;
DEFINE FIELD payload ON knowledge_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON knowledge_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON knowledge_event TYPE option<object>;

DEFINE INDEX knowledge_event_item_idx ON knowledge_event FIELDS knowledge_item;
DEFINE INDEX knowledge_event_type_idx ON knowledge_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_knowledge(
  $entity: record<entity>,
  $knowledge_type: string,
  $title: string,
  $statement: option<string>,
  $content: object,
  $owner: option<record<identity>>,
  $subject: option<record<entity>>,
  $confidence: option<number>,
  $evidence: option<object>
) {
  LET $created = CREATE knowledge_item SET
    entity = $entity,
    knowledge_type = $knowledge_type,
    title = $title,
    statement = $statement,
    content = $content,
    owner = $owner,
    subject = $subject,
    confidence = $confidence,
    evidence = $evidence,
    status = "candidate";

  CREATE knowledge_event SET
    knowledge_item = $created.id,
    event_type = "created",
    actor = $owner,
    payload = { knowledge_type: $knowledge_type, confidence: $confidence };

  RETURN $created;
};

DEFINE FUNCTION fn::verify_knowledge(
  $knowledge_item: record<knowledge_item>,
  $actor: option<record<identity>>,
  $verification_result: object,
  $reason: option<string>
) {
  LET $updated = UPDATE $knowledge_item SET
    status = "verified",
    verification_result = $verification_result;

  CREATE knowledge_event SET
    knowledge_item = $knowledge_item,
    event_type = "verified",
    actor = $actor,
    reason = $reason,
    payload = { verification_result: $verification_result };

  RETURN $updated;
};

DEFINE FUNCTION fn::make_knowledge_canonical(
  $knowledge_item: record<knowledge_item>,
  $actor: option<record<identity>>,
  $reason: option<string>
) {
  LET $updated = UPDATE $knowledge_item SET status = "canonical";

  CREATE knowledge_event SET
    knowledge_item = $knowledge_item,
    event_type = "made_canonical",
    actor = $actor,
    reason = $reason;

  RETURN $updated;
};

DEFINE FUNCTION fn::dispute_knowledge(
  $knowledge_item: record<knowledge_item>,
  $actor: option<record<identity>>,
  $reason: string,
  $evidence: option<object>
) {
  LET $updated = UPDATE $knowledge_item SET
    status = "disputed",
    evidence = $evidence;

  CREATE knowledge_event SET
    knowledge_item = $knowledge_item,
    event_type = "disputed",
    actor = $actor,
    reason = $reason,
    payload = { evidence: $evidence };

  RETURN $updated;
};

DEFINE FUNCTION fn::knowledge_is_usable($knowledge_item: record<knowledge_item>) {
  LET $k = SELECT * FROM ONLY $knowledge_item;
  RETURN $k.status IN ["canonical", "verified"]
    AND ($k.valid_to = NONE OR $k.valid_to > time::now())
    AND ($k.confidence = NONE OR $k.confidence >= 0.70);
};
