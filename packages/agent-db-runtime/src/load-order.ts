export const SCHEMA_FILES = [
  "schema/core/entity.surql",
  "schema/core/relation.surql",
  "schema/core/schema.surql",
  "schema/core/identity.surql",
  "schema/core/security.surql",
  "schema/core/governance.surql",
  "schema/core/protocol.surql",
  "schema/core/registry.surql",
  "schema/core/action.surql",
  "schema/core/task.surql",
  "schema/core/decision.surql",
  "schema/core/workflow.surql",
  "schema/core/evaluation.surql",
  "schema/core/trust.surql",
  "schema/core/memory.surql",
  "schema/core/knowledge.surql",
  "schema/core/artifact.surql",
  "schema/core/assurance.surql",
  "schema/core/issue.surql",
  "schema/core/collaboration.surql",
  "schema/core/commerce.surql"
] as const;

export type SchemaFile = (typeof SCHEMA_FILES)[number];
