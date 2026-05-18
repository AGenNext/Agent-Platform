# VPS + MicroK8s Deployment Plan

## Decision

Use a VPS running MicroK8s as the first always-on deployment target for Agent Platform.

## Why

A VPS with MicroK8s gives the platform:

- low monthly cost
- production-like Kubernetes runtime
- persistent services
- simple operational control
- room to run API, dashboard, workers, SurrealDB, MinIO, and observability
- a clean path from local development to cloud deployment

## Recommended Deployment Path

```text
Local fast dev
  → Podman Compose / Docker Compose

First always-on environment
  → VPS + MicroK8s

Later production scale
  → managed Kubernetes or larger MicroK8s cluster
```

## Minimum VPS Size

For first staging/preview deployment:

```text
4 vCPU
8 GB RAM
100 GB SSD
Ubuntu 22.04 or 24.04 LTS
```

## Better VPS Size

For smoother platform development with SurrealDB, MinIO, dashboard, API, workers, and optional local model runtime:

```text
8 vCPU
16 GB RAM
200 GB SSD
Ubuntu 22.04 or 24.04 LTS
```

## Avoid Initially

Avoid running large local LLMs on the first VPS unless the machine has enough RAM/VRAM.

Use local/open-source runtimes only when practical, and keep Model-Router constrained by Agent-Constraints.

## Initial MicroK8s Add-ons

Enable:

```bash
microk8s enable dns
microk8s enable hostpath-storage
microk8s enable ingress
microk8s enable registry
microk8s enable metrics-server
```

Optional later:

```bash
microk8s enable observability
```

## Initial Workloads

Deploy:

- agent-knowledge-api
- agent-dashboard
- agent-site
- surrealdb
- minio
- runtime worker
- optional ollama/local model runtime

## Security Baseline

- SSH key-only access
- firewall enabled
- only expose required ports
- ingress TLS before public use
- secrets stored as Kubernetes secrets initially
- separate namespace per environment
- backup plan for SurrealDB and object storage

## Final Rule

```text
Podman Compose for local speed.
VPS + MicroK8s for first always-on deployment.
Managed Kubernetes later if scale requires it.
```
