# AGenNext Agent Ecosystem Architecture Map

This is the canonical map for the AGenNext agent platform ecosystem.

## Top-Level Product Assembly

```text
Agent-Platform
  → assembles, configures, deploys, and launches the customer-facing platform
```

## Customer-Facing Surfaces

```text
Agent-Site
  → public website, docs, marketing, use-case pages

Agent-Dashboard
  → authenticated control plane, status, approvals, observability views

Agent-Knowledge
  → enterprise source-to-artifact intelligence product API and domain logic
```

## Agent Runtime and Execution

```text
Agent-Team
  → reusable goal-oriented agents and A2A handoff behavior

Agent-Frameworks
  → LangGraph/runtime adapters and SurrealDB-backed runtime state

Agent-Graph
  → artifact schemas and graph-shaped artifact contracts
```

## Governance and Operating Contracts

```text
Agent-Objective
  → objective contracts and completion policy

Agent-Blueprint
  → versioned team/system blueprints

Agent-Constraints
  → reusable policy constraints and guardrails

Agent-Secrets
  → secrets, keys, credential ownership, rotation, and environment-specific handling

Agent-Environment
  → dev/test/staging/prod environment contracts

Agent-Maturity
  → maturity and production/enterprise readiness model
```

## Capability, Model, Research, and Evaluation

```text
Agent-Skills
  → reusable skill/capability registry

Model-Router
  → model/provider routing under constraints and budgets

Agent-Research
  → evidence gathering and research-to-decision traceability

Agent-Bench
  → reproducible benchmark task definitions

Agent-Eval
  → evaluation rubrics, CLEAR scoring, and quality gates
```

## Trust, Telemetry, Analytics, Cost, and Operations

```text
Agent-Trust
  → provenance, evidence, traceability, and trust contracts

Agent-Traces
  → traces, telemetry, logs, correlation IDs, and observability contracts

Agent-Analytics
  → events, metrics, trends, and improvement loops

Agent-FinOps
  → cost governance, usage attribution, budgets, and unit economics

Agent-deploy
  → CI/CD, deployment, monitoring, rollback, post-production operations
```

## Deployment Stack

```text
Local development
  → Podman Compose preferred
  → Docker Compose compatible fallback

First always-on environment
  → VPS + MicroK8s

Later scale path
  → managed Kubernetes or larger MicroK8s cluster
```

## Runtime Flow

```text
User / Dashboard
  → Agent-Knowledge API
  → Agent-Frameworks Runtime
  → Agent-Team
  → SurrealDB runtime state
  → Agent-Analytics / Agent-Traces / Agent-Trust / Agent-FinOps
  → Dashboard visibility
  → Human approval
```

## Source-to-Artifact Product Flow

```text
source material
  → ingestion / freshness check
  → lossless storage in SurrealDB where possible
  → extraction and indexing
  → objective creation
  → agent team execution
  → model routing under constraints and budgets
  → artifact generation
  → evaluation
  → trust/provenance report
  → analytics and FinOps attribution
  → dashboard review
  → human approval
```

## Core Principles

```text
Agent-Platform assembles.
Agent-Knowledge delivers product value.
Agent-Team executes objectives.
Agent-Frameworks runs workflows.
Agent-Environment defines where.
Agent-Secrets protects credentials.
Agent-deploy deploys and operates.
Agent-Traces observes.
Agent-FinOps controls cost.
Agent-Trust proves evidence.
Agent-Eval proves quality.
Agent-Analytics improves over time.
```

## Runtime Law

```text
SurrealDB is the runtime brain, state layer, policy layer, API layer, and deterministic decision layer.
SurrealML is the learned inference layer.
LLMs are language tools, not the source of truth.
```

Business logic outside SurrealDB or SurrealML requires quorum consensus before implementation.

This applies to scoring, trust gates, model routing, budget enforcement, lifecycle transitions, approval decisions, permissions, policy checks, memory selection, belief updates, runtime state mutation, and public runtime API behavior.

```text
No quorum, no exception.
```

Any design change or architecture deviation requires quorum consensus before implementation.

```text
No quorum, no design change.
```

Any grammar, vocabulary, ontology, taxonomy, naming, schema-language, semantic-model, domain-term, relation, entity-type, record-type, edge-type, JSON-LD context, or meaning change requires quorum consensus before implementation.

```text
No quorum, no vocabulary change.
```

## Final Rule

Each repository should own exactly one major responsibility.

If a responsibility is shared, define the boundary explicitly before implementation.
