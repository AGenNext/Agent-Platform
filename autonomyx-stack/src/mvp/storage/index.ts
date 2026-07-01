import type { StateStore, StorageProviderName } from "./types.js";
import { JsonStateStore } from "./json-store.js";
import { SurrealStateStore } from "./surreal-store.js";

export function createStateStore(): StateStore {
  const provider = (process.env.AUTONOMYX_STATE_PROVIDER ?? "json") as StorageProviderName;

  if (provider === "surrealdb") {
    return new SurrealStateStore({
      endpoint: process.env.SURREALDB_ENDPOINT ?? "http://surrealdb.fabric.svc.cluster.local:8000",
      namespace: process.env.SURREALDB_NAMESPACE ?? "agennext",
      database: process.env.SURREALDB_DATABASE ?? "fabric",
      username: process.env.SURREALDB_USERNAME,
      password: process.env.SURREALDB_PASSWORD,
      recordId: process.env.AUTONOMYX_STATE_RECORD_ID,
    });
  }

  return new JsonStateStore(process.env.AUTONOMYX_STATE_FILE ?? "./data/autonomyx-state.json");
}
