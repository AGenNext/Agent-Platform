# Agent DB Runtime Schema Load Order

Apply the SurrealDB schema files in this order so dependencies are available before downstream schemas reference them.

```txt
01 core/entity.surql
02 core/relation.surql
03 core/schema.surql
04 core/identity.surql
05 core/security.surql
06 core/governance.surql
07 core/protocol.surql
08 core/registry.surql
09 core/action.surql
10 core/task.surql
11 core/decision.surql
12 core/workflow.surql
13 core/evaluation.surql
14 core/trust.surql
15 core/memory.surql
16 core/knowledge.surql
17 core/artifact.surql
18 core/assurance.surql
19 core/issue.surql
20 core/collaboration.surql
21 core/commerce.surql
```

## Layer View

```txt
Meta
├── entity
├── relation
├── schema
├── protocol
└── registry

Identity and Security
├── identity
└── security

Governance
├── governance
├── assurance
└── issue

Execution
├── action
├── task
├── decision
└── workflow

Learning and Trust
├── evaluation
├── trust
├── memory
└── knowledge

Artifacts, Collaboration, Commerce
├── artifact
├── collaboration
└── commerce
```

## Current Principle

The database is the governed operational state machine.

```txt
Agents propose.
Policies govern.
Humans approve.
Workers execute.
Database reconciles.
```
