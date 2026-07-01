export type CertificationInput = {
  subject: string;
  provenance?: {
    source?: string;
    digest?: string;
    sbomRef?: string;
    signatureRef?: string;
    slsaLevel?: string;
  };
  validFrom?: string;
  validUntil?: string;
};

export type CertificationDecision = {
  certified: boolean;
  trustScore: number;
  reasons: string[];
};

export function verifyCertification(input: CertificationInput): CertificationDecision {
  const reasons: string[] = [];

  if (!input.subject) reasons.push("SUBJECT_REQUIRED");
  if (!input.provenance?.source) reasons.push("PROVENANCE_SOURCE_REQUIRED");
  if (!input.provenance?.digest) reasons.push("PROVENANCE_DIGEST_REQUIRED");
  if (!String(input.provenance?.digest ?? "").startsWith("sha256:")) reasons.push("DIGEST_MUST_BE_SHA256");
  if (!input.provenance?.sbomRef) reasons.push("SBOM_REFERENCE_REQUIRED");
  if (!input.provenance?.signatureRef) reasons.push("SIGNATURE_REFERENCE_REQUIRED");

  const now = Date.now();
  if (input.validFrom && Date.parse(input.validFrom) > now) reasons.push("CERTIFICATION_NOT_YET_VALID");
  if (input.validUntil && Date.parse(input.validUntil) < now) reasons.push("CERTIFICATION_EXPIRED");

  const certified = reasons.length === 0;
  return {
    certified,
    trustScore: certified ? 0.85 : 0.25,
    reasons,
  };
}
