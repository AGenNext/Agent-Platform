# Schema Reconciliation Report v0.1

Status: draft, validation pending.

Canonical ontology:

```txt
packages/agent-db-runtime/docs/foundational-enterprise-runtime-ontology.md
```

Companion mapping:

```txt
packages/agent-db-runtime/reports/ontology-to-schema-mapping.md
```

## Purpose

This report reconciles the foundational enterprise/runtime ontology with current schema and contract artifacts.

It identifies what exists, what is missing, what overlaps, and what must be implemented next.

## Current truth

```txt
Ontology baseline: present
Schema contracts: present
Runtime implementation: unknown
Runtime validation: not complete
Production readiness: false
```

## Reconciliation targets

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

## Strongly represented areas

These areas are consistently represented across most design artifacts:

```txt
Card
Registry
Signature
Verification
Certification
Accreditation
Recognition
Discovery
Qualification
Eligibility
Recommendation
Selection
Rejection
Identity
Organization
Project
Milestone
Task
Operator
Skill
Tool
Protocol
Evidence
Decision
Artifact
Knowledge
Evaluation
Score
Rating
Review
TrustAssessment
Incident
SLA
Commitment
Duty
Responsibility
Assurance
Insurance
Claim
Resolution
```

## Missing or weakly represented areas

These are present in the foundational ontology but missing or weak across schemas:

```txt
Role
Relationship as first-class schema
Accountability
Location
Data
Information
Stakeholder
Beneficiary
Need
Opportunity
Strategy
Goal
Objective
Target
Assumption
Hypothesis
Asset
Resource
Process
Workflow as first-class schema
Service
Product
ValueStream
Customer
Outcome
ValueRealization
Learning
Improvement
Law
Regulation
Standard
Policy as first-class schema
Control
Procedure
Audit
Finding
Remediation
Market
Segment
Revenue
Cost
Margin
Profit
Budget
Investment
Benefit
```

## Naming mismatches

| Concept | Current representation | Recommended canonical name |
|---|---|---|
| API | `RuntimeApi` in GraphQL, `runtime_api` in SurrealQL | `RuntimeApi` / `runtime_api` acceptable |
| Interface | `RuntimeInterface` in GraphQL, `runtime_interface` in SurrealQL | `RuntimeInterface` / `runtime_interface` acceptable |
| RAG Index | `RagIndex` in GraphQL, `rag_index` in SurrealQL | keep both as language-specific forms |
| SLA | `Sla` in GraphQL, `sla` in SurrealQL | prefer `SLA` in docs, `Sla` in GraphQL |
| ValueRealization | only docs/events planned | add first-class schema as `ValueRealization` / `value_realization` |
| Learning | only docs/events planned | add first-class schema as `Learning` / `learning` |
| Improvement | only docs/events planned | add first-class schema as `Improvement` / `improvement` |

## Duplicate or overlapping concepts

### Duty, Responsibility, Obligation, Commitment

Current state:

```txt
Duty
Responsibility
Commitment
Obligation in docs only
```

Recommended reconciliation:

```txt
Obligation
  umbrella concept from law, policy, contract, SLA, decision, or commitment

Duty
  normative requirement to act

Responsibility
  assigned party expected to act

Commitment
  promise made by party
```

### Evidence, Artifact, Knowledge

Current state is acceptable.

Keep strict boundary:

```txt
Evidence supports claims.
Artifact records durable output.
Knowledge is promoted only from signed, verified, governed artifacts.
```

### Score, Rating, Review, Evaluation

Current state is acceptable.

Keep distinction:

```txt
Evaluation = assessment activity
Score = computed measurement
Rating = user/reviewer assessment
Review = qualitative assessment
```

## Relationship gaps

The following links should be added to ERD/GraphQL/SurrealQL design schema:

```txt
Stakeholder -> Need
Beneficiary -> Outcome
Need -> Goal
Goal -> Objective
Objective -> Metric
Objective -> Target
Objective -> Project
Assumption -> Objective
Hypothesis -> Objective
Hypothesis -> Outcome
Asset -> Capability
Resource -> Capability
Capability -> Service
Capability -> Product
Service -> ValueStream
Product -> ValueStream
ValueStream -> Beneficiary
Task -> Output
Output -> Outcome
Outcome -> ValueRealization
ValueRealization -> Learning
Learning -> Improvement
Improvement -> Strategy / Policy / WorkDefinition / Skill / Tool / Operator
Law -> Policy
Regulation -> Policy
Standard -> Policy
Policy -> Control
Control -> Procedure
Policy -> OPA rule
Relationship -> OpenFGA tuple
```

