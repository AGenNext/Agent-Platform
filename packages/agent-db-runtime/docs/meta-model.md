# Agent DB Runtime Meta Model

Status: draft index, aligned with Frozen Framework v0.1.

This document consolidates the current Agent DB Runtime meta-model and links the supporting model documents.

## Canonical foundation

```txt
Frozen Framework v0.1
  -> Work / Scope / Deadline / Progress
  -> Tool / Skill / Operator
  -> Evidence / Incident / SLA
  -> Knowledge / Memory / Source of Truth
  -> Cards / Registry / Discovery / Trust
```

Canonical framework file:

```txt
packages/agent-db-runtime/docs/frozen-framework-v0.1.md
```

## Core axioms

```txt
Organization defines Work.
Unit of measurement is one Unit of Work.
Organization defines what one Unit of Work means.
Project defines Scope.
Milestone defines Deadline.
Task measures Progress.
Runtime enforces Protocols.
Organization defines allowed Protocols.
Runtime logs Evidence.
Runtime reports Incidents.
Runtime maintains SLA.
Everything outside the kernel is a Tool.
Every agent is an Operator.
Only documented, signed, governed, and verified artifacts can become Knowledge.
Memory stores what is needed to reconstruct useful context, not everything that happened.
If a public canonical source of truth exists, Knowledge must anchor to it.
Available tools are governed data sources and capability surfaces.
Tool documentation is the source material for Skills.
Everything has a Card.
Registry Platform is the issuer of signed Cards.
Signed Card does not automatically mean Verified Capability.
Verification proves capability.
Certification approves scoped use.
Accreditation approves authority.
Recognition records ecosystem acceptance.
Discovery is governed selection over Cards.
Recommendation must explain preferred candidates, alternatives, risks, and confidence.
```

## Runtime operating chain

```txt
Organization
  defines WorkDefinition
    defines UnitOfWork
      measured through Task
        grouped by Project
          constrained by Milestone
            executed by Operator
              using Skill
                through Interface
                  exposed by API
                    governed by Protocol
                      packaged by Toolkit
                        exposing Tool
                          discovered through Registry
                            represented by Card
                              qualified
                                checked for eligibility
                                  recommended
                                    selected or rejected
                                      executed
                                        producing Evidence
                                          evaluated
                                            scored / rated / reviewed
                                              re-evaluated
                                                trusted / suspended / revoked
```

## Card lifecycle

```txt
Draft Card
  -> Submitted Card
    -> Registry Platform Review
      -> Signed Card
        -> Verification
          -> Verified Capability
            -> Certification
              -> Certified Capability
                -> Discovery
                  -> Qualification
                    -> Eligibility
                      -> Recommendation
                        -> Selection / Rejection
                          -> Execution
                            -> Evidence
                              -> Evaluation
                                -> Score / Rating / Review
                                  -> Re-evaluation
                                    -> Continue / Suspend / Revoke / Deprecate
```

## Authority lifecycle

```txt
Authority
  -> Identity
    -> Card
      -> Accreditation Request
        -> Accreditation Decision
          -> Accredited Authority
            -> Scoped Trust Delegation
              -> Re-accreditation / Suspension / Revocation
```

## Knowledge promotion lifecycle

```txt
Observation
  -> Discussion
    -> Claim
      -> Documentation
        -> Artifact
          -> Signed Artifact
            -> Verification
              -> Knowledge Candidate
                -> Governance Approval
                  -> Knowledge
```

## Discovery and decision chain

```txt
Need / Intent / Task
  -> Discovery Query
    -> Candidate Cards
      -> Qualification
        -> Eligibility
          -> Recommendation
            -> Decision
              -> Selection / Rejection
                -> Action Invocation
                  -> Evidence Logged
```

## Core entities

```txt
Organization
WorkDefinition
UnitOfWork
Project
Milestone
Task
Identity
Operator
Skill
Interface
API
Protocol
Toolkit
Tool
Card
Registry
Discovery
Qualification
Eligibility
Recommendation
Selection
Rejection
ActionInvocation
Decision
Evidence
Artifact
Evaluation
Score
Rating
Review
TrustAssessment
Certification
Accreditation
Recognition
Incident
SLA
Assurance
Insurance
Commitment
Duty
Responsibility
Knowledge
Memory
SourceAnchor
```

## Supporting model documents

```txt
docs/frozen-framework-v0.1.md
  Canonical framework freeze.

docs/data-model.md
  Conceptual runtime data model.

docs/capability-model.md
  Capability, skill, interface, API, protocol, toolkit, tool, operator model.

docs/card-model.md
  Universal card model, signed cards, verified capabilities, Registry Platform issuer.

docs/card-meta-model.md
  Eligibility, selection, rejection, scores, ratings, reviews, performance, re-evaluation.

docs/discovery-model.md
  Discovery over cards and registry selection.

docs/qualification-model.md
  Qualification before eligibility.

docs/recommendation-model.md
  Recommendation between discovery and selection.

docs/certification-model.md
  Certification of verified capabilities for scoped use.

docs/accreditation-model.md
  Accreditation of authorities and trust delegation.

docs/recognition-model.md
  Ecosystem reputation and acceptance.
```

## Database-native but portable

The runtime is allowed to use database-native enforcement while avoiding vendor lock-in.

```txt
Database-native
  -> schema enforcement
  -> indexes
  -> relations
  -> events
  -> functions
  -> transactional consistency

Portable-by-design
  -> cards in YAML/JSON/JSON-LD
  -> schemas versioned in Git
  -> open protocols
  -> source-anchored knowledge
  -> exportable artifacts
  -> documented semantics
  -> validation reports
  -> migration path
```

## Execution rule

No further meta-model expansion should block validation.

Allowed next work:

```txt
ERD
GraphQL schema
SurrealDB validation
Runtime validation report
Schema fixes
CI fixes
```

Blocked until validation:

```txt
new core nouns
new platform modules
new marketplace flows
new UI
new deployment architecture
new provider integrations
```

## Current validation status

```txt
Framework: frozen
Meta-model: documented
Runtime scaffold: committed
Live SurrealDB validation: pending
Deployment ready: no
Production ready: no
```

Required command:

```bash
cd packages/agent-db-runtime
make check
```
