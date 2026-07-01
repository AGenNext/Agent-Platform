import type { PlatformState } from "../types.js";
import { createStateStore } from "./storage/index.js";

const store = createStateStore();

export async function loadState(): Promise<PlatformState> {
  return store.load();
}

export async function saveState(state: PlatformState): Promise<void> {
  await store.save(state);
}

export function stateInfo(): Record<string, string | number | boolean | undefined> {
  return store.info();
}
