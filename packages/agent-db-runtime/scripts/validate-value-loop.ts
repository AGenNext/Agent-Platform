import { readFile, writeFile, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import {
  connectAgentDbRuntime,
  closeAgentDbRuntime,
  healthcheckAgentDbRuntime,
  readAgentDbRuntimeEnv
} from "../src/db.js";
import { SCHEMA_FILES } from "../src/load-order.js";

const repoRoot = resolve(process.cwd());
const packageRoot = repoRoot.endsWith("agent-db-runtime")
  ? repoRoot
  : resolve(repoRoot, "packages/agent-db-runtime");

const valueLoopSchema = "schema/design/value-loop-phase1.surql";
const valueLoopSmoke = "tests/value-loop-smoke.surql";
const evidenceDir = "reports/evidence";
const evidenceFile = "reports/evidence/value-loop-validation-output.json";

type ValidationEvidence = {
  status: "pass" | "fail";
  ranAt: string;
  environment: {
    url: string;
    namespace: string;
    database: string;
  };
  appliedSchemas: string[];
  smokeScript: string;
  checks: Record<string, number>;
  error?: string;
};

function requireFile(path: string): string {
  const absolutePath = resolve(packageRoot, path);
  if (!existsSync(absolutePath)) {
    throw new Error(`Required file not found: ${path}`);
  }
  return absolutePath;
}

function extractCount(result: unknown): number {
  const first = Array.isArray(result) ? result[0] : undefined;
  const rows = Array.isArray(first) ? first : Array.isArray(result) ? result : [];
  const row = rows[0] as { count?: number } | undefined;
  return Number(row?.count ?? 0);
}

async function writeEvidence(evidence: ValidationEvidence): Promise<void> {
  await mkdir(resolve(packageRoot, evidenceDir), { recursive: true });
  await writeFile(resolve(packageRoot, evidenceFile), `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

async function main(): Promise<void> {
  const env = readAgentDbRuntimeEnv();
  const appliedSchemas: string[] = [];

  const evidence: ValidationEvidence = {
    status: "fail",
    ranAt: new Date().toISOString(),
    environment: {
      url: env.url,
      namespace: env.namespace,
      database: env.database
    },
    appliedSchemas,
    smokeScript: valueLoopSmoke,
    checks: {}
  };

  console.log("Running Agent DB Runtime value-loop validation...");
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
      const absolutePath = requireFile(file);
      const sql = await readFile(absolutePath, "utf8");
      await db.query(sql);
      appliedSchemas.push(file);
      console.log(`✓ base schema ${file}`);
    }

    const valueLoopSchemaPath = requireFile(valueLoopSchema);
    await db.query(await readFile(valueLoopSchemaPath, "utf8"));
    appliedSchemas.push(valueLoopSchema);
    console.log(`✓ value-loop schema ${valueLoopSchema}`);

    const smokePath = requireFile(valueLoopSmoke);
    await db.query(await readFile(smokePath, "utf8"));
    console.log(`✓ smoke script ${valueLoopSmoke}`);

    const checks = {
      output: "SELECT count() AS count FROM output GROUP ALL;",
      outcome: "SELECT count() AS count FROM outcome GROUP ALL;",
      value_realization: "SELECT count() AS count FROM value_realization GROUP ALL;",
      learning: "SELECT count() AS count FROM learning GROUP ALL;",
      improvement: "SELECT count() AS count FROM improvement GROUP ALL;"
    };

    for (const [name, sql] of Object.entries(checks)) {
      const count = extractCount(await db.query(sql));
      evidence.checks[name] = count;
      if (count < 1) {
        throw new Error(`Value-loop check failed: ${name} has no records.`);
      }
      console.log(`✓ ${name} records: ${count}`);
    }

    evidence.status = "pass";
    await writeEvidence(evidence);
    console.log(`\nValue-loop validation complete. Evidence written to ${evidenceFile}`);
  } catch (error) {
    evidence.status = "fail";
    evidence.error = error instanceof Error ? error.stack ?? error.message : String(error);
    await writeEvidence(evidence);
    throw error;
  } finally {
    await closeAgentDbRuntime(db);
  }
}

main().catch((error) => {
  console.error("\nValue-loop validation failed.");
  console.error(error);
  process.exit(1);
});
