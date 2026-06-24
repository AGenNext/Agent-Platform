# Autonomyx MVP

The MVP is a usable control-plane surface for the Autonomyx OAM stack.

## What it provides

- Browser operator UI at `/`
- Health endpoint at `/healthz`
- App registry endpoint at `/api/apps`
- State endpoint at `/api/state`
- Manifest endpoint at `/api/manifest`
- Binding endpoint at `/api/binding`
- Execution endpoint at `/api/execute`
- Admission endpoint at `/admit`

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

## Execute through API

```bash
curl -X POST http://localhost:8080/api/execute \
  -H 'content-type: application/json' \
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

## Run in Kubernetes

```bash
kubectl apply -k deploy/
kubectl -n autonomyx-system port-forward svc/autonomyx-mvp 8080:80
```

Open:

```text
http://localhost:8080
```

## MVP scope

This is the first usable product surface. It proves:

```text
OAM apps
  → manifest
  → binding
  → execution API
  → graph state
  → audit event
  → operator UI
```

## Not yet included

- Persistent database
- Authentication login UI
- Real OPA bundle runtime
- Real SPIFFE Workload API
- Real OpenTelemetry exporter
- Real Sigstore/SLSA verification
- Production TLS automation
