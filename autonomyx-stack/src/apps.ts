import type { AutonomyxApp } from "./types.js";

function app(
  name: string,
  tier: AutonomyxApp["tier"],
  domain: string,
  capabilities: AutonomyxApp["capabilities"],
  traits: string[] = ["domain-bound", "gate-enforced", "audited"]
): AutonomyxApp {
  return {
    name,
    tier,
    domain,
    oam: {
      component: name,
      traits,
      scopes: [domain],
      workflows: [`${name}:rebase`, `${name}:authorize`, `${name}:execute`, `${name}:audit`],
    },
    capabilities,
  };
}

export const foundationApps: AutonomyxApp[] = [
  app("autonomyx-domain", "foundation", "platform", [
    { name: "create-domain", method: "POST", path: "/domain", requires: ["identity", "policy"] },
    { name: "get-domain", method: "GET", path: "/domain/:id", requires: ["identity"] },
  ]),
  app("autonomyx-identity", "foundation", "platform", [
    { name: "resolve-identity", method: "POST", path: "/identity/resolve", requires: ["domain"] },
    { name: "bind-workload", method: "POST", path: "/identity/workload", requires: ["domain", "policy"] },
  ], ["spiffe", "oidc", "domain-bound", "audited"]),
  app("autonomyx-policy", "foundation", "platform", [
    { name: "evaluate-policy", method: "POST", path: "/policy/evaluate", requires: ["identity", "domain"] },
    { name: "publish-policy", method: "POST", path: "/policy", requires: ["certification"] },
  ], ["opa", "rego", "deny-by-default", "audited"]),
  app("autonomyx-graph", "foundation", "platform", [
    { name: "upsert-entity", method: "POST", path: "/graph/entity", requires: ["identity", "policy"] },
    { name: "query-graph", method: "GET", path: "/graph", requires: ["eligibility"] },
  ], ["json-ld", "schema-org", "single-state", "audited"]),
];

export const governanceApps: AutonomyxApp[] = [
  app("autonomyx-trust", "governance", "governance", [
    { name: "score-trust", method: "POST", path: "/trust/score", requires: ["identity", "graph", "audit"] },
  ], ["trust-score", "risk", "eligibility"]),
  app("autonomyx-certification", "governance", "governance", [
    { name: "certify-artifact", method: "POST", path: "/certify", requires: ["provenance", "signature"] },
    { name: "verify-provenance", method: "POST", path: "/verify", requires: ["artifact"] },
  ], ["slsa", "sigstore", "sbom", "provenance"]),
  app("autonomyx-audit", "governance", "governance", [
    { name: "append-event", method: "POST", path: "/audit/events", requires: ["identity", "domain"] },
    { name: "read-timeline", method: "GET", path: "/audit/timeline", requires: ["eligibility"] },
  ], ["opentelemetry", "temporal", "immutable"]),
];

export const runtimeApps: AutonomyxApp[] = [
  app("autonomyx-runtime", "runtime", "runtime", [
    { name: "execute", method: "POST", path: "/execute", requires: ["domain", "identity", "policy", "graph"] },
    { name: "run-workflow", method: "POST", path: "/workflow", requires: ["manifest"] },
  ], ["rebase", "kernel", "wasm-ready", "gate-enforced"]),
  app("autonomyx-publication", "runtime", "runtime", [
    { name: "publish", method: "POST", path: "/publish", requires: ["certification", "audit"] },
    { name: "version", method: "POST", path: "/version", requires: ["publication"] },
  ], ["immutable", "versioned", "time-bound"]),
  app("autonomyx-discovery", "runtime", "runtime", [
    { name: "discover", method: "GET", path: "/discover", requires: ["eligibility", "trust"] },
    { name: "catalog", method: "GET", path: "/catalog", requires: ["domain"] },
  ], ["eligibility-before-discovery", "catalog", "registry"]),
];

export const oamApps: AutonomyxApp[] = [
  app("autonomyx-oam", "oam", "platform", [
    { name: "render-component", method: "POST", path: "/oam/component", requires: ["manifest"] },
    { name: "bind-trait", method: "POST", path: "/oam/trait", requires: ["policy"] },
  ], ["component", "trait", "scope", "workflow"]),
  app("autonomyx-manifest", "oam", "platform", [
    { name: "validate-manifest", method: "POST", path: "/manifest/validate", requires: ["domain", "policy"] },
    { name: "emit-manifest", method: "POST", path: "/manifest", requires: ["certification"] },
  ], ["canonical-contract", "domain-bound", "certified"]),
];

export const experienceApps: AutonomyxApp[] = [
  app("autodesk", "experience", "workspace", [{ name: "open-workspace", method: "GET", path: "/desk", requires: ["identity", "domain"] }]),
  app("autobuilder", "experience", "workspace", [{ name: "build-app", method: "POST", path: "/builder/app", requires: ["oam", "manifest"] }]),
  app("autograph", "experience", "workspace", [{ name: "explore-graph", method: "GET", path: "/graph/explorer", requires: ["eligibility"] }]),
  app("autotrust", "experience", "workspace", [{ name: "view-trust", method: "GET", path: "/trust/center", requires: ["trust"] }]),
  app("autopolicy", "experience", "workspace", [{ name: "govern-policy", method: "POST", path: "/policy/center", requires: ["policy", "identity"] }]),
  app("autopublish", "experience", "workspace", [{ name: "release", method: "POST", path: "/publish/center", requires: ["certification"] }]),
  app("autocertify", "experience", "workspace", [{ name: "certify", method: "POST", path: "/certify/center", requires: ["audit", "provenance"] }]),
];

export const allApps: AutonomyxApp[] = [
  ...foundationApps,
  ...governanceApps,
  ...runtimeApps,
  ...oamApps,
  ...experienceApps,
];
