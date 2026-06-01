import { connectAgentDbRuntime, closeAgentDbRuntime, healthcheckAgentDbRuntime, readAgentDbRuntimeEnv } from "../src/db.js";

type SmokeCheck = {
  name: string;
  sql: string;
};

const checks: SmokeCheck[] = [
  {
    name: "default tenant entity exists",
    sql: "SELECT count() AS count FROM entity WHERE id = entity:default_tenant GROUP ALL;"
  },
  {
    name: "system admin identity exists",
    sql: "SELECT count() AS count FROM identity WHERE id = identity:system_admin GROUP ALL;"
  },
  {
    name: "default agent registry exists",
    sql: "SELECT count() AS count FROM registry WHERE id = registry:default_agent_registry GROUP ALL;"
  },
  {
    name: "default runtime policy exists",
    sql: "SELECT count() AS count FROM governance_object WHERE id = governance_object:default_runtime_policy GROUP ALL;"
  }
];

function extractCount(result: unknown): number {
  const first = Array.isArray(result) ? result[0] : undefined;
  const rows = Array.isArray(first) ? first : Array.isArray(result) ? result : [];
  const row = rows[0] as { count?: number } | undefined;
  return Number(row?.count ?? 0);
}

async function main(): Promise<void> {
  const env = readAgentDbRuntimeEnv();

  console.log("Running Agent DB Runtime smoke tests...");
  console.log(`SurrealDB: ${env.url}`);
  console.log(`Namespace: ${env.namespace}`);
  console.log(`Database: ${env.database}\n`);

  const db = await connectAgentDbRuntime(env);

  try {
    const healthy = await healthcheckAgentDbRuntime(db);
    if (!healthy) {
      throw new Error("SurrealDB healthcheck failed.");
    }

    for (const check of checks) {
      const result = await db.query(check.sql);
      const count = extractCount(result);

      if (count < 1) {
        throw new Error(`Smoke check failed: ${check.name}`);
      }

      console.log(`✓ ${check.name}`);
    }

    console.log("\nSmoke tests complete.");
  } finally {
    await closeAgentDbRuntime(db);
  }
}

main().catch((error) => {
  console.error("\nSmoke tests failed.");
  console.error(error);
  process.exit(1);
});
