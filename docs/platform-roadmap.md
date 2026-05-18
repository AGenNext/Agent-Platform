# Agent Platform Roadmap

This roadmap translates the ecosystem architecture into executable delivery milestones.

## M0: Architecture and Contracts

Status: mostly complete.

Deliverables:

- ecosystem architecture map
- repo responsibility boundaries
- environment contracts
- secrets contract
- deployment contract
- observability contract
- FinOps contract
- maturity model
- local runtime decision

Exit criteria:

- every major responsibility has one owning repository
- Agent-Platform is the canonical assembly repo

## M1: Local Runnable Platform

Goal: make the platform runnable locally.

Deliverables:

- Podman Compose / Docker Compose local stack
- SurrealDB
- MinIO
- Agent-Knowledge API
- Agent-Frameworks runtime
- Agent-Team execution
- `/health`
- `/objectives/run`
- smoke test

Exit criteria:

- developer can run local platform from Agent-Platform
- objective can execute end-to-end
- runtime events are persisted or persistence-ready through SurrealDB backend

## M2: Dashboard Control Loop

Goal: make the platform interactive.

Deliverables:

- Agent-Dashboard UI
- health status view
- objective runner view
- runtime result view
- basic A2A trace view

Exit criteria:

- human can launch an objective from dashboard
- human can see readiness result and blockers

## M3: SurrealDB Runtime Persistence

Goal: make runtime state durable.

Deliverables:

- SurrealDB network writes for runtime events
- objective/task records
- A2A handoff records
- runtime checkpoint records
- event query API

Exit criteria:

- runtime can recover/inspect historical execution
- dashboard can read trace/event state

## M4: Evaluation, Trust, and Maturity Gates

Goal: block release until quality and trust are proven.

Deliverables:

- Agent-Eval hook
- Agent-Trust hook
- Agent-Maturity hook
- release readiness scoring
- human approval package

Exit criteria:

- every objective has evaluation, trust, and maturity status
- release agent can produce evidence-backed handoff

## M5: Model Routing and FinOps

Goal: route models under cost, policy, and quality constraints.

Deliverables:

- Model-Router integration
- Agent-Constraints policy enforcement
- Agent-FinOps cost attribution
- model spend dashboard
- cost per objective/artifact

Exit criteria:

- no objective runs without cost attribution
- model choices are policy-compliant and budget-aware

## M6: MicroK8s VPS Deployment

Goal: first always-on staging/preview environment.

Deliverables:

- MicroK8s manifests or Helm chart
- ingress
- TLS
- secrets handling
- backup/restore plan
- monitoring and alerts
- rollback runbook

Exit criteria:

- platform runs on VPS + MicroK8s
- health checks and post-deploy checks pass

## M7: Source-to-Artifact MVP

Goal: ship the first valuable product workflow.

Recommended first workflows:

1. PDF/document to blog or product documentation
2. URLs to course outline/content
3. source pack to sales deck
4. RFP response from enterprise docs

Exit criteria:

- at least one workflow produces a trusted, evaluated artifact
- dashboard shows provenance, evaluation, trust, and cost

## M8: Enterprise SaaS Foundations

Goal: prepare for real enterprise customers.

Deliverables:

- tenants/workspaces
- users/admins
- roles/permissions
- billing/metering
- source connectors
- audit logs
- policy controls
- versioning/diff/dedupe

Exit criteria:

- platform supports controlled multi-tenant workflows

## M9: Continuous Improvement Loop

Goal: make the system self-improving.

Deliverables:

- analytics feedback loop
- benchmark regression suite
- model routing improvements
- customer feedback to roadmap
- maturity progression dashboard

Exit criteria:

- roadmap and agent decisions are informed by measured outcomes

## Current Priority

```text
M1 → M2 → M3
```

Do not overbuild later-stage systems until the local runnable platform, dashboard loop, and SurrealDB persistence are solid.

## Final Rule

```text
Ship the thinnest end-to-end loop first.
Then harden it with trust, eval, FinOps, and deployment.
```
