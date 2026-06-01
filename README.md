# Agent Platform

Agent Platform is the top-level customer-facing enterprise SaaS platform assembly for AGenNext agentic products.

It composes reusable AGenNext subsystems into a deployable platform.

## Platform Mission

Deliver enterprise-grade AI systems that can convert real-world source material into trusted, evaluated, governed business artifacts and intelligence workflows.

## Core Product Capabilities

- Enterprise search
- Enterprise intelligence
- Source-to-artifact generation
- Business decks
- Pitch decks
- Sales decks
- Product documentation
- Demo video scripts
- RFP filling
- Vendor comparison
- Vendor proposal comparison
- Candidate profile screening
- Framework evaluation
- Future artifact workflows

## Platform Composition

```text
Agent-Platform
  → top-level product assembly and deployment boundary

Agent-Knowledge
  → source-to-artifact enterprise intelligence product domain

Agent-Dashboard
  → visibility and control UI

Agent-Team
  → reusable goal-oriented agents

Agent-Framework
  → AGenNext core runtime framework

Agent-Frameworks
  → adapters to external frameworks (LangGraph, CrewAI, AutoGen, etc.)

Agent-Environment
  → dev/test/staging/prod contracts

Agent-Graph
  → artifact schemas

Agent-Objective
  → objective contracts

Agent-Blueprint
  → reusable blueprints

Agent-Constraints
  → policies and guardrails

Agent-Skills
  → reusable skill/capability registry

Model-Router
  → model/provider routing

Agent-Bench
  → benchmark tasks

Agent-Eval
  → evaluation and CLEAR scoring

Agent-Trust
  → trust, evidence, provenance

Agent-Analytics
  → metrics, events, improvement loops

Agent-Research
  → research intelligence

Agent-Maturity
  → maturity and readiness model
```

## Platform Boundary

Agent Platform owns:

- product assembly
- deployment composition
- platform roadmap
- cross-repo integration
- platform-level architecture
- customer-facing platform packaging
- production launch readiness

Agent Platform does not duplicate subsystem ownership.

## Well-Known Discovery

The SurrealDB runtime publishes customer-facing discovery manifests for agent clients:

- `/.well-known/agent-platform.json`
- `/.well-known/agent.json`

Configure the advertised hosts with `PUBLIC_PLATFORM_URL`, `PUBLIC_SURREAL_API_URL`, `PUBLIC_AGENT_DASHBOARD_URL`, and `PUBLIC_AGENT_SITE_URL`.

These values map to the SurrealDB `platform_hosts` registry and the custom API definitions in `surrealdb/schema.surql`.

## Local Runtime Contract

Use `open-container-compose.yml` for local container composition. The backend/runtime layer is SurrealDB; browser-side TypeScript is limited to UI and edge authoring surfaces.

## Core Principle

```text
Subsystems own capabilities.
Agent-Platform assembles and launches the product.
```

## Strict Runtime Rule

SurrealDB is the platform layer for data processing, storage, business logic, policy enforcement, runtime state, API endpoints, permissions, and deterministic decisions. SurrealML is the learned inference layer.

Business logic outside SurrealDB or SurrealML is prohibited unless quorum consensus approves a documented exception. No quorum, no exception.

Any design change or architecture deviation also requires quorum consensus before implementation. No quorum, no design change.

Any grammar, vocabulary, ontology, taxonomy, naming, schema-language, or semantic-model change requires quorum consensus before implementation. No quorum, no vocabulary change.

Validation must run on the user's/client's system before any change is accepted by AGenNext servers.

Validation and authoring feedback must be fast and delivered at the edge. Checks that can run locally must run in the user's browser/client before server submission.

Outside SurrealDB, SurrealQL, SurrealML, and AgentQL, the only approved implementation language is browser-side TypeScript.

CI enforces this direction through Agent-deploy centralized governance validation. The editable validation rules live in `governance/no-python-business-logic.rules.tsv`. The check fails when Python owns business endpoints, scoring, routing, gates, lifecycle transitions, state mutation, or product/domain models.

## AgentQL

AgentQL is the AGenNext language for defining agent runtime vocabulary, ontology, policies, APIs, beliefs, mind state, constitution rules, and SurrealDB-owned business behavior.

AgentQL uses Langium for grammar-driven authoring and tooling. AgentQL compiles to SurrealDB and SurrealML artifacts; it is not a separate runtime business-logic layer.
