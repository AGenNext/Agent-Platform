import Surreal from "surrealdb";

const SURREAL_URL = import.meta.env.VITE_SURREALDB_URL ?? "ws://localhost:8000/rpc";
const NS = import.meta.env.VITE_SURREALDB_NS ?? "agent_platform";
const DB = import.meta.env.VITE_SURREALDB_DB ?? "agent_platform";

let _db: Surreal | null = null;
let _connecting = false;

export async function getSurrealClient(): Promise<Surreal> {
  if (_db) return _db;
  if (_connecting) {
    await new Promise((r) => setTimeout(r, 100));
    return getSurrealClient();
  }
  _connecting = true;
  const db = new Surreal();
  await db.connect(SURREAL_URL);
  await db.use({ namespace: NS, database: DB });
  _db = db;
  _connecting = false;
  return db;
}

export function closeSurrealClient() {
  if (_db) {
    _db.close();
    _db = null;
  }
}
