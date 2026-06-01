import { connectAgentDbRuntime, closeAgentDbRuntime, healthcheckAgentDbRuntime, readAgentDbRuntimeEnv } from "../src/db.js";

const seedSql = String.raw`
LET $tenant_entity = UPSERT entity:default_tenant CONTENT {
  entity_type: "organization",
  entity_subtype: "tenant",
  name: "Default Tenant",
  description: "Default bootstrap tenant for local and CI validation",
  status: "active",
  tenant: "default",
  owner: "system",
  namespace: "agennext",
  version: "0.1.0",
  labels: ["bootstrap", "tenant"],
  tags: ["default"],
  aliases: ["default"],
  schema_ref: "schema.org/Organization",
  schema_version: "0.1.0",
  metadata: { bootstrap: true }
};

LET $admin_entity = UPSERT entity:system_admin CONTENT {
  entity_type: "human",
  entity_subtype: "admin",
  name: "System Admin",
  description: "Bootstrap administrator identity",
  status: "active",
  tenant: "default",
  owner: "system",
  namespace: "agennext",
  version: "0.1.0",
  labels: ["bootstrap", "admin"],
  tags: ["system"],
  aliases: ["admin"],
  schema_ref: "schema.org/Person",
  schema_version: "0.1.0",
  metadata: { bootstrap: true }
};

LET $admin_identity = UPSERT identity:system_admin CONTENT {
  entity: entity:system_admin,
  identity_type: "human",
  subject: "system:admin",
  display_name: "System Admin",
  email: "admin@example.local",
  issuer: "agennext-bootstrap",
  provider: "local",
  provider_subject: "system:admin",
  lifecycle_state: "active",
  assurance_level: "high",
  verified: true,
  verified_at: time::now(),
  verification_method: "bootstrap",
  verification_evidence: { source: "seed.ts" },
  claims: { role: "admin", tenant: "default" },
  attributes: { bootstrap: true },
  metadata: { bootstrap: true }
};

LET $registry_entity = UPSERT entity:default_agent_registry CONTENT {
  entity_type: "registry",
  entity_subtype: "agent_registry",
  name: "Default Agent Registry",
  description: "Default registry for local and CI validation",
  status: "active",
  tenant: "default",
  owner: "system:admin",
  namespace: "agennext",
  version: "0.1.0",
  labels: ["bootstrap", "registry"],
  tags: ["agent", "registry"],
  aliases: ["default-agent-registry"],
  metadata: { bootstrap: true }
};

UPSERT registry:default_agent_registry CONTENT {
  entity: entity:default_agent_registry,
  owner: identity:system_admin,
  registry_type: "agent_registry",
  name: "Default Agent Registry",
  description: "Default registry for agents in local and CI validation",
  status: "active",
  visibility: "internal",
  allowed_entry_types: ["agent", "skill", "tool", "workflow", "service"],
  publication_rules: [],
  certification_rules: [],
  discovery_config: { enabled: true },
  metadata: { bootstrap: true }
};

LET $policy_entity = UPSERT entity:default_runtime_policy CONTENT {
  entity_type: "policy",
  entity_subtype: "agent_runtime_policy",
  name: "Default Runtime Policy",
  description: "Bootstrap policy for local and CI validation",
  status: "active",
  tenant: "default",
  owner: "system:admin",
  namespace: "agennext",
  version: "0.1.0",
  labels: ["bootstrap", "policy"],
  tags: ["governance"],
  aliases: ["default-runtime-policy"],
  metadata: { bootstrap: true }
};

UPSERT governance_object:default_runtime_policy CONTENT {
  entity: entity:default_runtime_policy,
  governance_type: "policy",
  code: "AGX-RUNTIME-DEFAULT",
  title: "Default Runtime Policy",
  description: "Default allow policy used only for bootstrap validation",
  status: "active",
  severity: "info",
  priority: "medium",
  applies_to_entity_types: ["agent", "task", "workflow", "action"],
  applies_to_actions: ["create", "read", "update", "execute"],
  applies_to_environments: ["local", "dev", "test", "ci"],
  rule: { effect: "allow", bootstrap: true },
  expression_language: "natural_language",
  external_ref: NONE,
  owner: identity:system_admin,
  metadata: { bootstrap: true }
};

RETURN {
  tenant: entity:default_tenant,
  admin: identity:system_admin,
  registry: registry:default_agent_registry,
  policy: governance_object:default_runtime_policy
};
`;

async function main(): Promise<void> {
  const env = readAgentDbRuntimeEnv();

  console.log("Seeding Agent DB Runtime...");
  console.log(`SurrealDB: ${env.url}`);
  console.log(`Namespace: ${env.namespace}`);
  console.log(`Database: ${env.database}\n`);

  const db = await connectAgentDbRuntime(env);

  try {
    const healthy = await healthcheckAgentDbRuntime(db);
    if (!healthy) {
      throw new Error("SurrealDB healthcheck failed.");
    }

    await db.query(seedSql);
    console.log("✓ Seed complete");
  } finally {
    await closeAgentDbRuntime(db);
  }
}

main().catch((error) => {
  console.error("\nSeed failed.");
  console.error(error);
  process.exit(1);
});
