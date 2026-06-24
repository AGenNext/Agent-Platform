# Internal Agent Console

A fast internal hPanel-style console for AGenNext operations.

This is **not** a hosting product and not a public control panel. It is an internal operator console that gives a simple UI over Kubernetes so the team can create workspaces, deploy agents, view logs, manage secrets, and operate the stack without exposing raw YAML.

## Principle

```text
User clicks button
  ↓
Console API validates request
  ↓
Kubernetes API applies resources
  ↓
k3s runs the workload
```

Kubernetes remains the control plane. The console is a thin operational layer.

## Initial Scope

Build only the internal loop first:

- Dashboard
- Workspaces
- Agents
- Deployments
- Logs
- Secrets
- Settings

Skip for now:

- Crossplane
- Billing
- Marketplace
- Public reseller features
- Email hosting
- Full multi-tenant SaaS packaging

## Stack

```text
Frontend  : Next.js + Tailwind
Backend   : Spring Boot
Runtime   : k3s / Kubernetes API
Deploy    : Helm chart
Database  : optional SurrealDB later
Auth      : local admin first, Authentik later
```

## Repository Layout

```text
internal-agent-console/
├── apps/
│   ├── web/       # Next.js UI scaffold
│   └── api/       # Spring Boot API scaffold
├── charts/
│   └── agent-console/
├── deploy/
├── docs/
└── examples/
```

## First Use Case

### Create Workspace

A workspace maps to a Kubernetes namespace.

```json
{
  "name": "research",
  "description": "Internal research workspace"
}
```

Creates:

```text
Namespace: research
Labels: agennext.io/workspace=true
```

### Create Agent

An agent maps to a Deployment, Service, ConfigMap, and Secret references.

```json
{
  "name": "research-agent",
  "workspace": "research",
  "image": "ghcr.io/agennext/research-agent:latest",
  "replicas": 1
}
```

Creates:

```text
Deployment/research-agent
Service/research-agent
ConfigMap/research-agent-config
```

## Local Development

```bash
cd internal-agent-console/apps/web
npm install
npm run dev
```

```bash
cd internal-agent-console/apps/api
./mvnw spring-boot:run
```

## Deploy

```bash
helm upgrade --install agent-console ./internal-agent-console/charts/agent-console \
  --namespace agent-console \
  --create-namespace
```

## Security Defaults

- Internal network only
- No public ingress by default
- Namespace-per-workspace
- Least-privilege service account
- Secrets mounted from Kubernetes Secrets
- Audit every create/update/delete action

## Roadmap

1. Dashboard and read-only Kubernetes inventory
2. Workspace create/delete
3. Agent create/delete/restart/logs
4. Secrets manager
5. Helm template installer
6. Authentik integration
7. OPA policy gates
8. SurrealDB audit/event store
