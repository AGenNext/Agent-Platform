# Autonomyx Kubernetes Layer

This directory turns the Autonomyx OAM stack into Kubernetes-native resources.

## Resource kinds

- `AutonomyxManifest` — canonical binding contract for an app stack.
- `Domain` — hard execution, visibility, and trust boundary.
- `Gate` — deny-by-default policy enforcement object.
- `Publication` — immutable artifact publication record.
- `Certification` — provenance and supply-chain certification record.

## Install CRDs

```bash
kubectl apply -f deploy/crds/
```

## Install controller resources

```bash
kubectl apply -f deploy/rbac.yaml
kubectl apply -f deploy/controller.yaml
```

## Install webhook contract

The webhook file contains a placeholder CA bundle.

```bash
# replace REPLACE_WITH_CA_BUNDLE first
kubectl apply -f deploy/webhook.yaml
```

## Apply samples

```bash
kubectl apply -f deploy/samples/domain-platform.yaml
kubectl apply -f deploy/samples/gate-default.yaml
kubectl apply -f deploy/samples/certification-stack.yaml
kubectl apply -f deploy/samples/publication-stack.yaml
kubectl apply -f deploy/samples/manifest-stack.yaml
```

## Controller skeleton

The current controller code is in:

- `src/controller/reconciler.ts`
- `src/controller/admission.ts`

It does not yet run an HTTP server. The next implementation step is to expose `/admit`, verify TLS, and wire Kubernetes watches for each CRD.

## Invariant mapping

| Invariant | Kubernetes enforcement |
| --- | --- |
| Domain-bound execution | `Domain` CRD + required `spec.domain` on every object |
| Every application is a gate | `Gate` CRD + validating webhook |
| JIT access and authorization | Gate fields `jitAccess` and `jitAuthorization` |
| Immutable publication | `Publication.spec.immutable == true` |
| Supply-chain certification | `Certification` CRD with provenance digest |
| Canonical manifest | `AutonomyxManifest` CRD |

## Next hardening

1. Add controller-runtime or lightweight HTTP server.
2. Add OPA bundle evaluation for `policy/gate.rego`.
3. Add SPIFFE/SPIRE identity extraction for admission requests.
4. Add OpenTelemetry spans for every reconcile/admission decision.
5. Add Sigstore/SLSA/SBOM verifier integration for `Certification`.
