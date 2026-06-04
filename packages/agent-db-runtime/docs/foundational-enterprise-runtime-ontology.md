# Foundational Enterprise Runtime Ontology

Status: draft consolidation, one-shot baseline.

Repository: `AGenNext/Agent-Platform`

Package: `packages/agent-db-runtime`

## Purpose

This document consolidates the foundational ontology that sits below and above the Agent DB Runtime.

It unifies:

```txt
Identity
Organization
Role
Relationship
Responsibility
Authority
Accountability
Time
Location
Data
Information
Knowledge
Enterprise Intent
Strategy
Capability
Asset
Service
Product
Value Stream
Decision
Execution
Evidence
Outcome
Value Realization
Learning
Improvement
```

The goal is to stop incremental noun expansion and provide one coherent baseline for implementation, conformance, and validation.

---

# 1. Foundational primitives

## 1.1 Identity

Identity answers:

```txt
Who or what is this?
```

Identity may represent:

```txt
human
agent
organization
team
service
system
application
device
model
workflow
registry
authority
```

Identity links to:

```txt
Credential
Role
Relationship
Responsibility
Authority
Accountability
Operator
Card
TrustAssessment
```

Runtime rule:

```txt
No meaningful action without identity.
No operator execution without identity.
No delegation without identifiable delegator and delegatee.
```

## 1.2 Organization

Organization answers:

```txt
In what structure does identity operate?
```

Organization may contain:

```txt
Enterprise
BusinessUnit
Department
Team
Program
Project
Community
PartnerNetwork
RegistryAuthority
```

Organization defines:

```txt
Work
UnitOfWork
Policy
Protocol
Role
Responsibility
Authority
Scope
Governance
```

Runtime rule:

```txt
Organization defines work.
Runtime measures work through tasks and units of work.
```

## 1.3 Role

Role answers:

```txt
What function, duty, authority, or responsibility does an identity have in a context?
```

Roles may include:

```txt
owner
operator
approver
reviewer
verifier
certifier
auditor
curator
publisher
issuer
consumer
beneficiary
risk_owner
policy_owner
service_owner
product_owner
capability_owner
```

Runtime rule:

```txt
Roles are contextual.
Identity may hold multiple roles.
Authority is granted through role, policy, delegation, ownership, accreditation, or law.
```

## 1.4 Relationship

Relationship answers:

```txt
How are two entities connected?
```

Relationship types:

```txt
owns
uses
provides
consumes
governs
approves
verifies
certifies
accredits
recognizes
delegates_to
reports_to
depends_on
composes
conflicts_with
replaces
supersedes
benefits
is_accountable_for
is_responsible_for
```

Runtime mapping:

```txt
Relationship
  -> OpenFGA relationship
  -> graph edge
  -> evidence-backed link
```

Runtime rule:

```txt
Authorization depends on relationships, policy, and context.
```

## 1.5 Time

Time answers:

```txt
When did it happen?
When is it due?
When is it valid?
When does it expire?
```

Time concepts:

```txt
EventTime
ValidFrom
ValidUntil
Deadline
MilestoneDate
ReviewDate
ExpiryDate
RecertificationDate
ObservationTime
DecisionTime
ExecutionTime
EvidenceTime
```

Runtime rule:

```txt
Time is a first-class primitive.
Every meaningful state change must be timestamped.
```

## 1.6 Location

Location answers:

```txt
Where does this apply or happen?
```

Location may be:

```txt
physical location
geography
jurisdiction
region
data residency boundary
cloud region
edge node
device location
market geography
legal territory
```

Runtime rule:

```txt
Location affects policy, compliance, data residency, jurisdiction, availability, and value realization.
```

## 1.7 Data, Information, Knowledge

```txt
Data
  raw observation, signal, record, event, or fact candidate

Information
  interpreted data with context and meaning

Knowledge
  documented, signed, verified, governed artifact promoted as trusted reusable truth
```

Knowledge rule:

```txt
Data is not knowledge.
Information is not knowledge.
Memory is not knowledge.
Tool output is not knowledge.
Model output is not knowledge.
Only documented, signed, governed, and verified artifacts can become Knowledge.
```

Promotion path:

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

---

# 2. Enterprise layer

## 2.1 Enterprise intent chain

```txt
Stakeholder
  -> Need / Opportunity / Risk / Obligation
    -> Strategy
      -> Goal
        -> Objective
          -> Metric
          -> Target
          -> Constraint
          -> Assumption
          -> Hypothesis
            -> Portfolio
              -> Program
                -> Project
                  -> Milestone
                    -> Task
                      -> Output
                        -> Outcome
                          -> ValueRealization
                            -> Learning
                              -> Improvement
                                -> Strategy Update
```

## 2.2 Stakeholder and beneficiary

```txt
Stakeholder
  party with interest, influence, responsibility, risk, or accountability

Beneficiary
  party expected to receive value
```

