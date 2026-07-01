import type { AnyDataGraph, ExecutionRequest, GraphEdge, GraphNode } from "../types.js";

export type ExecutionMode = "sequential" | "parallel";
export type PlanStatus = "planned" | "verified" | "rejected" | "applied";

export type KernelIntent = {
  request: ExecutionRequest;
  description?: string;
  constraints?: KernelConstraint[];
};

export type KernelConstraint =
  | { type: "domain-bound"; domain: string }
  | { type: "requires-target" }
  | { type: "requires-certification" }
  | { type: "max-node-count"; count: number }
  | { type: "no-cross-domain-edges" };

export type GraphPatch =
  | { op: "add-node"; node: GraphNode }
  | { op: "remove-node"; id: string; domain: string }
  | { op: "add-edge"; edge: GraphEdge }
  | { op: "remove-edge"; from: string; to: string; relation?: string }
  | { op: "update-edge-weight"; from: string; to: string; relation?: string; weight: number }
  | { op: "add-scope"; node: GraphNode };

export type ExecutionStep = {
  id: string;
  mode: ExecutionMode;
  dependsOn: string[];
  patch: GraphPatch;
  reason: string;
};

export type ExecutionPlan = {
  id: string;
  requestId: string;
  domain: string;
  status: PlanStatus;
  steps: ExecutionStep[];
  createdAt: string;
};

export type VerificationFinding = {
  level: "error" | "warning";
  code: string;
  message: string;
  stepId?: string;
};

export type VerificationResult = {
  ok: boolean;
  findings: VerificationFinding[];
};

export type GraphDiff = {
  fromVersion: number;
  toVersion: number;
  addedNodes: GraphNode[];
  removedNodes: GraphNode[];
  addedEdges: GraphEdge[];
  removedEdges: GraphEdge[];
  updatedEdges: Array<{ before: GraphEdge; after: GraphEdge }>;
};

export type ReconcileResult = {
  graph: AnyDataGraph;
  diff: GraphDiff;
  verification: VerificationResult;
  plan: ExecutionPlan;
};
