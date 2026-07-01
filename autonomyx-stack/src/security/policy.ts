export type PolicyInput = {
  identity: { id: string; issuer?: string };
  domain: string;
  trustScore: number;
  resourceKind?: string;
  operation?: string;
  certified?: boolean;
};

export type PolicyDecision = {
  allow: boolean;
  reasons: string[];
};

export function evaluatePolicy(input: PolicyInput): PolicyDecision {
  const reasons: string[] = [];

  if (!input.identity?.id || input.identity.id === "unknown") reasons.push("IDENTITY_REQUIRED");
  if (!input.domain || input.domain === "blocked") reasons.push("DOMAIN_INVALID");
  if (input.trustScore < 0.5) reasons.push("TRUST_BELOW_THRESHOLD");

  if (input.resourceKind === "Publication" && input.certified !== true) {
    reasons.push("PUBLICATION_REQUIRES_CERTIFICATION");
  }

  if (input.operation === "DELETE") {
    reasons.push("DELETE_REQUIRES_EXPLICIT_BREAK_GLASS_POLICY");
  }

  return {
    allow: reasons.length === 0,
    reasons,
  };
}

export function trustForIdentity(identityId: string): number {
  if (identityId.startsWith("spiffe://")) return 0.9;
  if (identityId.startsWith("oidc:")) return 0.75;
  if (identityId.startsWith("kubernetes:")) return 0.65;
  if (identityId === "unknown") return 0;
  return 0.5;
}
