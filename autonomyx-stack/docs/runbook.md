# Autonomyx Operator Runbook

This runbook binds the Autonomyx OAM stack from source to cluster.

## 1. Build controller

```bash
cd autonomyx-stack
npm install
npm run build
docker build -t ghcr.io/agennext/autonomyx-controller:0.1.0 .
```

## 2. Certify artifact before publication

The current Certification verifier requires:

- `subject`
- `provenance.source`
- `provenance.digest` beginning with `sha256:`
- `provenance.sbomRef`
- `provenance.signatureRef`
- `validFrom`
- `validUntil`

Example:

```yaml
apiVersion: autonomyx.io/v1alpha1
kind: Certification
metadata:
  name: autonomyx-stack-v0-1
spec:
  domain: platform
  subject: ghcr.io/agennext/autonomyx-controller:0.1.0
  provenance:
    source: AGenNext/Agent-Platform
    digest: sha256:REPLACE
    sbomRef: sbom:REPLACE
    signatureRef: cosign:REPLACE
    slsaLevel: build-l1
  validFrom: "2026-06-24T00:00:00+05:30"
  validUntil: "2026-12-24T00:00:00+05:30"
```

## 3. Bind webhook TLS

`deploy/webhook.yaml` contains `REPLACE_WITH_CA_BUNDLE`.

Production binding options:

1. cert-manager issued serving certificate.
2. SPIRE/SPIFFE workload SVID converted for webhook serving cert flow.
3. Manually generated cluster-local CA for first bootstrap only.

The controller deployment must mount the serving certificate before using the Kubernetes webhook in production. The current local server is HTTP-first for scaffold testing.

## 4. Apply stack

```bash
kubectl apply -k deploy/
```

## 5. Validate health

```bash
kubectl -n autonomyx-system get deploy autonomyx-controller
kubectl -n autonomyx-system get svc autonomyx-controller
```

For local dev:

```bash
npm run controller:dev
curl http://localhost:8443/healthz
```

## 6. Admission contract

Every admission decision performs:

```text
headers/body
  -> identity extraction
  -> domain resolution
  -> trust score
  -> policy evaluation
  -> CRD reconciliation
  -> status patch
  -> telemetry event
```

## 7. Break-glass policy

Deletes are denied by policy scaffold with:

```text
DELETE_REQUIRES_EXPLICIT_BREAK_GLASS_POLICY
```

Add a separate break-glass CRD/policy before allowing delete paths.

## 8. Next hardening

- Real OPA bundle runtime instead of TypeScript mirror.
- SPIFFE Workload API integration.
- OpenTelemetry SDK exporter.
- Sigstore verification implementation.
- SLSA provenance parsing.
- Kubernetes watch/reconcile loop.
