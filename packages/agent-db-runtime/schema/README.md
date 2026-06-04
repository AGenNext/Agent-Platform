# Agent DB Runtime Schema Boundaries

This directory defines the canonical SurrealDB schema for the AGenNext agent runtime kernel.

The purpose of this file is to prevent duplicate concepts from being added across schema files.

## Core Rule

Do not add a new schema file for a concept that is already owned by an existing file unless the existing file is intentionally refactored.

```txt
One concept → one owner file → many references
```

## Ownership Boundaries

| Concept | Owner file | Notes |
|---|---|---|
| Base durable object | `core/entity.surql` | Every durable runtime object should have an entity record. |
| Graph relation | `core/relation.surql` | Generic entity-to-entity relation layer. |
| Type, class, schema, validation, environment | `core/schema.surql` | Meta-model layer. Do not create separate type/class files without refactor. |
| Human, agent, service account, tenant, org identity | `core/identity.surql` | Owns identity lifecycle. |
| Credential | `core/identity.surql` | Credential is identity-owned. Do not create `credential.surql` unless splitting identity. |
| Auth binding | `core/identity.surql` | Relationship-like authorization binding, useful for RBAC/ReBAC modeling. |
| Identity verification | `core/identity.surql` | Identity-level verification record. |
| Authentication event | `core/security.surql` | Runtime authentication attempt/event. |
| Security session | `core/security.surql` | Runtime session state. |
| Authorization decision | `core/security.surql` | Runtime authorization result from SurrealDB/OPA/OpenFGA/AuthZEN/etc. |
| Verification check | `core/security.surql` | Runtime verification of identity, credential, policy, protocol, artifact, payment, proof, claim, etc. |
| Policy, framework, standard, risk, approval | `core/governance.surql` | Governance spine. |
| Protocol and protocol message | `core/protocol.surql` | MCP, A2A, AuthZEN, OpenFGA, OIDC, AP2, UCP, webhooks, etc. |
| Registry/catalog/marketplace | `core/registry.surql` | Discovery, publication, certification, lifecycle. |
| Action and action invocation | `core/action.surql` | Bridge between intent and execution. |
| Task and task event | `core/task.surql` | Governed unit of work. |
| Decision and decision event | `core/decision.surql` | Explanation and choice record. |
| Workflow, step, edge, run | `core/workflow.surql` | Orchestration graph. |
| Evaluation and metric | `core/evaluation.surql` | Quality, correctness, compliance, safety, cost, latency, trustworthiness scoring. |
| Trust assessment and event | `core/trust.surql` | Trust as first-class object, not just a score. |
| Memory | `core/memory.surql` | What is remembered. Not canonical truth. |
| Knowledge | `core/knowledge.surql` | What is known, claimed, verified, disputed, canonical. |
| Artifact | `core/artifact.surql` | Durable output or externalized work product. |
| Assurance, insurance, refund, warranty, claim | `core/assurance.surql` | Commercial/operational confidence commitments and claims. |
| Generic issue, operational claim, resolution | `core/issue.surql` | Non-commercial issue/claim/resolution model. |
| Collaboration, exchange, handoff | `core/collaboration.surql` | Social/coordination layer. |
| Commerce, account, document, usage, transaction, subscription | `core/commerce.surql` | Economic exchange layer. |

## Known Conceptual Overlap

Some concepts intentionally appear in multiple layers with different meanings.

### Verification

```txt
identity.surql
└── identity_verification
    Purpose: verifies an identity lifecycle claim.

security.surql
└── verification_check
    Purpose: runtime verification of any target: credential, policy, protocol, artifact, payment, proof, claim, etc.

knowledge.surql
└── verification_result
    Purpose: evidence that knowledge has been verified.
```

### Claim

```txt
assurance.surql
└── assurance_claim
    Purpose: commercial claim for refund, warranty, SLA breach, insurance, compensation.

issue.surql
└── operational_claim
    Purpose: generic assertion, requirement, obligation, attestation, quality/security/compliance claim.

knowledge.surql
└── knowledge_type = claim
    Purpose: a claim as a knowledge item that may be verified, disputed, or made canonical.
```

### Authorization

```txt
identity.surql
└── auth_binding
    Purpose: durable authorization relationship or binding.

security.surql
└── authorization_decision
    Purpose: runtime decision from an authorization engine.

governance.surql
└── policy_evaluation
    Purpose: policy evaluation that may support authorization.
```

## Addition Checklist

Before adding a new schema file or table, check:

1. Is this concept already owned by an existing schema file?
2. Is it a new domain concept or only a runtime event of an existing concept?
3. Should it be modeled as an `entity`, a relation, an event, or a field?
4. Does it need lifecycle, owner, tenant, evidence, provenance, or trust?
5. Does it overlap with identity, security, governance, issue, assurance, or commerce?
6. Does it need to be discoverable through `registry.surql`?
7. Does it need policy evaluation or approval?

## Load Order

See [`load-order.md`](./load-order.md).
