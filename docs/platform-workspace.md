# Agent Platform Workspace

Agent-Platform is the top-level assembly and deployment boundary for the AGenNext ecosystem.

This document defines how the platform should become one runnable system.

## Goal

Turn the collection of reusable repositories into a single local, test, staging, and production platform.

```text
Agent-Platform
  → compose repos
  → run services
  → wire contracts
  → deploy product
```

## Platform Workspace Responsibilities

Agent-Platform owns:

- workspace composition
- local development orchestration
- cross-repo dependency wiring
- deployment composition
- platform-level CI/CD
- release coordination
- environment selection
- product packaging

Agent-Platform does not own the internals of each subsystem.

## Required Workspace Components

```text
workspace/
  services/
    agent-knowledge/
    agent-dashboard/
    agent-site/
  packages/
    agent-team/
    agent-frameworks/
    agent-graph/
  contracts/
    agent-objective/
    agent-blueprint/
    agent-constraints/
    agent-skills/
    agent-eval/
    agent-trust/
    agent-analytics/
    agent-research/
    agent-maturity/
    agent-bench/
  infrastructure/
    surrealdb/
    object-storage/
    queue/
    observability/
```

## Recommended First Implementation

Start with a lightweight composition:

1. `docker-compose.yml`
2. `.env.example`
3. `workspace.yaml`
4. `scripts/bootstrap.sh`
5. `scripts/test-platform.sh`
6. `docs/local-dev.md`
7. `docs/deployment.md`

## Initial Runtime Stack

- Agent-Knowledge API/backend
- Agent-Dashboard UI
- Agent-Team package
- Agent-Frameworks LangGraph adapter
- SurrealDB
- S3-compatible object storage
- Queue/worker runtime
- Observability stack later

## Local Development Goal

A developer should be able to run:

```bash
./scripts/bootstrap.sh
./scripts/dev.sh
```

And get:

- Agent-Knowledge API running
- Agent-Dashboard running
- SurrealDB running
- Agent-Team importable
- basic health checks passing

## Environment Contract

Agent-Platform must consume Agent-Environment for:

- dev
- test
- staging
- prod

## Release Gate

The platform is not release-ready until:

- all required subsystem versions are pinned
- local workspace boots
- tests pass
- eval gates pass
- trust gates pass
- maturity target is reached
- dashboard shows no blocking issues
- deployment rollback is documented

## Final Rule

```text
Repos are reusable subsystems.
Agent-Platform makes them runnable together.
```
