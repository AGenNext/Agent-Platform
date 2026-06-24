import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { initialState } from "../platform.js";
import type { PlatformState } from "../types.js";

const defaultStatePath = process.env.AUTONOMYX_STATE_FILE ?? "./data/autonomyx-state.json";

export function loadState(path = defaultStatePath): PlatformState {
  if (!existsSync(path)) {
    const state = initialState();
    saveState(state, path);
    return state;
  }

  const raw = readFileSync(path, "utf8");
  return JSON.parse(raw) as PlatformState;
}

export function saveState(state: PlatformState, path = defaultStatePath): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(state, null, 2));
}

export function statePath(): string {
  return defaultStatePath;
}
