import type { AnyDataGraph } from "../types.js";
import type { ExecutionPlan, KernelConstraint, VerificationFinding, VerificationResult } from "./types.js";

export function verifyPlan(graph: AnyDataGraph, plan: ExecutionPlan, constraints: KernelConstraint[] = []): VerificationResult {
  const findings: VerificationFinding[] = [];

  if (!plan.domain) {
    findings.push({ level: "error", code: "DOMAIN_REQUIRED", message: "Execution plan must be domain-bound." });
  }

  for (const step of plan.steps) {
    for (const dependency of step.dependsOn) {
      if (!plan.steps.some((candidate) => candidate.id === dependency)) {
        findings.push({ level: "error", code: "UNKNOWN_DEPENDENCY", message: `Step dependency not found: ${dependency}`, stepId: step.id });
      }
    }

    if (step.patch.op === "add-node" || step.patch.op === "add-scope") {
      if (step.patch.node.domain !== plan.domain) {
        findings.push({ level: "error", code: "CROSS_DOMAIN_NODE", message: "Node patch domain must match plan domain.", stepId: step.id });
      }
    }

    if (step.patch.op === "add-edge" && step.patch.edge.domain !== plan.domain) {
      findings.push({ level: "error", code: "CROSS_DOMAIN_EDGE", message: "Edge patch domain must match plan domain.", stepId: step.id });
    }
  }

  for (const constraint of constraints) {
    switch (constraint.type) {
      case "domain-bound":
        if (plan.domain !== constraint.domain) {
          findings.push({ level: "error", code: "DOMAIN_MISMATCH", message: `Expected domain ${constraint.domain} but got ${plan.domain}.` });
        }
        break;
      case "requires-target":
        if (!plan.steps.some((step) => "id" in step.patch || "from" in step.patch)) {
          findings.push({ level: "error", code: "TARGET_REQUIRED", message: "Operation requires a target." });
        }
        break;
      case "requires-certification":
        findings.push({ level: "warning", code: "CERTIFICATION_NOT_EVALUATED", message: "Certification constraint is declared but not yet bound to verifier input." });
        break;
      case "max-node-count":
        if (graph.nodes.length > constraint.count) {
          findings.push({ level: "error", code: "MAX_NODE_COUNT_EXCEEDED", message: `Graph node count exceeds ${constraint.count}.` });
        }
        break;
      case "no-cross-domain-edges":
        for (const edge of graph.edges) {
          const from = graph.nodes.find((node) => node["@id"] === edge.from);
          const to = graph.nodes.find((node) => node["@id"] === edge.to);
          if (from && to && from.domain !== to.domain) {
            findings.push({ level: "error", code: "CROSS_DOMAIN_EDGE_PRESENT", message: `Cross-domain edge found: ${edge.from} -> ${edge.to}` });
          }
        }
        break;
    }
  }

  return {
    ok: !findings.some((finding) => finding.level === "error"),
    findings,
  };
}
