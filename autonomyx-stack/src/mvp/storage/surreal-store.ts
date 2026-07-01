import { initialState } from "../../platform.js";
import type { PlatformState } from "../../types.js";
import type { StateStore } from "./types.js";

export type SurrealStateStoreConfig = {
  endpoint: string;
  namespace: string;
  database: string;
  username?: string;
  password?: string;
  recordId?: string;
};

export class SurrealStateStore implements StateStore {
  readonly name = "surrealdb" as const;
  private readonly recordId: string;

  constructor(private readonly config: SurrealStateStoreConfig) {
    this.recordId = config.recordId ?? "autonomyx_state:mvp";
  }

  async load(): Promise<PlatformState> {
    const result = await this.query<[PlatformState]>(`SELECT * FROM ${this.recordId};`);
    const existing = Array.isArray(result) ? result[0] : undefined;
    if (existing) return existing;

    const state = initialState();
    await this.save(state);
    return state;
  }

  async save(state: PlatformState): Promise<void> {
    await this.query(`UPSERT ${this.recordId} CONTENT ${JSON.stringify(state)};`);
  }

  info(): Record<string, string | number | boolean | undefined> {
    return {
      provider: this.name,
      endpoint: this.config.endpoint,
      namespace: this.config.namespace,
      database: this.config.database,
      recordId: this.recordId,
    };
  }

  private async query<T>(query: string): Promise<T> {
    const headers: Record<string, string> = {
      accept: "application/json",
      "content-type": "application/surrealql",
      ns: this.config.namespace,
      db: this.config.database,
    };

    if (this.config.username && this.config.password) {
      headers.authorization = `Basic ${Buffer.from(`${this.config.username}:${this.config.password}`).toString("base64")}`;
    }

    const response = await fetch(`${this.config.endpoint.replace(/\/$/, "")}/sql`, {
      method: "POST",
      headers,
      body: query,
    });

    if (!response.ok) {
      throw new Error(`SurrealDB query failed: ${response.status} ${response.statusText}`);
    }

    const json = (await response.json()) as Array<{ status: string; result?: unknown; detail?: string }>;
    const first = json[0];
    if (!first || first.status !== "OK") {
      throw new Error(first?.detail ?? "SurrealDB query failed");
    }

    return first.result as T;
  }
}
