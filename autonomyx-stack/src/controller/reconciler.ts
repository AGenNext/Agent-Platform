import { verifyCertification } from "../security/certification.js";

export type KubernetesObject = {
  apiVersion: string;
  kind: string;
  metadata: {
    name: string;
    namespace?: string;
    generation?: number;
  };
  spec?: Record<string, unknown>;
  status?: Record<string, unknown>;
};

export type ReconcileDecision = {
  phase: "Accepted" | "Rejected" | "Certified" | "Published" | "Pending";
  certified?: boolean;
  reason?: string;
  patches: Array<{ op: "add" | "replace"; path: string; value: unknown }>;
};

export function reconcile(object: KubernetesObject): ReconcileDecision {
  switch (object.kind) {
    case "AutonomyxManifest":
      return reconcileManifest(object);
    case "Domain":
      return reconcileDomain(object);
    case "Gate":
      return reconcileGate(object);
    case "Publication":
      return reconcilePublication(object);
    case "Certification":
      return reconcileCertification(object);
    default:
      return reject(`Unsupported kind: ${object.kind}`);
  }
}

function reconcileManifest(object: KubernetesObject): ReconcileDecision {
  const domain = object.spec?.domain;
  const apps = object.spec?.apps;
  if (typeof domain !== "string" || domain.length === 0) return reject("Manifest requires spec.domain");
  if (!Array.isArray(apps) || apps.length === 0) return reject("Manifest requires at least one app");
  return accept("Accepted", true);
}

function reconcileDomain(object: KubernetesObject): ReconcileDecision {
  if (!object.spec?.name) return reject("Domain requires spec.name");
  if (!object.spec?.scope) return reject("Domain requires spec.scope");
  return accept("Accepted", object.spec.status === "verified");
}

function reconcileGate(object: KubernetesObject): ReconcileDecision {
  if (!object.spec?.domain) return reject("Gate requires spec.domain");
  if (object.spec.mode !== "deny-by-default") return reject("Gate mode must be deny-by-default");
  return accept("Accepted", false);
}

function reconcilePublication(object: KubernetesObject): ReconcileDecision {
  if (!object.spec?.domain) return reject("Publication requires spec.domain");
  if (!object.spec?.artifact) return reject("Publication requires spec.artifact");
  if (object.spec.immutable !== true) return reject("Publication must be immutable");
  if (!object.spec.certificationRef) return reject("Publication requires spec.certificationRef");
  return accept("Published", true);
}

function reconcileCertification(object: KubernetesObject): ReconcileDecision {
  const decision = verifyCertification({
    subject: String(object.spec?.subject ?? ""),
    provenance: object.spec?.provenance as Parameters<typeof verifyCertification>[0]["provenance"],
    validFrom: typeof object.spec?.validFrom === "string" ? object.spec.validFrom : undefined,
    validUntil: typeof object.spec?.validUntil === "string" ? object.spec.validUntil : undefined,
  });

  if (!object.spec?.domain) return reject("Certification requires spec.domain");
  if (!decision.certified) return reject(decision.reasons.join(","));

  return {
    phase: "Certified",
    certified: true,
    patches: [
      { op: "add", path: "/status/phase", value: "Certified" },
      { op: "add", path: "/status/certified", value: true },
      { op: "add", path: "/status/trustScore", value: decision.trustScore },
    ],
  };
}

function accept(phase: ReconcileDecision["phase"], certified: boolean): ReconcileDecision {
  return {
    phase,
    certified,
    patches: [
      { op: "add", path: "/status/phase", value: phase },
      { op: "add", path: "/status/certified", value: certified },
    ],
  };
}

function reject(reason: string): ReconcileDecision {
  return {
    phase: "Rejected",
    certified: false,
    reason,
    patches: [
      { op: "add", path: "/status/phase", value: "Rejected" },
      { op: "add", path: "/status/certified", value: false },
      { op: "add", path: "/status/message", value: reason },
    ],
  };
}
