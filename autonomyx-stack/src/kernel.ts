import type {
  AnyDataGraph,
  AuditEvent,
  ExecutionRequest,
  ExecutionResult,
  GraphNode,
  PlatformState,
} from "./types.js";

export function rebase(state: PlatformState, request: ExecutionRequest): PlatformState {
  const domain = state.domains.find((item) => item.id === request.domain);
  if (!domain) {
    throw new Error(`Domain not found: ${request.domain}`);
  }
  return structuredClone(state);
}

export function gate(state: PlatformState, request: ExecutionRequest): { allow: boolean; reason?: string } {
  const domain = state.domains.find((item) => item.id === request.domain);
  if (!domain) return { allow: false, reason: "DOMAIN_NOT_FOUND" };
  if (domain.status === "suspended") return { allow: false, reason: "DOMAIN_SUSPENDED" };
  if (!request.identity?.id) return { allow: false, reason: "IDENTITY_REQUIRED" };

  const trustScore = state.trust[request.identity.id] ?? 0;
  if (trustScore < 0.5) return { allow: false, reason: "TRUST_BELOW_THRESHOLD" };

  return { allow: true };
}

export function arithmetic(graph: AnyDataGraph, request: ExecutionRequest): AnyDataGraph {
  const next = structuredClone(graph);

  switch (request.op) {
    case "⊕": {
      const node: GraphNode = {
        "@id": String(request.payload["@id"] ?? `node:${request.id}`),
        "@type": String(request.payload["@type"] ?? "AutonomyxArtifact"),
        domain: request.domain,
        data: request.payload,
        createdAt: new Date().toISOString(),
      };
      next.nodes.push(node);
      next.version += 1;
      return next;
    }

    case "⊖": {
      const target = request.target ?? String(request.payload["@id"] ?? "");
      next.nodes = next.nodes.filter((node) => node["@id"] !== target || node.domain !== request.domain);
      next.edges = next.edges.filter((edge) => edge.from !== target && edge.to !== target);
      next.version += 1;
      return next;
    }

    case "⊗": {
      const target = request.target ?? String(request.payload["@id"] ?? "");
      const factor = Number(request.payload.factor ?? 1);
      next.edges = next.edges.map((edge) => {
        if (edge.domain !== request.domain) return edge;
        if (target && edge.from !== target && edge.to !== target) return edge;
        return { ...edge, weight: (edge.weight ?? 1) * factor };
      });
      next.version += 1;
      return next;
    }

    case "÷": {
      const scope = String(request.payload.scope ?? request.domain);
      next.nodes.push({
        "@id": `scope:${request.domain}:${scope}`,
        "@type": "AutonomyxDomainScope",
        domain: request.domain,
        data: { scope, source: request.id },
        createdAt: new Date().toISOString(),
      });
      next.version += 1;
      return next;
    }
  }
}

export function auditEvent(request: ExecutionRequest, status: AuditEvent["status"], graphVersion: number, reason?: string): AuditEvent {
  return {
    id: `audit:${request.id}`,
    requestId: request.id,
    identity: request.identity.id,
    domain: request.domain,
    op: request.op,
    status,
    reason,
    graphVersion,
    timestamp: new Date().toISOString(),
  };
}

export function execute(state: PlatformState, request: ExecutionRequest): ExecutionResult {
  let rebased: PlatformState;
  try {
    rebased = rebase(state, request);
  } catch (error) {
    const reason = error instanceof Error ? error.message : "REBASE_FAILED";
    const auditEventResult = auditEvent(request, "error", state.graph.version, reason);
    return { status: "error", reason, graph: state.graph, auditEvent: auditEventResult };
  }

  const decision = gate(rebased, request);
  if (!decision.allow) {
    const auditEventResult = auditEvent(request, "denied", rebased.graph.version, decision.reason);
    return { status: "denied", reason: decision.reason, graph: rebased.graph, auditEvent: auditEventResult };
  }

  const graph = arithmetic(rebased.graph, request);
  const auditEventResult = auditEvent(request, "allowed", graph.version);
  return { status: "allowed", graph, auditEvent: auditEventResult };
}
