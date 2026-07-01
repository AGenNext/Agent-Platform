import type { AnyDataGraph } from "../types.js";
import { applyPlan } from "./apply.js";
import { diffGraph } from "./diff.js";
import { plan } from "./planner.js";
import type { KernelConstraint, KernelIntent, ReconcileResult } from "./types.js";
import { verifyPlan } from "./verifier.js";

export function reconcileIntent(graph: AnyDataGraph, intent: KernelIntent, constraints: KernelConstraint[] = []): ReconcileResult {
  const executionPlan = plan(intent);
  const verification = verifyPlan(graph, executionPlan, constraints);

  if (!verification.ok) {
    return {
      graph,
      diff: diffGraph(graph, graph),
      verification,
      plan: { ...executionPlan, status: "rejected" },
    };
  }

  const nextGraph = applyPlan(graph, executionPlan);
  return {
    graph: nextGraph,
    diff: diffGraph(graph, nextGraph),
    verification,
    plan: { ...executionPlan, status: "applied" },
  };
}

export * from "./types.js";
export * from "./planner.js";
export * from "./verifier.js";
export * from "./apply.js";
export * from "./diff.js";
