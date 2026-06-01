# Ontology to Schema Mapping v0.1

Status: draft mapping, validation pending.

Canonical ontology:

```txt
packages/agent-db-runtime/docs/foundational-enterprise-runtime-ontology.md
```

## Purpose

Map the foundational enterprise/runtime ontology to current schema and contract artifacts.

This report supports Issue #21 and blocks further ontology expansion until reconciliation and validation are complete.

## Mapping legend

```txt
Mapped       = represented directly
Partial      = represented indirectly or incompletely
Missing      = not represented in target artifact
Design only  = represented in design artifact but not runtime-validated
```

## Target artifacts

```txt
docs/runtime-ontology.jsonld
docs/runtime-erd.mmd
graphql/runtime.graphql
openapi/runtime-openapi.yaml
events/runtime-cloudevents.yaml
schema/design/runtime-meta-model.surql
protocols/runtime-mcp.yaml
protocols/runtime-a2a.yaml
protocols/runtime-authzen.yaml
protocols/runtime-openfga.yaml
protocols/runtime-opa.yaml
```

## Foundational primitive mapping

| Ontology primitive | JSON-LD | ERD | GraphQL | OpenAPI | CloudEvents | SurrealQL design | Protocol maps | Status |
|---|---|---|---|---|---|---|---|---|
| Identity | Mapped | Mapped | Mapped | Partial | Partial | Mapped | Mapped | Partial |
| Organization | Mapped | Mapped | Mapped | Partial | Partial | Mapped | Mapped | Partial |
| Role | Missing | Missing | Missing | Missing | Missing | Missing | Partial in OpenFGA | Missing |
| Relationship | Partial | Partial | Partial | Missing | Missing | Partial | Mapped in OpenFGA | Partial |
| Responsibility | Mapped | Mapped | Mapped | Missing | Partial | Mapped | Mapped | Partial |
| Authority | Partial | Partial | Partial | Partial | Partial | Partial | Mapped | Partial |
| Accountability | Partial | Partial | Missing | Missing | Missing | Missing | Partial | Missing |
| Time | Partial | Partial | Partial | Partial | Mapped | Partial | Partial | Partial |
| Location | Missing | Missing | Missing | Missing | Missing | Missing | Partial via policy context | Missing |
| Data | Missing | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Information | Missing | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Knowledge | Mapped | Mapped | Mapped | Partial | Mapped | Mapped | Mapped | Partial |

## Enterprise layer mapping

| Ontology primitive | JSON-LD | ERD | GraphQL | OpenAPI | CloudEvents | SurrealQL design | Status |
|---|---|---|---|---|---|---|---|
| Stakeholder | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Beneficiary | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Need | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Opportunity | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Risk | Partial | Partial via Incident/SLA | Missing | Missing | Partial | Missing | Partial |
| Obligation | Partial | Partial via Duty/Commitment | Partial | Missing | Missing | Missing | Partial |
| Strategy | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Goal | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Objective | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Metric | Partial via Score | Partial via Score | Partial | Missing | Partial | Partial | Partial |
| Target | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Constraint | Partial via OPA | Missing | Missing | Missing | Missing | Missing | Partial |
| Assumption | Partial via Decision | Missing | Missing | Missing | Missing | Missing | Partial |
| Hypothesis | Missing | Missing | Missing | Missing | Missing | Missing | Missing |

## Asset-to-value mapping

| Ontology primitive | JSON-LD | ERD | GraphQL | OpenAPI | CloudEvents | SurrealQL design | Status |
|---|---|---|---|---|---|---|---|
| Asset | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Resource | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Capability | Partial via Skill/Tool | Partial | Partial | Partial | Mapped via capability events | Partial | Partial |
| Process | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Workflow | Partial | Partial | Missing | Missing | Missing | Missing | Partial |
| Service | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Product | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| ValueStream | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Customer | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Outcome | Missing | Missing | Missing | Missing | Planned event only | Missing | Missing |
| ValueRealization | Missing | Missing | Missing | Missing | Planned event only | Missing | Missing |
| Learning | Missing | Missing | Missing | Missing | Planned event only | Missing | Missing |
| Improvement | Missing | Missing | Missing | Missing | Planned event only | Missing | Missing |

