import { listApplications, runPlatform, initialState } from "./platform.js";
import type { ExecutionRequest } from "./types.js";

const state = initialState();

console.log("Autonomyx OAM Stack Apps");
console.table(listApplications());

const request: ExecutionRequest = {
  id: `req:${Date.now()}`,
  domain: "platform",
  identity: {
    id: "user:001",
    issuer: "local",
    subject: "operator",
    claims: { role: "platform-operator" },
  },
  op: "⊕",
  payload: {
    "@id": "publication:autonomyx-stack-v0.1",
    "@type": "AutonomyxPublication",
    title: "Autonomyx OAM Stack v0.1",
    immutable: true,
  },
};

const next = runPlatform(request, state);
console.log(JSON.stringify({ graphVersion: next.graph.version, lastAudit: next.audit.at(-1) }, null, 2));
