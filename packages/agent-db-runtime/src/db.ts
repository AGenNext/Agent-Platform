import Surreal from "surrealdb";

export type AgentDbRuntimeEnv = {
  url: string;
  username: string;
  password: string;
  namespace: string;
  database: string;
};

export function readAgentDbRuntimeEnv(): AgentDbRuntimeEnv {
  return {
    url: process.env.SURREAL_URL ?? "http://127.0.0.1:8000/rpc",
    username: process.env.SURREAL_USER ?? "root",
    password: process.env.SURREAL_PASS ?? "root",
    namespace: process.env.SURREAL_NS ?? "agennext",
    database: process.env.SURREAL_DB ?? "agent_runtime"
  };
}

export async function connectAgentDbRuntime(env: AgentDbRuntimeEnv = readAgentDbRuntimeEnv()): Promise<Surreal> {
  const db = new Surreal();

  await db.connect(env.url);

  await db.signin({
    username: env.username,
    password: env.password
  });

  await db.use({
    namespace: env.namespace,
    database: env.database
  });

  return db;
}

export async function closeAgentDbRuntime(db: Surreal): Promise<void> {
  await db.close();
}

export async function healthcheckAgentDbRuntime(db: Surreal): Promise<boolean> {
  try {
    await db.query("RETURN true;");
    return true;
  } catch {
    return false;
  }
}
