import type { PlatformState } from "../../types.js";

export type StorageProviderName = "json" | "surrealdb";

export interface StateStore {
  name: StorageProviderName;
  load(): Promise<PlatformState>;
  save(state: PlatformState): Promise<void>;
  info(): Record<string, string | number | boolean | undefined>;
}
