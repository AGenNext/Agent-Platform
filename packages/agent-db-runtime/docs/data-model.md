# Agent DB Runtime Data Model

Status: draft, derived from the current SurrealDB schema scaffold. This document is not validated against a live SurrealDB instance yet.

## Purpose

The Agent DB Runtime data model defines the canonical operational language for the AGenNext platform.

It models the database as a governed operational state machine:

```txt
Identity -> Authorization -> Action -> Task -> Decision -> Evaluation -> Trust
```

and connects this to:

```txt
Workflow
Memory
Knowledge
Artifact
Protocol
Registry
Assurance
Issue
Collaboration
Commerce
```

## Design principles

1. Every durable object is an `Entity`.
2. Runtime-specific tables reference `Entity` for stable identity and metadata.
3. Operational state changes are captured through event/history tables.
4. Decisions explain work.
5. Evaluations judge work.
6. Trust is evidence-backed and time-aware.
7. Memory is not canonical knowledge.
8. Knowledge carries provenance, verification, and dispute state.
9. Commerce, assurance, refund, and settlement are first-class concepts.
10. Deployment readiness requires live SurrealDB validation, not only static schema checks.

## Core entity model

### Entity

Canonical durable object across the runtime.

Owns common metadata such as:

- type
- subtype
- name
- status
- tenant
- owner
- namespace
- version
- schema references
- labels/tags/aliases
- timestamps

Used by every major runtime table.

### Relation

Generic graph relation between two entities.

Used for:

- dependency
- ownership
- lineage
- reference
- composition
- support/contradiction
- workflow/knowledge links

## Meta model

### SchemaDefinition

Defines runtime meta-concepts:

- type
- class
- schema
- field
- enum
- validation rule
- protocol
- framework
- standard
- version
- environment
- namespace
- taxonomy
- ontology

### ValidationResult

Captures validation outcomes for schema, type, relation, policy, protocol, environment, version, and completeness checks.

### RuntimeEnvironment

Represents local, dev, test, staging, production, sandbox, air-gapped, edge, customer-managed, and cloud-managed environments.

## Identity and security model

### Identity

Represents humans, agents, services, tenants, teams, organizations, providers, publishers, partners, resellers, affiliates, owners, and other identity-bearing actors.

### Credential

Identity-owned evidence such as:

- API key
- OAuth/OIDC token reference
- SAML assertion reference
- DID/VC credential reference
- certificate
- SSH key
- service token

### SecuritySession

Runtime session for humans, agents, services, APIs, workflows, delegated sessions, impersonation sessions, and break-glass sessions.

### AuthenticationEvent

Runtime authentication attempt/result.

### AuthorizationDecision

Runtime authorization decision from SurrealDB, OPA, OpenFGA, AuthZEN, RBAC, ABAC, ReBAC, manual, or external engines.

### VerificationCheck

Runtime verification of identity, credential, authorization, policy, protocol, schema, artifact, knowledge, trust, payment, assurance, signature, proof, or claim.

## Governance model

### GovernanceObject

Canonical object for:

- policy
- framework
- standard
- control
- risk
- constraint
- objective
- approval rule
- compliance requirement

### PolicyEvaluation

Result of evaluating policy against subject/action/resource/context.

### GovernanceApproval

Explicit human or authorized approval record.

## Protocol and registry model

### Protocol

First-class protocol definition for:

- MCP
- A2A
- AuthZEN
- OpenFGA
- OPA
- SCIM
- OIDC
- SAML
- DID
- VC
- AP2
- UCP
- HTTP
- gRPC
- WebSocket
- Webhook
- Email
- Slack
- GitHub
- BPMN
- DMN
- LangGraph

### ProtocolBinding

Declares that an entity supports, uses, exposes, or conforms to a protocol.

### ProtocolMessage

Runtime message exchanged through a protocol.

### Registry

Catalog/discovery surface for agents, skills, tools, protocols, models, artifacts, knowledge, workflows, services, policies, schemas, integrations, marketplaces, catalogs, and directories.

### RegistryEntry

Published/certified/deprecated entry in a registry.

## Execution model

### Action

Canonical capability/action definition. Actions describe what can happen.

Examples:

- create
- read
- update
- delete
- search
- approve
- execute
- validate
- verify
- classify
- decide
- recommend
- plan
- schedule
- publish
- deploy
- rollback
- reconcile
- pay
- buy
- order
- invoice
- refund
- settle

### ActionInvocation

Runtime request/execution record for an action.

### Task

Governed unit of work. Tasks track execution state, ownership, assignment, dependencies, blockers, approval, retry, rollback, compensation, evidence, cost, SLA, and outcome.

### TaskEvent

Task lifecycle history.

### Decision

Explains why work happened. Captures context, intent, constraints, objectives, options, tradeoffs, selected option, evidence, policy results, confidence, risk, approval, and outcome.

### DecisionEvent

