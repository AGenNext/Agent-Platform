# Upstream Product Composition Decision

## Decision

Agent Platform will code the core runtime and platform backend entirely in-house, while using upstream open-source or trusted tools for selected supporting product surfaces.

## Recommended Composition

```text
Core runtime/backend
  → custom AGenNext code

Platform API and product state
  → custom AGenNext code

Semantic traces and run model
  → Agent-Traces contracts + SurrealDB

Dashboard / BI reporting
  → Metabase where useful

Agent builder / structured editable tables
  → Teable where useful

Agent flow prototyping / visual flows
  → Langflow where useful

Product UI screens
  → vibe-coded UI, then hardened into Agent-Dashboard / Agent-Site

LLM observability
  → Langfuse adapter

APM / infrastructure observability
  → SigNoz / OpenTelemetry adapter
```

## Core Principle

```text
Own the platform brain.
Use upstream tools for acceleration, visualization, and operations.
Do not outsource the canonical runtime or product data model.
```

## What AGenNext Must Own

AGenNext owns:

- Agent-Platform assembly
- Agent-Knowledge product backend
- Agent-Framework core runtime (AGenNext-owned execution engine)
- Agent-Frameworks adapters (external framework integration layer)
- Agent-Team behavior and A2A handoffs
- Agent-Traces semantic trace model
- SurrealDB product/run state
- tenant/workspace/user/admin model
- objective execution lifecycle
- artifact versioning
- human approval records
- evaluation/trust/finops summaries
- policy and constraints enforcement
- billing/metering model

## Upstream Tool Boundaries

### Metabase

Use for:

- BI dashboards
- run analytics
- cost reports
- tenant/workspace reports
- operational reporting
- product metrics exploration

Do not use as:

- primary product control plane
- runtime event source of truth
- approval workflow engine

### Teable

Use for:

- agent builder admin tables
- editable registries
- skill/config catalogs
- lightweight internal ops UI
- non-critical structured data entry

Do not use as:

- canonical runtime database
- tenant security source of truth
- durable execution engine

### Langflow

Use for:

- visual flow prototyping
- agent flow experimentation
- prompt/tool chain design
- demo flows
- import/export candidates into Agent-Frameworks later

Do not use as:

- production runtime source of truth
- policy enforcement engine
- enterprise execution control plane

### Vibe-Coded UI

Use for:

- fast UI iteration
- dashboard prototypes
- landing pages
- admin screens
- user feedback loops

Then harden into:

- Agent-Dashboard
- Agent-Site
- Agent-Knowledge frontend surfaces

## Integration Pattern

```text
AGenNext backend APIs
  → expose stable product/runtime APIs

Upstream tools
  → consume APIs or read approved views/replicas

Adapters
  → isolate tool-specific SDKs and schemas
```

## Data Ownership Rule

Canonical state belongs to AGenNext systems:

```text
SurrealDB + Agent-Traces + Agent-Knowledge + Agent-Platform
```

Upstream tools may cache, visualize, prototype, or operate on derived/approved data.

## Risk Controls

Before adopting any upstream tool:

- verify license compatibility
- confirm self-hosting path
- isolate credentials through Agent-Secrets
- deploy through Agent-deploy
- trace integration through Agent-Traces
- avoid direct schema lock-in
- keep export path available

## Final Rule

```text
Build the core.
Borrow the accelerators.
Own the data model.
Keep adapters replaceable.
```