A stakeholder may be a beneficiary, but not every stakeholder is the beneficiary.

## 2.3 Need, opportunity, risk, obligation

```txt
Need
  problem or demand requiring work

Opportunity
  positive value that may be captured

Risk
  uncertainty or potential harm to reduce

Obligation
  duty created by law, regulation, policy, contract, SLA, commitment, or decision
```

## 2.4 Strategy, goal, objective

```txt
Strategy
  direction, priorities, tradeoffs, resource allocation, and policy posture

Goal
  broad desired future state

Objective
  measurable target linked to goal
```

Objective requires:

```txt
metric
target
baseline
deadline
constraints
owner
beneficiary
success criteria
evidence required
```

## 2.5 Metric and target

```txt
Metric
  what is measured

Target
  desired value for the metric
```

Examples:

```txt
cycle_time
cost_per_unit_of_work
value_realization_rate
incident_response_time
trust_score
sla_compliance
risk_reduction
quality_score
adoption_rate
```

---

# 3. Asset-to-value layer

## 3.1 Asset, resource, capability

```txt
Asset
  something owned, governed, or usable to create value

Resource
  something allocated to perform work

Capability
  ability to achieve an outcome
```

Assets include:

```txt
data asset
knowledge asset
software asset
infrastructure asset
brand asset
contract asset
policy asset
model asset
agent asset
tool asset
workflow asset
human skill asset
```

Capabilities are enabled by:

```txt
people
process
policy
data
software
tools
agents
skills
operators
knowledge
resources
partners
```

## 3.2 Service, product, value stream

```txt
Service
  governed capability offered to a consumer

Product
  packaged value offering for a customer, user, beneficiary, or market

ValueStream
  flow of work and capability that delivers value to a beneficiary
```

Asset-to-value chain:

```txt
Asset
  -> Resource
    -> Capability
      -> Process / Workflow
        -> Service
          -> Product
            -> ValueStream
              -> Customer / Beneficiary
                -> Outcome
                  -> ValueRealization
                    -> Learning
                      -> Improvement
```

---

# 4. Work and execution layer

## 4.1 Work model

```txt
Organization defines Work.
Unit of measurement is one UnitOfWork.
Organization defines what one UnitOfWork means.
Project defines Scope.
Milestone defines Deadline.
Task measures Progress.
```

Work chain:

```txt
WorkDefinition
  -> UnitOfWork
    -> Project
      -> Milestone
        -> Task
          -> Output
            -> Outcome
              -> ValueRealization
```

## 4.2 Operator, skill, tool

```txt
Everything outside the kernel is a Tool.
Every agent is an Operator.
Tool documentation is source material for Skills.
```

Execution chain:

```txt
Operator
  -> Skill
    -> Interface
      -> API
        -> Protocol
          -> Tool
            -> ActionInvocation
              -> Evidence
                -> Evaluation
                  -> TrustAssessment
```

---

# 5. Card and registry layer

## 5.1 Everything has a card

```txt
Everything has a Card.
Registry Platform is the issuer of signed Cards.
Signed Card does not automatically mean Verified Capability.
```

## 5.2 Card lifecycle

```txt
Draft Card
  -> Submitted Card
    -> Signed Card
      -> Verified Capability
        -> Certified Capability
          -> Discovered
            -> Qualified
              -> Eligible
                -> Recommended
                  -> Selected / Rejected
                    -> Used
                      -> Rated / Reviewed / Scored
                        -> Re-evaluated
                          -> Continued / Suspended / Revoked / Improved
```

## 5.3 Trust chain

```txt
Signature
  -> Verification
    -> Certification
      -> Accreditation
        -> Recognition
          -> Trust
```

Definitions:

```txt
Signature
  registry acceptance

Verification
  evidence proves capability

Certification
  scoped governance approval for use

Accreditation
  authority approval

Recognition
  ecosystem acceptance

Trust
  evidence-backed confidence
```

---

# 6. Discovery and selection layer

```txt
Discovery
  finds candidates

Qualification
  filters for relevance

Eligibility
  filters for allowed use

Recommendation
  explains preferred option, alternatives, risks, and confidence

Selection
  commits a choice

Rejection
  explains why alternatives were not chosen
```

Chain:

```txt
Need / Task
  -> Discovery
    -> Qualification
      -> Eligibility
        -> Recommendation
          -> Selection / Rejection
            -> Authorization
              -> Execution
```

---

# 7. Decision layer

Decision is the governed commitment to a selected path among alternatives.

```txt
Decision
  records context
  records options
  records selected option
  records rejected options
  records tradeoffs
  records evidence
  records authority
  records assumptions
  records risks
  records expected value
  records outcome
  records learning
```

Decision chain:

```txt
Need / Opportunity / Risk / Obligation
  -> Decision
    -> Commitment
      -> Responsibility
        -> Execution
          -> Evidence
            -> Outcome
              -> ValueRealization
                -> Learning
                  -> Future Decision Improvement
```

