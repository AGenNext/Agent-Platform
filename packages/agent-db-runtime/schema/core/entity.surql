-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Entity Schema
-- ============================================================

-- Purpose:
-- Every durable object in the agent platform starts as a governed entity.
-- Agent, Human, Team, Organization, Tool, Skill, Knowledge, Memory,
-- Credential, Policy, Action, Task, Workflow, Decision, Evaluation,
-- Evidence, Trust, Objective, Constraint, and Protocol all share this base.

DEFINE TABLE entity SCHEMAFULL;

DEFINE FIELD entity_type ON entity TYPE string
  ASSERT $value IN [
    "agent",
    "human",
    "team",
    "organization",
    "tool",
    "skill",
    "knowledge",
    "memory",
    "credential",
    "policy",
    "action",
    "task",
    "workflow",
    "decision",
    "evaluation",
    "evidence",
    "trust",
    "objective",
    "constraint",
    "protocol",
    "environment",
    "registry",
    "artifact",
    "integration",
    "runtime"
  ];

DEFINE FIELD entity_subtype ON entity TYPE option<string>;
DEFINE FIELD name ON entity TYPE string;
DEFINE FIELD description ON entity TYPE option<string>;

DEFINE FIELD status ON entity TYPE string DEFAULT "draft"
  ASSERT $value IN [
    "draft",
    "active",
    "inactive",
    "pending",
    "blocked",
    "suspended",
    "deprecated",
    "archived",
    "deleted"
  ];

DEFINE FIELD tenant ON entity TYPE option<string>;
DEFINE FIELD owner ON entity TYPE option<string>;
DEFINE FIELD namespace ON entity TYPE option<string>;

DEFINE FIELD version ON entity TYPE string DEFAULT "0.1.0";
DEFINE FIELD labels ON entity TYPE array<string> DEFAULT [];
DEFINE FIELD tags ON entity TYPE array<string> DEFAULT [];
DEFINE FIELD aliases ON entity TYPE array<string> DEFAULT [];

DEFINE FIELD valid_from ON entity TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON entity TYPE option<datetime>;
DEFINE FIELD created_at ON entity TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON entity TYPE datetime VALUE time::now();

DEFINE FIELD metadata ON entity TYPE option<object>;
DEFINE FIELD provenance ON entity TYPE option<object>;
DEFINE FIELD schema_ref ON entity TYPE option<string>;
DEFINE FIELD schema_version ON entity TYPE option<string>;
DEFINE FIELD schema_snapshot ON entity TYPE option<object>;

DEFINE INDEX entity_type_idx ON entity FIELDS entity_type;
DEFINE INDEX entity_status_idx ON entity FIELDS status;
DEFINE INDEX entity_tenant_idx ON entity FIELDS tenant;
DEFINE INDEX entity_name_idx ON entity FIELDS name SEARCH ANALYZER ascii BM25;
