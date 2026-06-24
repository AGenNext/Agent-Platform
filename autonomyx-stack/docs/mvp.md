# Autonomyx MVP

The MVP is a usable control-plane surface for the Autonomyx OAM stack.

## What it provides

- Browser operator UI at `/`
- Health endpoint at `/healthz`
- App registry endpoint at `/api/apps`
- State endpoint at `/api/state`
- Audit endpoint at `/api/audit`
- Manifest endpoint at `/api/manifest`
- Binding endpoint at `/api/binding`
- Execution endpoint at `/api/execute`
- Reset endpoint at `/api/reset`
- Admission endpoint at `/admit`
- File-backed state persistence
- Optional bearer-token write protection

## Run locally

```bash
cd autonomyx-stack
npm install
npm run mvp:dev
```

Open:

```text
http://localhost:8080
```

## Run locally with token protection

```bash
AUTONOMYX_MVP_TOKEN=change-me npm run mvp:dev
```

Write requests must include:

```text
Authorization: Bearer change-me
```

## Execute through API

```bash
curl -X POST http://localhost:8080/api/execute \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer change-me' \
  -H 'x-oidc-subject: mvp-operator' \
  --data '{
    "domain": "platform",
    "op": "⊕",
    "payload": {
      "@id": "publication:mvp-api",
      "@type": "AutonomyxPublication",
      "title": "MVP API Publication",
      "immutable": true
    }
  }'
```

## State persistence

By default, MVP state is written to:

```text
./data/autonomyx-state.json
```

Override it with:

```bash
AUTONOMYX_STATE_FILE=/var/lib/autonomyx/state/autonomyx-state.json npm run mvp:dev
```

## Run in Kubernetes

```bash
kubectl apply -k deploy/
kubectl -n autonomyx-system port-forward svc/autonomyx-mvp 8080:80
```

Open:

```text
http://localhost:8080
```

The Kubernetes MVP deployment includes:

- `PersistentVolumeClaim` named `autonomyx-mvp-state`
- `Secret` named `autonomyx-mvp-auth`
- `AUTONOMYX_STATE_FILE=/var/lib/autonomyx/state/autonomyx-state.json`
- `AUTONOMYX_MVP_TOKEN` loaded from the secret

## MVP scope

This is the first usable product surface. It proves:

```text
OAM apps
  → manifest
  → binding
  → execution API
  → persistent graph state
  → audit event
  → operator UI
```

## Not yet included

- Production database adapter
- Authentication login UI
- Real OPA bundle runtime
- Real SPIFFE Workload API
- Real OpenTelemetry exporter
- Real Sigstore/SLSA verification
- Production TLS automation
