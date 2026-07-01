import type { GraphNode } from "../types.js";
import type { ExecutionPlan, ExecutionStep, KernelIntent } from "./types.js";

export function plan(intent: KernelIntent): ExecutionPlan {
  const { request } = intent;
  const now = new Date().toISOString();
  const base = {
    id: `plan:${request.id}`,
    requestId: request.id,
    domain: request.domain,
    status: "planned" as const,
    createdAt: now,
  };

  switch (request.op) {
    case "⊕":
      return {
        ...base,
        steps: [addNodeStep(request.id, request.domain, request.payload, now)],
      };
    case "⊖":
      return {
        ...base,
        steps: [
          {
            id: `step:${request.id}:remove-node`,
            mode: "sequential",
            dependsOn: [],
            patch: { op: "remove-node", id: request.target ?? String(request.payload["@id"] ?? ""), domain: request.domain },
            reason: "Remove a domain-bound node and its dependent edges.",
          },
        ],
      };
    case "⊗":
      return {
        ...base,
        steps: [
          {
            id: `step:${request.id}:weight-edges`,
            mode: "parallel",
            dependsOn: [],
            patch: {
              op: "update-edge-weight",
              from: String(request.payload.from ?? request.target ?? "*"),
              to: String(request.payload.to ?? "*"),
              relation: typeof request.payload.relation === "string" ? request.payload.relation : undefined,
              weight: Number(request.payload.factor ?? request.payload.weight ?? 1),
            },
            reason: "Apply a multiplicative graph weight transformation.",
          },
        ],
      };
    case "÷": {
      const scope = String(request.payload.scope ?? request.domain);
      const node: GraphNode = {
        "@id": `scope:${request.domain}:${scope}`,
        "@type": "AutonomyxDomainScope",
        domain: request.domain,
        data: { scope, source: request.id },
        createdAt: now,
      };
      return {
        ...base,
        steps: [
          {
            id: `step:${request.id}:add-scope`,
            mode: "sequential",
            dependsOn: [],
            patch: { op: "add-scope", node },
            reason: "Create an explicit domain scope boundary.",
          },
        ],
      };
    }
  }
}

function addNodeStep(requestId: string, domain: string, payload: Record<string, unknown>, createdAt: string): ExecutionStep {
  const node: GraphNode = {
    "@id": String(payload["@id"] ?? `node:${requestId}`),
    "@type": String(payload["@type"] ?? "AutonomyxArtifact"),
    domain,
    data: payload,
    createdAt,
  };

  return {
    id: `step:${requestId}:add-node`,
    mode: "sequential",
    dependsOn: [],
    patch: { op: "add-node", node },
    reason: "Add a domain-bound graph node.",
  };
}
