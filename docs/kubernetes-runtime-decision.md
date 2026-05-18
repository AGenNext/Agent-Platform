# Kubernetes Runtime Decision

## Decision

Use **MicroK8s** as the preferred lightweight Kubernetes runtime for staging and production-like deployments.

Use **Docker Compose** for the fastest local development loop.

Do not use Kubeless as the primary platform runtime.

## Recommendation

```text
Local fast dev: Docker Compose
Local/prod-like Kubernetes: MicroK8s
Short demos/single-node experiments: Minikube optional
Serverless function layer: not Kubeless initially
```

## Why MicroK8s

MicroK8s is a better fit for Agent Platform because it supports a lightweight but realistic Kubernetes environment with add-ons for:

- DNS
- ingress
- storage
- registry
- observability integrations later
- multi-service platform deployment

It is better aligned with a platform that includes:

- Agent-Knowledge API
- Agent-Dashboard
- Agent-Site
- SurrealDB
- object storage
- workers
- model runtime adapters
- observability

## Why not Minikube as default

Minikube is useful for quick local Kubernetes demos, but it is less ideal as the default platform target because Agent Platform is expected to evolve into an always-on multi-service environment.

Use Minikube only as an optional compatibility target.

## Why not Kubeless initially

Kubeless is a serverless/function framework, not the core platform runtime.

Agent Platform needs long-running services, stateful backends, queues, workers, dashboard UI, API services, and runtime persistence. These should be deployed first as Kubernetes services/workloads.

Serverless-style execution can be added later if a specific workflow needs it.

## Deployment Path

1. Keep Docker Compose for local dev.
2. Add MicroK8s manifests or Helm chart for staging-like local deployment.
3. Add production overlays later.
4. Keep Minikube compatibility optional.
5. Evaluate serverless only after core services are stable.

## Initial MicroK8s Workloads

- agent-knowledge-api
- agent-dashboard
- agent-site
- surrealdb
- minio or S3-compatible object storage
- worker/runtime service
- optional local model runtime

## Final Rule

```text
Docker Compose for speed.
MicroK8s for platform realism.
Kubeless only if a future function-specific need appears.
```
