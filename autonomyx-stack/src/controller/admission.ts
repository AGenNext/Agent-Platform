import { reconcile, type KubernetesObject } from "./reconciler.js";

export type AdmissionReview = {
  request?: {
    uid: string;
    operation: "CREATE" | "UPDATE" | "DELETE" | "CONNECT";
    object?: KubernetesObject;
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

export function admit(review: AdmissionReview): AdmissionResponse {
  const uid = review.request?.uid ?? "unknown";
  const object = review.request?.object;

  if (!object) {
    return deny(uid, "Admission object missing");
  }

  const decision = reconcile(object);
  if (decision.phase === "Rejected") {
    return deny(uid, decision.reason ?? "Rejected by Autonomyx gate");
  }

  const patch = Buffer.from(JSON.stringify(decision.patches)).toString("base64");
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

function deny(uid: string, message: string): AdmissionResponse {
  return {
    apiVersion: "admission.k8s.io/v1",
    kind: "AdmissionReview",
    response: {
      uid,
      allowed: false,
      status: { message },
    },
  };
}
