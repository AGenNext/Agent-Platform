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

## Build

```bash
npm run build
npm start
```

## Key files

- `autonomyx.manifest.yaml` — canonical binding contract.
- `src/types.ts` — platform object model.
- `src/kernel.ts` — deterministic logical kernel.
- `src/apps.ts` — every stack component as an app.
- `src/platform.ts` — composition layer.
- `policy/gate.rego` — OPA gate policy.
- `docs/oam-mapping.md` — OAM-to-Autonomyx mapping.

## Current scope

This is a first-pass runnable scaffold. It is not yet a production control plane. Next steps are Kubernetes CRDs, OPA bundle integration, SPIFFE workload identity, OpenTelemetry instrumentation, and supply-chain certification wiring.
