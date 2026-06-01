# AGenNext Agent DB Runtime

The Agent DB Runtime is the SurrealDB-backed operational kernel for AGenNext.

It treats the database as a governed state machine for agents, humans, tools, workflows, decisions, policies, trust, memory, knowledge, commerce, and collaboration.

```txt
Agents propose.
Policies govern.
Humans approve.
Workers execute.
Database reconciles.
```

## Purpose

This package defines the common operational language used by the platform.

It is not only storage. It provides the canonical model for:

- identity
- credentials
- authentication
- authorization
- verification
- governance
- policy
- protocol
- registry
- action
- task
- decision
- workflow
- evaluation
- trust
- memory
- knowledge
- artifact
- assurance
- issue
- collaboration
- commerce

## Core Schema Files

```txt
schema/core/
├── entity.surql
├── relation.surql
├── schema.surql
├── identity.surql
├── security.surql
├── governance.surql
├── protocol.surql
├── registry.surql
├── action.surql
├── task.surql
├── decision.surql
├── workflow.surql
├── evaluation.surql
├── trust.surql
├── memory.surql
├── knowledge.surql
├── artifact.surql
├── assurance.surql
├── issue.surql
├── collaboration.surql
└── commerce.surql
```

See [`schema/load-order.md`](./schema/load-order.md) for the required application order.

## Layered Architecture

```txt
Meta Layer
├── Entity
├── Relation
├── Schema
├── Protocol
└── Registry

Identity and Security Layer
├── Identity
├── Credential
├── Authentication
├── Verification
├── Authorization
└── Session

Governance Layer
├── Policy
├── Framework
├── Standard
├── Risk
├── Constraint
├── Approval
├── Assurance
├── Insurance
├── Refund
├── Issue
├── Claim
└── Resolution

Execution Layer
├── Action
├── Task
├── Decision
└── Workflow

Learning and Trust Layer
├── Evaluation
├── Trust
├── Memory
└── Knowledge

Artifact Layer
├── Document
├── Report
├── Code
├── Dataset
├── Presentation
├── Contract
└── Generated Output

Collaboration Layer
├── Collaboration Space
├── Exchange
├── Handoff
└── Delegation

Commerce Layer
├── Quote
├── Offer
├── Order
├── Invoice
├── Payment
├── Settlement
├── Usage
├── Subscription
├── Escrow
└── Revenue Share
```

## Database as Agents Pattern

The database owns governed truth.

Agents and workers should not directly mutate truth without leaving a trace. They should create tasks, decisions, evaluations, evidence, approvals, and outcomes.

```txt
Intent
  ↓
Action
  ↓
Policy Evaluation
  ↓
Approval when required
  ↓
Task
  ↓
Workflow
  ↓
Decision
  ↓
Artifact / Knowledge / Memory
  ↓
Evaluation
  ↓
Trust Update
```

## Recommended Runtime Phases

### Phase 1 — Schema Kernel

Current package state.

- Define core language
- Define first-class records
- Define lifecycle fields
- Define event history tables
- Define reusable SurrealDB functions

### Phase 2 — Schema Runtime

Next implementation phase.

```txt
scripts/
├── apply-schema.ts
├── seed.ts
├── snapshot.ts
├── restore.ts
└── validate-schema.ts
```

Expected commands:

```bash
npm run db:apply
npm run db:seed
npm run db:validate
npm run db:snapshot
npm run db:restore
```

### Phase 3 — Kernel APIs

Expose stable service functions for:

```txt
create_entity()
record_identity()
authenticate()
authorize_action()
evaluate_policy()
create_task()
start_workflow()
record_decision()
record_evaluation()
update_trust()
store_memory()
record_knowledge()
record_artifact()
open_issue()
submit_claim()
settle_transaction()
```

### Phase 4 — Agent Runtime

Build agent-facing runtime components on top of the kernel:

```txt
Agent
Skill
Tool
Prompt
Model
Memory
Knowledge
Team
Registry
Governance
Trust
Payment
```

### Phase 5 — Platform Modules

Use this package as the shared foundation for:

```txt
Agent-BE
Agent-Builder
Agent-Registry
Agent-Identity
Agent-Governance
Agent-Trust
Agent-Eval
Agent-Bench
Agent-Pay
Agent-Commerce
Agent-Space
Agent-Teams
Agent-Research
Agent-RAG
```

## Design Rules

1. Everything durable is an entity.
2. Everything important has lifecycle, ownership, time, evidence, and provenance.
3. Agents propose; the database governs and reconciles.
4. Human approval is explicit, not hidden inside prompts.
5. Decisions explain work.
6. Evaluations judge work.
7. Trust is earned through evidence and history.
8. Memory is not canonical knowledge.
9. Knowledge requires provenance, verification, and dispute handling.
10. Commerce, refund, assurance, and settlement are first-class runtime concepts.

## Current Status

This package is schema-first. The next high-value step is to add the schema application runner and validation tooling.
