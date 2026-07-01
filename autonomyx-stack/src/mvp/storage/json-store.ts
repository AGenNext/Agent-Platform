import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { initialState } from "../../platform.js";
import type { PlatformState } from "../../types.js";
import type { StateStore } from "./types.js";

export class JsonStateStore implements StateStore {
  readonly name = "json" as const;

  constructor(private readonly path: string) {}

  async load(): Promise<PlatformState> {
    if (!existsSync(this.path)) {
      const state = initialState();
      await this.save(state);
      return state;
    }

    const raw = readFileSync(this.path, "utf8");
    return JSON.parse(raw) as PlatformState;
  }

  async save(state: PlatformState): Promise<void> {
    mkdirSync(dirname(this.path), { recursive: true });
    writeFileSync(this.path, JSON.stringify(state, null, 2));
  }

  info(): Record<string, string | number | boolean | undefined> {
    return {
      provider: this.name,
      path: this.path,
    };
  }
}
