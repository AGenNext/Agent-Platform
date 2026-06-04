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

## Strict Runtime Ownership Rule

SurrealDB owns platform data processing, storage, business logic, policy enforcement, runtime state, API endpoints, permissions, live queries, and deterministic decisioning.

SurrealML owns learned inference for model-backed scoring, classification, and prediction inside the runtime.

LLMs are tools for open-ended language work only. Their outputs must become governed SurrealDB state with provenance before they can affect platform decisions.

Business logic in Python, JavaScript, TypeScript, shell scripts, YAML, external services, or frontend code is prohibited unless quorum consensus approves a documented exception.

Any exception must state why SurrealDB or SurrealML cannot handle the behavior, define the temporary boundary, preserve SurrealDB-owned state/provenance/permissions/audit, and include the migration path back into SurrealDB.

```text
No quorum, no exception.
```

## Design Change Control

Any design change, architecture deviation, runtime-layer deviation, data-ownership change, policy-location change, business-logic placement change, API ownership change, or source-of-truth change requires quorum consensus before implementation.

Every approved design change must record the current approved design, proposed deviation, reason, rejected alternatives, impact on SurrealDB/SurrealML ownership, impact on provenance/audit/permissions/runtime state, rollback or migration path, and quorum approvers.

```text
No quorum, no design change.
```

## Language, Vocabulary, and Ontology Change Control

Any grammar, vocabulary, ontology, taxonomy, schema-language, naming, semantic-model, domain-term, relation, entity-type, record-type, edge-type, JSON-LD context, or meaning change requires quorum consensus before implementation.

Every approved language or ontology change must record the current term or structure, proposed term or structure, exact semantic meaning, affected SurrealDB tables/fields/functions/events/APIs/permissions, affected JSON-LD/context mappings, affected docs/UI labels, migration path for existing records, compatibility impact, and quorum approvers.

```text
No quorum, no vocabulary change.
```

## What AGenNext Must Own

AGenNext owns:

- Agent-Platform assembly
- Agent-Knowledge product backend
- Agent-Frameworks runtime adapters
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

Business decisions belong to SurrealDB or SurrealML, not upstream tools or application code.

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
