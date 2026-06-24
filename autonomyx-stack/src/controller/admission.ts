import { admissionTelemetry } from "../observability/telemetry.js";
import { extractIdentity, type WorkloadIdentity } from "../security/identity.js";
import { evaluatePolicy, trustForIdentity } from "../security/policy.js";
import { reconcile, type KubernetesObject } from "./reconciler.js";

export type AdmissionReview = {
  request?: {
    uid: string;
    operation: "CREATE" | "UPDATE" | "DELETE" | "CONNECT";
    object?: KubernetesObject;
    userInfo?: Record<string, unknown>;
  };
};

export type AdmissionResponse = {
  apiVersion: "admission.k8s.io/v1";
  kind: "AdmissionReview";
  response: {
    uid: string;
    allowed: boolean;
    status?: { message: string };
    patchType?: "JSONPatch";
    patch?: string;
  };
};

export function admit(
  review: AdmissionReview,
  headers: Record<string, string | string[] | undefined> = {}
): AdmissionResponse {
  const uid = review.request?.uid ?? "unknown";
  const object = review.request?.object;
  const identity = extractIdentity(headers, review as unknown as Record<string, unknown>);

  if (!object) {
    return deny(uid, "Admission object missing", identity);
  }

  const domain = resolveDomain(object);
  const trustScore = trustForIdentity(identity.id);
  const policy = evaluatePolicy({
    identity,
    domain,
    trustScore,
    resourceKind: object.kind,
    operation: review.request?.operation,
    certified: Boolean(object.spec?.certificationRef),
  });

  if (!policy.allow) {
    return deny(uid, policy.reasons.join(","), identity, object);
  }

  const decision = reconcile(object);
  if (decision.phase === "Rejected") {
    return deny(uid, decision.reason ?? "Rejected by Autonomyx gate", identity, object);
  }

  const patches = [
    ...decision.patches,
    { op: "add" as const, path: "/metadata/annotations/autonomyx.io~1identity", value: identity.id },
    { op: "add" as const, path: "/metadata/annotations/autonomyx.io~1trust-score", value: String(trustScore) },
    { op: "add" as const, path: "/metadata/annotations/autonomyx.io~1rebase", value: new Date().toISOString() },
  ];

  const patch = Buffer.from(JSON.stringify(patches)).toString("base64");
  admissionTelemetry({
    uid,
    kind: object.kind,
    name: object.metadata.name,
    namespace: object.metadata.namespace,
    allowed: true,
  });

  return {
    apiVersion: "admission.k8s.io/v1",
    kind: "AdmissionReview",
    response: {
      uid,
      allowed: true,
      patchType: "JSONPatch",
      patch,
    },
  };
}

function deny(
  uid: string,
  message: string,
  identity?: WorkloadIdentity,
  object?: KubernetesObject
): AdmissionResponse {
  admissionTelemetry({
    uid,
    kind: object?.kind,
    name: object?.metadata.name,
    namespace: object?.metadata.namespace,
    allowed: false,
    reason: message,
  });

  return {
    apiVersion: "admission.k8s.io/v1",
    kind: "AdmissionReview",
    response: {
      uid,
      allowed: false,
      status: { message: `${message}${identity ? ` identity=${identity.id}` : ""}` },
    },
  };
}

function resolveDomain(object: KubernetesObject): string {
  const specDomain = object.spec?.domain;
  if (typeof specDomain === "string" && specDomain.length > 0) return specDomain;
  const metadataDomain = object.metadata.namespace;
  if (metadataDomain) return metadataDomain;
  return "blocked";
}
