export type WorkloadIdentity = {
  id: string;
  issuer: "spiffe" | "oidc" | "kubernetes" | "unknown";
  subject: string;
  domain?: string;
  raw?: Record<string, unknown>;
};

export function extractIdentity(headers: Record<string, string | string[] | undefined>, body?: Record<string, unknown>): WorkloadIdentity {
  const spiffeId = header(headers, "x-spiffe-id");
  if (spiffeId) {
    return {
      id: spiffeId,
      issuer: "spiffe",
      subject: spiffeId,
      domain: header(headers, "x-autonomyx-domain"),
      raw: { headers: safeHeaders(headers), body },
    };
  }

  const oidcSubject = header(headers, "x-oidc-subject") ?? header(headers, "x-forwarded-user");
  if (oidcSubject) {
    return {
      id: `oidc:${oidcSubject}`,
      issuer: "oidc",
      subject: oidcSubject,
      domain: header(headers, "x-autonomyx-domain"),
      raw: { headers: safeHeaders(headers), body },
    };
  }

  const k8sUser = String((body?.request as Record<string, unknown> | undefined)?.userInfo ?? "");
  if (k8sUser && k8sUser !== "[object Object]") {
    return {
      id: `kubernetes:${k8sUser}`,
      issuer: "kubernetes",
      subject: k8sUser,
      domain: header(headers, "x-autonomyx-domain"),
      raw: { headers: safeHeaders(headers), body },
    };
  }

  return {
    id: "unknown",
    issuer: "unknown",
    subject: "unknown",
    domain: header(headers, "x-autonomyx-domain"),
    raw: { headers: safeHeaders(headers), body },
  };
}

function header(headers: Record<string, string | string[] | undefined>, key: string): string | undefined {
  const lower = key.toLowerCase();
  const value = headers[lower] ?? headers[key];
  if (Array.isArray(value)) return value[0];
  return value;
}

function safeHeaders(headers: Record<string, string | string[] | undefined>): Record<string, string | string[] | undefined> {
  const copy = { ...headers };
  delete copy.authorization;
  delete copy.cookie;
  return copy;
}
