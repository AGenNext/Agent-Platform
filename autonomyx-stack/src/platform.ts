import { allApps } from "./apps.js";
import { execute } from "./kernel.js";
import { reconcileIntent } from "./logical-kernel/index.js";
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
  const gateResult = execute(state, request);
  if (gateResult.status !== "allowed") {
    return {
      ...state,
      audit: [...state.audit, gateResult.auditEvent],
    };
  }

  const reconciliation = reconcileIntent(state.graph, { request }, [
    { type: "domain-bound", domain: request.domain },
    { type: "no-cross-domain-edges" },
  ]);

  return {
    ...state,
    graph: reconciliation.graph,
    audit: [
      ...state.audit,
      {
        ...gateResult.auditEvent,
        graphVersion: reconciliation.graph.version,
        reason: reconciliation.verification.ok
          ? `plan=${reconciliation.plan.id};addedNodes=${reconciliation.diff.addedNodes.length};removedNodes=${reconciliation.diff.removedNodes.length}`
          : reconciliation.verification.findings.map((finding) => finding.code).join(","),
        status: reconciliation.verification.ok ? gateResult.auditEvent.status : "error",
      },
    ],
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
