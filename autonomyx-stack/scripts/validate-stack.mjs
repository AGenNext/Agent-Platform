import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const required = [
  "autonomyx.manifest.yaml",
  "bindings/autonomyx.stack.binding.yaml",
  "deploy/kustomization.yaml",
  "deploy/crds/autonomyx.io_autonomyxmanifests.yaml",
  "deploy/crds/autonomyx.io_domains.yaml",
  "deploy/crds/autonomyx.io_gates.yaml",
  "deploy/crds/autonomyx.io_publications.yaml",
  "deploy/crds/autonomyx.io_certifications.yaml",
  "deploy/rbac.yaml",
  "deploy/controller.yaml",
  "deploy/mvp.yaml",
  "deploy/webhook.yaml",
  "policy/gate.rego",
  "src/controller/server.ts",
  "src/controller/admission.ts",
  "src/controller/reconciler.ts",
  "src/mvp/server.ts",
  "src/mvp/html.ts",
  "src/mvp/store.ts",
  "src/mvp/auth.ts",
  "src/mvp/storage/types.ts",
  "src/mvp/storage/index.ts",
  "src/mvp/storage/json-store.ts",
  "src/mvp/storage/surreal-store.ts",
  "src/security/identity.ts",
  "src/security/policy.ts",
  "src/security/certification.ts",
  "src/observability/telemetry.ts",
];

const missing = required.filter((file) => !fs.existsSync(path.join(root, file)));
if (missing.length > 0) {
  console.error("Autonomyx stack validation failed. Missing files:");
  for (const file of missing) console.error(`- ${file}`);
  process.exit(1);
}

const manifest = fs.readFileSync(path.join(root, "autonomyx.manifest.yaml"), "utf8");
for (const invariant of [
  "rebaseAtEverySurface",
  "eligibilityBeforeDiscovery",
  "jitAccess",
  "jitAuthorization",
  "immutablePublication",
  "everyApplicationIsGate",
]) {
  if (!manifest.includes(invariant)) {
    console.error(`Autonomyx manifest missing invariant: ${invariant}`);
    process.exit(1);
  }
}

const binding = fs.readFileSync(path.join(root, "bindings/autonomyx.stack.binding.yaml"), "utf8");
for (const bindingKey of ["domainBindings", "appBindings", "everyResourceHasDomain", "everyPublicationRequiresCertification"]) {
  if (!binding.includes(bindingKey)) {
    console.error(`Autonomyx binding missing: ${bindingKey}`);
    process.exit(1);
  }
}

const mvp = fs.readFileSync(path.join(root, "src/mvp/server.ts"), "utf8");
for (const route of ["/api/apps", "/api/state", "/api/audit", "/api/execute", "/api/reset", "/api/manifest", "/api/binding"]) {
  if (!mvp.includes(route)) {
    console.error(`MVP server missing route: ${route}`);
    process.exit(1);
  }
}

const deployment = fs.readFileSync(path.join(root, "deploy/mvp.yaml"), "utf8");
for (const token of ["PersistentVolumeClaim", "AUTONOMYX_STATE_PROVIDER", "AUTONOMYX_STATE_FILE", "AUTONOMYX_MVP_TOKEN", "SURREALDB_ENDPOINT"]) {
  if (!deployment.includes(token)) {
    console.error(`MVP deployment missing persistence/auth/storage token: ${token}`);
    process.exit(1);
  }
}

console.log("Autonomyx stack validation passed.");
