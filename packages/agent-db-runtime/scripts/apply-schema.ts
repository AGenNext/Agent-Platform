import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { connectAgentDbRuntime, closeAgentDbRuntime, healthcheckAgentDbRuntime, readAgentDbRuntimeEnv } from "../src/db.js";
import { SCHEMA_FILES } from "../src/load-order.js";

const repoRoot = resolve(process.cwd());
const packageRoot = repoRoot.endsWith("agent-db-runtime")
  ? repoRoot
  : resolve(repoRoot, "packages/agent-db-runtime");

async function main(): Promise<void> {
  const env = readAgentDbRuntimeEnv();

  console.log("Applying Agent DB Runtime schemas...");
  console.log(`SurrealDB: ${env.url}`);
  console.log(`Namespace: ${env.namespace}`);
  console.log(`Database: ${env.database}\n`);

  const db = await connectAgentDbRuntime(env);

  try {
    const healthy = await healthcheckAgentDbRuntime(db);
    if (!healthy) {
      throw new Error("SurrealDB healthcheck failed.");
    }

    for (const file of SCHEMA_FILES) {
      const absolutePath = resolve(packageRoot, file);

      if (!existsSync(absolutePath)) {
        throw new Error(`Schema file not found: ${file}`);
      }

      const sql = await readFile(absolutePath, "utf8");

      try {
        await db.query(sql);
        console.log(`✓ ${file}`);
      } catch (error) {
        console.error(`\n✗ Failed applying ${file}`);
        throw error;
      }
    }

    console.log("\nSchema installation complete.");
  } finally {
    await closeAgentDbRuntime(db);
  }
}

main().catch((error) => {
  console.error("\nSchema installation failed.");
  console.error(error);
  process.exit(1);
});