Rule:

```txt
Discussion is exploration.
Decision is commitment.
Action is execution.
```

---

# 8. Responsibility, authority, accountability layer

```txt
Responsibility
  who performs or manages

Authority
  who may decide, approve, certify, accredit, invoke, delegate, or override

Accountability
  who answers for outcome, value, risk, compliance, and consequences

Ownership
  who governs or controls

Delegation
  transfer within scope

Acceptance
  acknowledgement of responsibility, authority, or commitment
```

Rules:

```txt
No decision without authority.
No task without responsibility.
No commitment without accountability.
No delegation without acceptance.
No value claim without beneficiary and accountable owner.
```

---

# 9. Governance and economics layer

## 9.1 Governance chain

```txt
Law / Regulation / Standard
  -> Policy
    -> Control
      -> Procedure
        -> Runtime Enforcement
          -> Evidence
            -> Compliance Evaluation
              -> Risk Reduction
                -> ValueRealization
```

## 9.2 Economics chain

```txt
Market / Segment
  -> Customer / Beneficiary
    -> Product / Service
      -> Contract / Commitment
        -> Revenue / Cost / Margin / Profit
          -> Outcome
            -> ValueRealization
```

Economic entities:

```txt
Revenue
Cost
Margin
Profit
Budget
Investment
Benefit
ValueMetric
```

Rule:

```txt
Value must be assessed against cost, risk, and beneficiary outcome.
```

---

# 10. Value realization and learning layer

## 10.1 Work-to-value chain

```txt
Work
  -> Output
    -> Outcome
      -> Value
        -> Learning
          -> Improvement
```

## 10.2 Concept distinctions

```txt
Execution
  did we do it?

Outcome
  what changed?

ValueRealization
  did it matter?

Learning
  what should change?

Improvement
  applied learning
```

## 10.3 Value dimensions

```txt
business_value
user_value
operational_value
financial_value
compliance_value
trust_value
knowledge_value
risk_reduction
cost_reduction
time_saved
quality_improvement
reliability_improvement
sla_improvement
```

## 10.4 Learning dimensions

```txt
decision_learning
skill_learning
tool_learning
operator_learning
policy_learning
recommendation_learning
selection_learning
trust_learning
knowledge_learning
workflow_learning
cost_learning
risk_learning
quality_learning
```

Rule:

```txt
Execution without value realization is activity.
Value realization without learning is reporting.
Learning without improvement is unused insight.
Improvement with evidence increases trust.
```

---

# 11. Operating loop

The platform is a loop, not a line.

```txt
Sense
  -> Understand
    -> Decide
      -> Plan
        -> Execute
          -> Evidence
            -> Evaluate
              -> Realize Value
                -> Learn
                  -> Improve
                    -> Sense
```

Minimum valid runtime loop:

```txt
Task
  -> ActionInvocation
    -> Evidence
      -> Evaluation
        -> Trust Update
          -> Learning
            -> ImprovementCandidate
```

Minimum valid enterprise loop:

```txt
Objective
  -> Project
    -> Outcome
      -> ValueRealization
        -> Learning
          -> Improvement
```

---

# 12. Protocol and policy layer

The runtime enforces protocols and policies.

```txt
Organization defines allowed Protocols.
Runtime enforces Protocols.
Organization defines Policy.
Runtime enforces Policy.
```

Protocol stack:

```txt
MCP
A2A
AuthZEN
OpenFGA
OPA
CloudEvents
OpenAPI
GraphQL
JSON-LD
```

Authorization stack:

```txt
OpenFGA
  relationship authorization

OPA
  policy evaluation

AuthZEN
  authorization decision API
```

---

# 13. Final unified chain

```txt
Identity
  in Organization
    holds Role
      has Relationship
        receives Responsibility
          may hold Authority
            is Accountable for Decision
              creates Commitment
                scopes Project
                  contains Milestone
                    contains Task
                      invokes Operator
                        uses Skill
                          uses Tool
                            produces Evidence
                              supports Evaluation
                                produces Outcome
                                  realizes Value
                                    creates Learning
                                      drives Improvement
                                        updates Strategy / Policy / Work / Skill / Tool / Operator / Knowledge
```

---

# 14. Stop rule

This document is the one-shot foundational ontology baseline.

Do not add more foundational nouns before validation unless the implementation audit proves a missing primitive blocks execution.

Allowed next work:

```txt
implementation audit
schema reconciliation
runtime validation
conformance scoring
gap closure
```

Blocked next work:

```txt
new ontology expansion
new platform modules
new protocol families
new marketplace features
production readiness claims
```

## Final rule

```txt
Enterprise defines intent.
Runtime executes work.
Evidence proves execution.
Evaluation judges quality.
Value realization proves benefit.
Learning improves the next loop.
Trust is earned through repeated evidence-backed value delivery.
```
