# SurrealDB Architecture

## Core Principle

SurrealDB is the runtime. Data and decisions live at the same layer.

```
The context layer must live in the database, not above it.
— SurrealDB position statement
```

The Agent Platform does not add middleware between agents and their data. SurrealDB IS the context layer, the knowledge graph, the memory store, the audit log, the policy engine, and the digital twin backbone.

## What SurrealDB Replaces Natively

| Need | Traditional Tool | Native SurrealDB |
|---|---|---|
| Secrets/env management | Infisical | DEFINE SCOPE, namespace isolation |
| Analytics dashboard | Metabase | LIVE SELECT, SurrealQL aggregates |
| Billing/metering | Lago | usage_record table, budget table, SurrealDB events |
| Health monitoring | Uptime Kuma | health_check table, DEFINE EVENT |
| APM / traces | SigNoz | trace table, OpenTelemetry-aligned |
| Agent memory | External vector DB | MTREE vector index, FTS, LIVE queries |
| Permissions/RBAC | External IAM | DEFINE PERMISSION, DEFINE SCOPE |
| Audit log | External audit service | audit_log table, append-only permissions |
| Policy enforcement | External rules engine | policy table, SurrealQL rule expressions |
| Digital twin backbone | External twin platform | twin table + RELATE graph edges |
| Agent registry | External service registry | agent table, capability ASSERT |

## Graph Data Model

Every entity is a **Schema.org JSON-LD** record:

```
schema:Action    → objective, task
schema:CreativeWork → artifact
schema:SoftwareAgent → agent
schema:Rating    → trust_record
schema:Event     → event (analytics)
schema:HowToStep → skill
schema:Thing     → twin
schema:Rating    → trust_record
schema:CheckAction → health_check
schema:Invoice   → usage_record
```

The semantic web IS the knowledge graph. No separate graph database needed.

## Agent Registration Contract

An agent cannot execute objectives until it is registered with ALL capabilities declared:

```surql
capabilities: {
    analytics: true,
    billing: true,
    health: true,
    tracing: true,
    auth: true,
    artifacts: true,
    skills: true,
    trust: true
}
```

On registration the runtime auto-seeds three default memory records:
1. **Procedural** — identity and capability declaration
2. **Semantic** — platform runtime and ecosystem context
3. **Episodic** — initial registration event

An agent ships with implicit understanding of the runtime, ecosystem, and its own memory — not configured, not optional.

## Schema Files

All SurrealQL schemas live in `services/agent-knowledge-api/schemas/`. The schema loader applies them on startup in sorted order. Agent-Backend's 78 SurrealQL files drop straight in.

| File | Purpose |
|---|---|
| `objective.surql` | schema:Action — objective run records |
| `task.surql` | schema:Action — sub-actions of objectives |
| `trace.surql` | A2A handoff traces, OTel-aligned |
| `artifact.surql` | schema:CreativeWork — generated outputs |
| `agent.surql` | Agent registry with capability ASSERT |
| `skill.surql` | schema:HowToStep — skill registry |
| `memory.surql` | Agent memory — vector + FTS + episodic/semantic/procedural/working |
| `twin.surql` | Digital twin backbone with RELATE graph edges |
| `health.surql` | schema:CheckAction — native health monitoring |
| `trust.surql` | schema:Rating — trust and provenance |
| `analytics.surql` | schema:Event — native analytics via SurrealDB events |
| `billing.surql` | Usage records, budgets, cost attribution |
| `governance.surql` | Audit log, record-level permissions, tenant isolation |
| `policy.surql` | Runtime constraints and guardrails |

## SurrealDB Features Used

- **DEFINE TABLE SCHEMAFULL** — strict schemas, no untyped data
- **DEFINE FIELD ... ASSERT** — runtime validation and guardrails
- **DEFINE EVENT** — reactive triggers (analytics, audit, memory seeding)
- **DEFINE PERMISSION** — record-level tenant isolation and least privilege
- **DEFINE SCOPE** — JWT-based multi-tenant auth
- **DEFINE INDEX ... MTREE** — native vector search (agent memory, twin similarity)
- **DEFINE INDEX ... SEARCH ANALYZER ... BM25** — native full-text search
- **LIVE SELECT** — real-time dashboard updates without polling
- **RELATE** — graph edges for digital twin backbone
- **INSERT IGNORE** — idempotent default data seeding (policies)
- **math::sum / group by** — native aggregates (billing rollups)

## Digital Twins

Every agent, objective, and artifact automatically gets a `twin` record via SurrealDB events. Twins are connected via `twin_relates_to` graph edges. The graph is traversable with SurrealQL:

```surql
-- All twins related to an agent
SELECT ->twin_relates_to->twin.* FROM twin WHERE twin_id = $agent_id;

-- Knowledge graph: artifacts produced by an agent
SELECT ->twin_relates_to->twin.* FROM twin WHERE entity_type = 'agent';
```

## Live Query Pattern (M3)

The dashboard Runtime page will use SurrealDB live queries for real-time updates:

```surql
LIVE SELECT * FROM objective WHERE status IN ['running', 'pending'];
LIVE SELECT * FROM health_check ORDER BY checked_at DESC LIMIT 1;
```

No polling. No message queue. SurrealDB pushes changes via WebSocket.

## Default Integrations

SurrealDB natively integrates with:
- **LangGraph / LangChain** — memory and context provider
- **OpenAI / Anthropic / Ollama** — embedding generation (store vectors in memory table)
- **OpenTelemetry** — trace table is OTel span-aligned
- **JSON-LD / Schema.org** — native document store for semantic data
- **A2A (Agent-to-Agent)** — trace table records all handoffs

Adapters for upstream tools (Metabase, Lago, Infisical, SigNoz) are optional accelerators — the platform runs without them.
