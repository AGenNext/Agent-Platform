# Container Runtime Decision

## Decision

Use **Podman + Podman Compose** as the preferred local container runtime for Agent Platform.

Keep **Docker Compose** compatibility as a fallback because it is widely adopted and familiar.

## Recommendation

```text
Preferred local runtime: Podman + Podman Compose
Compatibility fallback: Docker Compose
Kubernetes target: MicroK8s
```

## Why Podman

Podman is a strong fit for Agent Platform because it is:

- daemonless
- rootless-friendly
- OCI-native
- Linux/enterprise aligned
- compatible with Docker-style images and Compose workflows
- better aligned with security-conscious local development

## Why still support Docker Compose

Docker Compose should remain supported because:

- many developers already have Docker installed
- CI templates often assume Docker compatibility
- onboarding is easier for some contributors
- existing Compose files are portable with minor adjustments

## Local Development Policy

Agent Platform should support both commands:

```bash
podman compose up -d
```

and:

```bash
docker compose up -d
```

Scripts should prefer Podman when available and fall back to Docker.

## Relationship to MicroK8s

```text
Podman Compose / Docker Compose
  → fast local development

MicroK8s
  → production-like Kubernetes deployment
```

## Why not Podman instead of Kubernetes

Podman is excellent for local/container runtime workflows, but Agent Platform will eventually need Kubernetes-grade deployment capabilities:

- ingress
- service discovery
- scaling
- rollout/rollback
- storage classes
- environment promotion
- multi-service lifecycle management

So Podman is preferred for local development, while MicroK8s remains preferred for Kubernetes staging/production-like deployment.

## Final Rule

```text
Podman first for local containers.
Docker Compose for compatibility.
MicroK8s for Kubernetes realism.
```