## Runtime model mapping

| Runtime primitive | JSON-LD | ERD | GraphQL | OpenAPI | CloudEvents | SurrealQL design | Status |
|---|---|---|---|---|---|---|---|
| WorkDefinition | Mapped | Mapped | Mapped | Missing | Missing | Mapped | Partial |
| UnitOfWork | Mapped | Mapped | Mapped | Missing | Missing | Mapped | Partial |
| Project | Mapped | Mapped | Mapped | Partial | Partial | Mapped | Partial |
| Milestone | Mapped | Mapped | Mapped | Missing | Partial | Mapped | Partial |
| Task | Mapped | Mapped | Mapped | Mapped | Partial | Mapped | Partial |
| Operator | Mapped | Mapped | Mapped | Partial | Partial | Mapped | Mapped |
| Skill | Mapped | Mapped | Mapped | Partial | Partial | Mapped | Mapped |
| Tool | Mapped | Mapped | Mapped | Partial | Partial | Mapped | Mapped |
| Protocol | Mapped | Mapped | Mapped | Partial | Mapped | Mapped | Mapped |
| Evidence | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Evaluation | Mapped | Mapped | Mapped | Partial | Mapped | Mapped | Partial |
| TrustAssessment | Mapped | Mapped | Mapped | Missing | Mapped | Mapped | Partial |

## Card and registry mapping

| Card primitive | JSON-LD | ERD | GraphQL | OpenAPI | CloudEvents | SurrealQL design | Status |
|---|---|---|---|---|---|---|---|
| Card | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| RegistryPlatform | Mapped | Mapped | Mapped | Partial | Mapped | Mapped | Partial |
| Registry | Mapped | Mapped | Mapped | Mapped | Partial | Mapped | Partial |
| RegistryEntry | Mapped | Mapped | Mapped | Mapped | Partial | Mapped | Partial |
| Signature | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Verification | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Certification | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Accreditation | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Recognition | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Qualification | Mapped | Mapped | Mapped | Partial | Mapped | Mapped | Mapped |
| Eligibility | Mapped | Mapped | Mapped | Partial | Partial | Mapped | Mapped |
| Recommendation | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Selection | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |
| Rejection | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped | Mapped |

## Governance and economics mapping

| Primitive | JSON-LD | ERD | GraphQL | OpenAPI | CloudEvents | SurrealQL design | Status |
|---|---|---|---|---|---|---|---|
| Law | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Regulation | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Standard | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Policy | Partial via OPA | Missing | Missing | Missing | Missing | Missing | Partial |
| Control | Partial via OPA | Missing | Missing | Missing | Missing | Missing | Partial |
| Procedure | Partial via Skill/Workflow | Missing | Missing | Missing | Missing | Missing | Partial |
| Audit | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Finding | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Remediation | Partial via Task | Missing | Missing | Missing | Missing | Missing | Partial |
| Market | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Segment | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Revenue | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Cost | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Margin | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Profit | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Budget | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Investment | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Benefit | Missing | Missing | Missing | Missing | Missing | Missing | Missing |

## Summary

The runtime execution, card, registry, discovery, trust, and knowledge layers are well represented in design artifacts.

The enterprise layer is now documented but not yet reconciled into schemas.

The largest gaps are:

```txt
Role
Location
Data
Information
Stakeholder
Beneficiary
Need
Strategy
Goal
Objective
Target
Asset
Resource
Service
Product
ValueStream
Outcome
ValueRealization
Learning
Improvement
Law/Regulation/Standard
Policy/Control as first-class schema
Market/Economics
```

## Recommendation

Do not add new ontology concepts.

Create a reconciliation phase that adds only the minimum schema objects required to represent the foundational ontology consistently across:

```txt
JSON-LD
ERD
GraphQL
OpenAPI
CloudEvents
SurrealQL design schema
```

Runtime validation remains pending.
