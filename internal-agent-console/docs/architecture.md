# Internal Agent Console Architecture

## Goal

Build an hPanel-style internal console for AGenNext operations.

The console should hide Kubernetes from daily operators while keeping Kubernetes as the source of truth.

## Control Plane Shape

```text
Browser
  ↓
Next.js Console
  ↓
Spring Boot API
  ↓
Kubernetes Java Client
  ↓
k3s API Server
  ↓
Deployments / Services / Jobs / Secrets / ConfigMaps
```

## Why Not Crossplane First

Crossplane is useful when AGenNext becomes a platform API for many internal/external teams. For the immediate internal use case, it adds extra layers before the basic operations loop is stable.

Start direct:

```text
Console API → Kubernetes API
```

Add Crossplane later only for infrastructure composition such as DNS, cloud databases, VPS, object storage, and external provider resources.

## Core Objects

### Workspace

Maps to Kubernetes namespace.

```text
Workspace → Namespace
```

### Agent

Maps to Kubernetes deployment unit.

```text
Agent → Deployment + Service + ConfigMap + Secret refs
```

### Secret

Maps to Kubernetes secret.

```text
Secret → Kubernetes Secret
```

### Deployment

Read from Kubernetes workloads.

```text
Deployment → apps/v1 Deployment status
```

### Logs

Read from Kubernetes pods.

```text
Logs → Pod logs
```

## Minimal RBAC

The console service account should initially operate only in namespaces labeled:

```yaml
agennext.io/managed-by: internal-agent-console
```

## API Endpoints

```http
GET    /api/dashboard
GET    /api/workspaces
POST   /api/workspaces
DELETE /api/workspaces/{name}
GET    /api/agents
POST   /api/agents
DELETE /api/agents/{workspace}/{name}
POST   /api/agents/{workspace}/{name}/restart
GET    /api/logs/{workspace}/{pod}
GET    /api/secrets
POST   /api/secrets
```

## First Deployment Rule

Do not expose public ingress by default.

Use local cluster access first:

```bash
kubectl port-forward svc/agent-console-web 3000:3000 -n agent-console
```

Public exposure should be added only after auth and policy are active.