Decision lifecycle history.

### Workflow

Reusable workflow definition.

Supports:

- sequence
- conditional
- parallel
- join
- loop
- approval
- delegation
- handoff
- retry
- timeout
- rollback
- compensation
- escalation

### WorkflowStep

Step in a workflow graph.

### WorkflowEdge

Directed relation between workflow steps.

### WorkflowRun

Runtime workflow execution.

### WorkflowRunEvent

Workflow execution history.

## Learning, trust, memory, and knowledge model

### Evaluation

Determines whether work was correct, complete, compliant, safe, aligned, cost-effective, timely, and trustworthy.

### EvaluationMetric

Detailed metric attached to an evaluation.

### TrustAssessment

First-class trust object for identity, credential, agent, human, knowledge, decision, tool, provider, organization, relationship, protocol, runtime, environment, and evidence trust.

### TrustEvent

Trust history.

### Memory

What is remembered.

Types include:

- working
- short-term
- long-term
- episodic
- semantic
- procedural
- organizational
- team
- agent
- user
- task
- decision
- knowledge
- tool usage
- evaluation
- trust

### KnowledgeItem

What is known, claimed, observed, verified, disputed, derived, cited, and governed.

### KnowledgeRelation

Relationship between knowledge items, such as supports, contradicts, derives from, cites, explains, classifies, specializes, generalizes, equivalent to, similar to, supersedes, depends on, and part of.

## Artifact model

### Artifact

Durable work product:

- document
- report
- blog
- PRD
- code
- pull request
- contract
- invoice
- presentation
- dataset
- model
- workflow definition
- policy artifact
- decision record
- evaluation report
- knowledge base entry
- image
- video
- audio
- spreadsheet
- diagram
- configuration
- schema
- API spec
- runbook
- playbook
- generated output

### ArtifactEvent

Artifact lifecycle history.

## Assurance, issue, and resolution model

### AssuranceProduct

Commercial or operational confidence commitment:

- insurance
- assurance
- guarantee
- warranty
- refund policy
- service credit
- liability cover
- performance guarantee
- quality guarantee
- compliance guarantee
- delivery guarantee
- uptime guarantee
- safety guarantee
- trust guarantee

### AssuranceBinding

Binding of an assurance product to a subject, resource, task, workflow, artifact, or transaction.

### AssuranceClaim

Commercial claim, refund request, warranty claim, SLA breach claim, quality failure claim, delivery failure claim, or compensation request.

### Issue

Generic operational problem, risk, finding, violation, defect, bug, exception, observation, recommendation, dispute, non-conformance, security issue, privacy issue, quality issue, reliability issue, trust issue, compliance issue, or operational issue.

### OperationalClaim

Generic assertion, requirement, obligation, attestation, statement, finding claim, compliance claim, security claim, quality claim, trust claim, performance claim, or capability claim.

### Resolution

Corrective action, preventive action, exception approval, risk acceptance, settlement, closure, reconciliation, rollback, compensation, documentation update, policy update, control update, training, monitoring, or no action.

## Collaboration model

### CollaborationSpace

Shared work area for conversations, projects, teams, agent teams, customers, vendors, incidents, approvals, negotiations, support threads, workflow threads, and task threads.

### Exchange

Message, request, response, proposal, offer, acceptance, rejection, counter-offer, question, answer, notification, approval request, approval response, handoff request, delegation request, status update, coordination signal, negotiation message, commitment, or acknowledgement.

### Handoff

Transfer of ownership, responsibility, context, authority, task, workflow, agent, human support, or incident escalation.

## Commerce model

### CommerceAccount

Economic account for customers, merchants, providers, agent providers, marketplaces, escrow, platform, settlement, tax, commission, and revenue share.

### CommercialDocument

Quote, offer, counter-offer, order, contract, agreement, invoice, receipt, credit note, debit note, refund note, settlement statement, usage statement, subscription agreement, purchase order, or service order.

### UsageRecord

Metered usage such as agent execution, tool call, model call, workflow run, storage, API call, token usage, compute time, human review, artifact generation, knowledge query, memory access, or protocol message.

### CommerceTransaction

Authorization, capture, payment, refund, chargeback, credit, debit, settlement, escrow hold, escrow release, commission, revenue share, tax, subscription charge, usage charge, service credit, or compensation.

### Subscription

Recurring, trialing, usage-based, or custom subscription agreement.

## Primary end-to-end flow

```txt
Identity
  -> Credential
  -> AuthenticationEvent
  -> SecuritySession
  -> AuthorizationDecision
  -> Action
  -> ActionInvocation
  -> Task
  -> WorkflowRun
  -> Decision
  -> Artifact / Memory / Knowledge
  -> Evaluation
  -> TrustAssessment
```

## Deployment readiness note

This data model is not production-ready until:

```txt
make check
```

passes in `packages/agent-db-runtime` against pinned SurrealDB `v2.3.10`.
