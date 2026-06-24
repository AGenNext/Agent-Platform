# Autonomyx OAM Stack

Autonomyx is implemented here as an **Open Application Governance Platform**: every capability is modeled as an OAM-style application, every application is a gate, and every execution is domain-bound, policy-governed, graph-backed, audited, and certifiable.

## Canonical position

Autonomyx does not replace Kubernetes, OAM, SPIFFE, OPA, OpenTelemetry, SLSA, or Sigstore. It composes them into a governed execution fabric.

## Stack apps

### Foundation

- `autonomyx-domain`
- `autonomyx-identity`
- `autonomyx-policy`
- `autonomyx-graph`

### Governance

- `autonomyx-trust`
- `autonomyx-certification`
- `autonomyx-audit`

### Runtime

- `autonomyx-runtime`
- `autonomyx-publication`
- `autonomyx-discovery`

### OAM

- `autonomyx-oam`
- `autonomyx-manifest`

### Experience

- `autodesk`
- `autobuilder`
- `autograph`
- `autotrust`
- `autopolicy`
- `autopublish`
- `autocertify`

## Runtime law

```text
Surface request
  -> rebase
  -> domain resolution
  -> gate decision
  -> graph arithmetic
  -> audit
  -> certification-ready record
```

## Run locally

```bash
cd autonomyx-stack
npm install
npm run dev
```

## Run the admission controller locally

```bash
cd autonomyx-stack
npm install
npm run controller:dev
curl http://localhost:8443/healthz
```

The controller exposes:

- `GET /healthz`
- `POST /admit`

## Build

```bash
npm run build
npm start
npm run controller:start
```

## Build controller image

```bash
docker build -t ghcr.io/agennext/autonomyx-controller:0.1.0 .
```

## Apply the bound Kubernetes stack

```bash
kubectl apply -k deploy/
```

## Binding

The stack is bound in two places:

- `deploy/kustomization.yaml` binds Kubernetes resources into one apply unit.
- `bindings/autonomyx.stack.binding.yaml` binds OAM apps to domains, gates, policy, publication, and certification.

## Key files

- `autonomyx.manifest.yaml` — canonical binding contract.
- `bindings/autonomyx.stack.binding.yaml` — app/domain/gate/certification binding.
- `src/types.ts` — platform object model.
- `src/kernel.ts` — deterministic logical kernel.
- `src/apps.ts` — every stack component as an app.
- `src/platform.ts` — composition layer.
- `src/controller/server.ts` — HTTP admission server.
- `src/controller/admission.ts` — AdmissionReview decision adapter.
- `src/controller/reconciler.ts` — CRD reconcile rules.
- `policy/gate.rego` — OPA gate policy.
- `docs/oam-mapping.md` — OAM-to-Autonomyx mapping.
- `docs/kubernetes.md` — Kubernetes install guide.

## Current scope

This is now a runnable TypeScript scaffold plus a Kubernetes-native resource model and admission endpoint. It is not yet a production-grade controller image with TLS automation, live Kubernetes watches, SPIFFE extraction, OPA bundle runtime, OpenTelemetry export, or Sigstore/SLSA verification.
