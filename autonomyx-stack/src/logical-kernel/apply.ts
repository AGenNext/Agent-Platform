import type { AnyDataGraph, GraphEdge } from "../types.js";
import type { ExecutionPlan, GraphPatch } from "./types.js";

export function applyPlan(graph: AnyDataGraph, plan: ExecutionPlan): AnyDataGraph {
  let next = structuredClone(graph);

  for (const step of orderedSteps(plan)) {
    next = applyPatch(next, step.patch);
  }

  return { ...next, version: graph.version + 1 };
}

function orderedSteps(plan: ExecutionPlan) {
  const steps = [...plan.steps];
  return steps.sort((a, b) => a.dependsOn.length - b.dependsOn.length || a.id.localeCompare(b.id));
}

export function applyPatch(graph: AnyDataGraph, patch: GraphPatch): AnyDataGraph {
  const next = structuredClone(graph);

  switch (patch.op) {
    case "add-node":
    case "add-scope": {
      next.nodes = next.nodes.filter((node) => node["@id"] !== patch.node["@id"]);
      next.nodes.push(patch.node);
      return next;
    }
    case "remove-node": {
      next.nodes = next.nodes.filter((node) => node["@id"] !== patch.id || node.domain !== patch.domain);
      next.edges = next.edges.filter((edge) => edge.from !== patch.id && edge.to !== patch.id);
      return next;
    }
    case "add-edge": {
      next.edges.push(patch.edge);
      return next;
    }
    case "remove-edge": {
      next.edges = next.edges.filter((edge) => !edgeMatches(edge, patch.from, patch.to, patch.relation));
      return next;
    }
    case "update-edge-weight": {
      next.edges = next.edges.map((edge) => {
        if (!edgeMatches(edge, patch.from, patch.to, patch.relation)) return edge;
        return { ...edge, weight: (edge.weight ?? 1) * patch.weight };
      });
      return next;
    }
  }
}

function edgeMatches(edge: GraphEdge, from: string, to: string, relation?: string): boolean {
  const fromMatches = from === "*" || edge.from === from;
  const toMatches = to === "*" || edge.to === to;
  const relationMatches = !relation || edge.relation === relation;
  return fromMatches && toMatches && relationMatches;
}
