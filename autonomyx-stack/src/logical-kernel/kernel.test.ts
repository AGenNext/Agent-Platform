import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { initialState } from "../platform.js";
import type { ExecutionRequest } from "../types.js";
import { reconcileIntent } from "./index.js";

function request(op: ExecutionRequest["op"], payload: Record<string, unknown> = {}): ExecutionRequest {
  return {
    id: `req:test:${op}`,
    domain: "platform",
    identity: {
      id: "user:001",
      issuer: "local",
      subject: "operator",
      claims: {},
    },
    op,
    payload,
  };
}

describe("logical kernel", () => {
  it("plans, verifies, applies and diffs node addition", () => {
    const state = initialState();
    const result = reconcileIntent(state.graph, {
      request: request("⊕", {
        "@id": "test:node",
        "@type": "AutonomyxTestNode",
        title: "Test Node",
      }),
    }, [{ type: "domain-bound", domain: "platform" }]);

    assert.equal(result.verification.ok, true);
    assert.equal(result.plan.status, "applied");
    assert.equal(result.diff.addedNodes.length, 1);
    assert.equal(result.graph.nodes.some((node) => node["@id"] === "test:node"), true);
  });

  it("rejects cross-domain plans", () => {
    const state = initialState();
    const result = reconcileIntent(state.graph, {
      request: request("⊕", {
        "@id": "test:bad-domain",
        "@type": "AutonomyxTestNode",
      }),
    }, [{ type: "domain-bound", domain: "governance" }]);

    assert.equal(result.verification.ok, false);
    assert.equal(result.plan.status, "rejected");
    assert.equal(result.diff.addedNodes.length, 0);
  });
});
