-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Relation Schema
-- ============================================================

-- Purpose:
-- A relation is the governed graph edge between two entities.
-- This keeps the platform composable: agents use tools, tasks depend on
-- knowledge, policies govern actions, humans approve decisions, etc.

DEFINE TABLE entity_relation TYPE RELATION IN entity OUT entity SCHEMAFULL;

DEFINE FIELD relation_type ON entity_relation TYPE string
  ASSERT $value IN [
    "owns",
    "contains",
    "depends_on",
    "uses",
    "calls",
    "executes",
    "delegates",
    "approves",
    "rejects",
    "evaluates",
    "trusts",
    "knows",
    "references",
    "governs",
    "constrains",
    "implements",
    "extends",
    "inherits",
    "version_of",
    "member_of",
    "reports_to",
    "created_by",
    "assigned_to",
    "observes",
    "emits",
    "consumes",
    "produces",
    "validates",
    "verifies",
    "authenticates",
    "authorizes",
    "routes_to",
    "hands_off_to",
    "collaborates_with",
    "similar_to",
    "alias_of",
    "alternative_to",
    "derived_from",
    "reconciles_with"
  ];

DEFINE FIELD status ON entity_relation TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "pending", "blocked", "deprecated", "archived"];

DEFINE FIELD strength ON entity_relation TYPE option<number>
  ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD confidence ON entity_relation TYPE option<number>
  ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD source ON entity_relation TYPE option<string>;
DEFINE FIELD reason ON entity_relation TYPE option<string>;
DEFINE FIELD evidence ON entity_relation TYPE option<object>;
DEFINE FIELD policy_result ON entity_relation TYPE option<object>;

DEFINE FIELD valid_from ON entity_relation TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON entity_relation TYPE option<datetime>;
DEFINE FIELD created_at ON entity_relation TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON entity_relation TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON entity_relation TYPE option<object>;

DEFINE INDEX entity_relation_type_idx ON entity_relation FIELDS relation_type;
DEFINE INDEX entity_relation_status_idx ON entity_relation FIELDS status;

DEFINE FUNCTION fn::relate_entity(
  $from: record<entity>,
  $to: record<entity>,
  $relation_type: string,
  $reason: option<string>,
  $confidence: option<number>
) {
  RETURN RELATE $from->entity_relation->$to SET
    relation_type = $relation_type,
    reason = $reason,
    confidence = $confidence,
    status = "active";
};