## Event gaps

CloudEvents should add these event types:

```txt
agennext.need.recorded.v0
agennext.goal.defined.v0
agennext.objective.defined.v0
agennext.assumption.recorded.v0
agennext.hypothesis.recorded.v0
agennext.outcome.recorded.v0
agennext.value.realized.v0
agennext.learning.recorded.v0
agennext.improvement.created.v0
agennext.improvement.applied.v0
agennext.policy.created.v0
agennext.control.evaluated.v0
agennext.finding.recorded.v0
agennext.remediation.created.v0
```

## API gaps

OpenAPI should eventually include endpoints for:

```txt
/outcomes
/value-realizations
/learnings
/improvements
/objectives
/needs
/policies
/controls
/risks
/assets
/capabilities
/services
/products
/value-streams
```

Do not implement all at once.

Start with minimal value loop endpoints:

```txt
POST /outcomes
POST /value-realizations
POST /learnings
POST /improvements
```

## GraphQL gaps

GraphQL should add first-class types:

```txt
Role
Relationship
Accountability
Location
Stakeholder
Beneficiary
Need
Goal
Objective
Metric
Target
Assumption
Hypothesis
Asset
Resource
Capability
Service
Product
ValueStream
Output
Outcome
ValueRealization
Learning
Improvement
Policy
Control
Procedure
Risk
Opportunity
Obligation
```

Prioritize:

```txt
Outcome
ValueRealization
Learning
Improvement
Need
Objective
Role
Relationship
Policy
Control
```

## SurrealQL design schema gaps

The design schema should add minimum tables:

```txt
role
relationship
stakeholder
beneficiary
need
goal
objective
metric
target
assumption
hypothesis
asset
resource
capability
service
product
value_stream
output
outcome
value_realization
learning
improvement
policy
control
procedure
risk
opportunity
obligation
```

Prioritize:

```txt
output
outcome
value_realization
learning
improvement
need
objective
role
relationship
policy
control
```

## Minimal reconciliation plan

### Phase 1 — Runtime value loop

Add schema/contracts for:

```txt
Output
Outcome
ValueRealization
Learning
Improvement
```

Reason:

```txt
Completes the operating loop from task execution to value and learning.
```

### Phase 2 — Enterprise intent link

Add schema/contracts for:

```txt
Need
Goal
Objective
Metric
Target
Assumption
Hypothesis
```

Reason:

```txt
Allows value to be measured against original intent.
```

### Phase 3 — Responsibility and authorization foundation

Add schema/contracts for:

```txt
Role
Relationship
Accountability
AuthorityGrant
ResponsibilityAssignment
Delegation
Acceptance
```

Reason:

```txt
Connects decisions, tasks, ownership, and access control.
```

### Phase 4 — Governance foundation

Add schema/contracts for:

```txt
Policy
Control
Procedure
Obligation
Risk
Opportunity
```

Reason:

```txt
Connects OPA/OpenFGA/AuthZEN to first-class enterprise policy objects.
```

### Phase 5 — Enterprise asset/value stream layer

Add schema/contracts for:

```txt
Asset
Resource
Capability
Service
Product
ValueStream
Market
Segment
Revenue
Cost
Budget
Investment
Benefit
```

Reason:

```txt
Completes enterprise architecture and economics model.
```

## Validation blockers

The following block production claims:

```txt
No make check evidence
No runtime validation report with real outputs
No implementation audit report
No schema reconciliation implementation
Design schema not proven in live SurrealDB
Protocol mappings not executable adapters
```

## Recommended immediate next action

Do not add more ontology.

Run implementation audit from Issue #20 and then reconcile Phase 1 only.

Start with:

```txt
Output
Outcome
ValueRealization
Learning
Improvement
```

because these complete the loop without expanding the enterprise scope too far.

## Closure criteria for Issue #21

Issue #21 can be considered documentation-complete when:

```txt
ontology-to-schema-mapping.md exists
schema-reconciliation-report.md exists
missing entities listed
relationship gaps listed
event gaps listed
API gaps listed
phased implementation plan listed
production readiness remains false
```

Runtime closure still requires implementation and validation.
