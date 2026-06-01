import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { connectAgentDbRuntime, closeAgentDbRuntime, healthcheckAgentDbRuntime, readAgentDbRuntimeEnv } from "../src/db.js";

const repoRoot = resolve(process.cwd());
const packageRoot = repoRoot.endsWith("agent-db-runtime")
  ? repoRoot
  : resolve(repoRoot, "packages/agent-db-runtime");

function timestamp(): string {
  return new Date().toISOString().replace(/[:.]/g, "-");
}

async function main(): Promise<void> {
  const env = readAgentDbRuntimeEnv();
  const backupDir = resolve(packageRoot, "backups");
  const backupFile = resolve(backupDir, `agent-runtime-${env.namespace}-${env.database}-${timestamp()}.surql`);

  console.log("Creating Agent DB Runtime backup...");
  console.log(`SurrealDB: ${env.url}`);
  console.log(`Namespace: ${env.namespace}`);
  console.log(`Database: ${env.database}`);
  console.log(`Output: ${backupFile}\n`);

  const db = await connectAgentDbRuntime(env);

  try {
    const healthy = await healthcheckAgentDbRuntime(db);
    if (!healthy) {
      throw new Error("SurrealDB healthcheck failed.");
    }

    await mkdir(backupDir, { recursive: true });

    const result = await db.query("EXPORT DATABASE;");
    const exported = JSON.stringify(result, null, 2);

    await writeFile(backupFile, exported, "utf8");
    console.log(`✓ Backup written: ${backupFile}`);
  } finally {
    await closeAgentDbRuntime(db);
  }
}

main().catch((error) => {
  console.error("\nBackup failed.");
  console.error(error);
  process.exit(1);
});
