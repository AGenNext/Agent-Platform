import { allApps } from "./apps.js";
import { execute } from "./kernel.js";
import type { ExecutionRequest, PlatformState } from "./types.js";

export function initialState(): PlatformState {
  return {
    domains: [
      { id: "platform", name: "Platform", scope: "foundation", status: "verified" },
      { id: "governance", name: "Governance", scope: "governance", status: "verified" },
      { id: "runtime", name: "Runtime", scope: "runtime", status: "verified" },
      { id: "workspace", name: "Workspace", scope: "experience", status: "trusted" },
    ],
    graph: {
      nodes: allApps.map((app) => ({
        "@id": `app:${app.name}`,
        "@type": "AutonomyxOAMApplication",
        domain: app.domain,
        data: {
          name: app.name,
          tier: app.tier,
          oam: app.oam,
          capabilities: app.capabilities,
        },
        createdAt: new Date().toISOString(),
      })),
      edges: allApps.flatMap((app) =>
        app.capabilities.flatMap((capability) =>
          capability.requires.map((requirement) => ({
            from: `app:${app.name}`,
            to: `capability:${requirement}`,
            relation: "requires",
            domain: app.domain,
            weight: 1,
          }))
        )
      ),
      version: 1,
    },
    trust: {
      "identity:system": 1,
      "identity:operator": 0.9,
      "user:001": 0.9,
    },
    audit: [],
  };
}

export function runPlatform(request: ExecutionRequest, state: PlatformState = initialState()): PlatformState {
  const result = execute(state, request);
  return {
    ...state,
    graph: result.graph,
    audit: [...state.audit, result.auditEvent],
  };
}

export function listApplications() {
  return allApps.map((app) => ({
    name: app.name,
    tier: app.tier,
    domain: app.domain,
    capabilities: app.capabilities.map((capability) => capability.name),
  }));
}
