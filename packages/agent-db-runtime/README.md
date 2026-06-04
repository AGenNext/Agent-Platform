# AGenNext Agent DB Runtime

The Agent DB Runtime is the SurrealDB-backed operational kernel for AGenNext.

> **Status: committed but untested.**
>
> The schema files, SurrealQL seed/smoke scripts, Podman compose file, Makefile, and CI gates are committed and verified against SurrealDB `v2.3.10` via the `surreal` CLI. This package is SurrealDB-first: the only runtime tool is the SurrealDB CLI — there is no Node/npm/TypeScript tooling.

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

## Validation Status

Current validation status:

```txt
Committed to repository: yes
SurrealQL seed + smoke scripts added: yes
Podman SurrealDB runtime added: yes
CI deployment gates added: yes
Live SurrealDB apply tested: yes (surreal v2.3.10)
Known-good production status: no
Deployment-ready: no
```

Required local proof command:

```bash
cd packages/agent-db-runtime
make up
make apply
make seed
make smoke
```

The package should not be considered runtime-ready until `make apply` succeeds against the pinned SurrealDB server version.

## Deployment Readiness Gates

Deployment is blocked unless all of the following pass:

```txt
Gate 1: SurrealDB CLI (surreal v2.3.10) installs successfully
Gate 2: Pinned SurrealDB server starts successfully
Gate 3: Core schema applies against live SurrealDB (load order)
Gate 4: Seed bootstrap records apply successfully
Gate 5: Smoke assertions pass (THROW on missing records)
Gate 6: Regression tests pass (THROW on regressions)
Gate 7: Value-loop slice applies and asserts records
Gate 8: Backup + disaster-recovery restore verified
Gate 9: File-backed persistence survives a restart
Gate 10: Upgrade/migration path is documented and tested
```

Current implemented gates:

```txt
✓ Install surreal v2.3.10 CLI in CI
✓ Start surreal in-memory server in CI
✓ surreal import core schema (schema/load-order.txt)
✓ surreal import schema/seed.surql
✓ surreal import tests/smoke.surql (asserts via THROW)
✓ surreal import tests/regression.surql (asserts via THROW)
✓ surreal import value-loop slice + tests/value-loop-asserts.surql
✓ Backup (surreal export) + restore (schema-from-repo + data) verified
✓ File-backed (rocksdb) persistence verified across a restart
```

Current missing gates:

```txt
✗ upgrade/migration test (schema change over existing seeded data)
```

Backup and restore locally:

```bash
make backup                          # surreal export -> backups/agent-runtime-backup.surql
SURREAL_DB=agent_runtime_dr make restore-check   # schema from repo + data from backup, then verify
```

The GitHub Actions workflow is:

```txt
.github/workflows/agent-db-runtime-gates.yml
```

A green parse alone is **not** deployment readiness. The live SurrealDB apply, seed, and smoke gates must also pass.

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

Current implementation phase.

```txt
schema/
├── load-order.txt        (core schema apply order)
├── seed.surql            (bootstrap records)
└── design/               (value-loop design slice)
tests/
├── smoke.surql           (core bootstrap assertions)
├── value-loop-smoke.surql
└── value-loop-asserts.surql
```

Expected commands (SurrealDB CLI via make):

```bash
make apply        # surreal import core schema in load order
make seed         # surreal import schema/seed.surql
make smoke        # surreal import tests/smoke.surql
make value-loop   # apply + assert the value-loop slice
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

This package is schema-first and **untested against live SurrealDB**. The next high-value step is to run the schema application runner against the pinned local SurrealDB instance or CI gate and fix the first failing schema file.
