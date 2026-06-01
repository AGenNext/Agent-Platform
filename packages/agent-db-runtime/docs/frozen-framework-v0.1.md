# Agent DB Runtime Frozen Framework v0.1

Status: frozen for validation.

This document is the canonical framework freeze for the Agent DB Runtime in `AGenNext/Agent-Platform`.

Do not add new core nouns, schema files, platform modules, or hierarchy changes until the runtime validation gates pass.

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
```

## Operating model

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
                          producing Evidence
                            recorded as Artifact
                              promoted to Knowledge only if signed, governed, and verified
```

## Work model

Work is not universal.

Each organization defines what work means.

```txt
Software organization
  Unit of Work = shipped story / merged PR / resolved issue

Support organization
  Unit of Work = resolved ticket / handled escalation / customer response

Sales organization
  Unit of Work = qualified lead / proposal sent / deal advanced

Research organization
  Unit of Work = source reviewed / claim verified / report section completed

Agent runtime
  Unit of Work = task completed with decision, evidence, evaluation, and trust update
```

### WorkDefinition

```txt
WorkDefinition
├── organization
├── industry
├── domain
├── work_type
├── unit_name
├── measurement_rule
├── evidence_required
├── completion_criteria
├── quality_criteria
├── trust_criteria
├── cost_model
├── progress_formula
├── governance_policy
└── version
```

### Progress

```txt
Progress = completed units of work / planned units of work
```

Progress is measured by tasks, not guessed from conversation.

```txt
Project Progress
  = aggregate(Task.status, Task.progress, Task.blockers, Task.evidence)

Milestone Progress
  = aggregate(Tasks linked to Milestone)

Workflow Progress
  = aggregate(Tasks and WorkflowSteps)
```

## Scope, deadline, and progress

```txt
Project = scope boundary
Milestone = deadline boundary
Task = progress unit
```

A project answers:

```txt
What is included?
What is excluded?
Who owns it?
What constraints apply?
Which tools/operators/skills/protocols are allowed?
```

A milestone answers:

```txt
By when?
What must be delivered?
What evidence proves delivery?
```

A task answers:

```txt
What work is being done?
Who is doing it?
How far has it progressed?
What blocks it?
What evidence proves it moved forward?
```

## Tool, skill, and operator model

```txt
Tool = outside capability surface and possible data/evidence source
Tool Documentation = skill source / usage contract / operating instruction
Skill = governed reusable capability derived from documented tool use
Operator = executor
Agent = identity that becomes an operator during execution
```

Everything outside the kernel is a tool:

```txt
External API
SaaS application
Database
Object store
Message queue
Webhook endpoint
Email inbox
Slack workspace
GitHub repository
Browser
CLI command
File system
Search engine
Calendar system
Payment provider
CRM
ERP
Ticketing system
Model provider
Vector database
MCP server
A2A endpoint
Human-facing app surface
```

Every agent is an operator during execution:

```txt
Agent Identity
  has Credential
  has TrustAssessment
  has RegistryEntry
  becomes Agent Operator during execution
```

Execution model:

```txt
Agent Operator
  receives Task
  selects Skill
  uses Interface
  calls Tool
  executes Operator Action
  records Decision
  emits Evidence
  receives Evaluation
  updates Trust
```

## Protocol model

Organizations define allowed protocols.

Runtime enforces protocol conformance.

```txt
Organization
  defines allowed Protocols
    Runtime validates ProtocolBinding
      Operator uses Tool through Protocol
        Runtime logs ProtocolMessage
          Runtime evaluates conformance
```

Examples:

```txt
MCP
A2A
AuthZEN
OpenFGA
OPA
SCIM
OIDC
SAML
DID
Verifiable Credential
AP2
UCP
HTTP
gRPC
WebSocket
Webhook
Email
Slack
GitHub
BPMN
DMN
LangGraph
```

## Evidence, incidents, and SLA

Runtime logs evidence for every meaningful state change.

Evidence is required for:

```txt
action invocation
protocol use
tool use
decision
approval
handoff
claim
incident
resolution
evaluation
trust update
knowledge promotion
payment/settlement
```

Runtime reports incidents.

Runtime maintains SLA.

```txt
Incident
  arises from issue, failure, breach, violation, outage, risk, defect, or escalation
  requires evidence
  requires owner
  requires severity
  requires response state
  may trigger claim, assurance, refund, or insurance path
```

```txt
SLA
  defines obligation
  defines time/quality/reliability threshold
  links to duty, responsibility, commitment, assurance, and evidence
  may trigger incident or claim when breached
```

## Duty, responsibility, commitment, assurance, and insurance ontology

```txt
Discussion
  produces Options / Arguments / Evidence

Decision
  selects Direction
  creates Commitment
  assigns Responsibility
  may create Duty

Duty
  defines what must be done

Responsibility
  defines who is accountable for doing it

Commitment
  defines what has been promised

Assurance
  increases confidence that the commitment will be met

Insurance
  transfers financial risk if the commitment fails

Documentation
  records discussion, decision, duty, responsibility, commitment, evidence, assurance, and outcome

Evidence
  proves what happened

Claim
  asserts something happened or failed

Resolution
  closes the issue, claim, or incident
```

Runtime mapping:

```txt
Discussion       -> collaboration_space / exchange
Decision         -> decision
Documentation    -> artifact
Duty             -> governance_object / task
Responsibility   -> task.owner / task.assignee / handoff
Commitment       -> exchange / commercial_document / governance_object
Assurance        -> assurance_product / assurance_binding
Insurance        -> assurance_product(assurance_type = insurance)
Evidence         -> artifact / verification_check / event
Claim            -> operational_claim / assurance_claim / knowledge_item
Resolution       -> resolution
```

## Knowledge model

Not everything can become knowledge.

```txt
Everything can be recorded.
Everything can be discussed.
Everything can be claimed.
Everything can be documented.
Only some things can become Knowledge.
```

Knowledge is not created by generation.

Knowledge is promoted from signed, verified, governed artifacts.

```txt
Observation
  -> Discussion
    -> Claim
      -> Documentation
        -> Signed Artifact
          -> Verification
            -> Knowledge Candidate
              -> Governance Approval
                -> Knowledge
```

Cannot become knowledge directly:

```txt
Chat messages
Raw memories
Unverified claims
Draft documents
Unsigned artifacts
Temporary context
Model outputs
Tool outputs
Logs
Search results
Opinions
Assumptions
RAG chunks
```

Can support knowledge:

```txt
Evidence
Artifacts
Citations
Source anchors
Verification checks
Decision records
Evaluation reports
Signed documents
```

Can become knowledge after promotion:

```txt
Signed decision record
Signed policy document
Verified incident report
Approved evaluation report
Signed contract
Governed runbook
Verified research note
Approved architecture decision record
Audited compliance evidence
```

Knowledge requires:

```txt
documentation
signature
provenance
evidence
owner
version
verification state
governance approval
canonical source anchor when applicable
```

## Public canonical source of truth

If a public canonical source exists, knowledge must cite it.

If no public canonical source exists, knowledge must cite the best available accountable source.

If no accountable source exists, the item remains claim/evidence/artifact, not canonical knowledge.

Examples of canonical sources:

```txt
Government statute or regulation page
Official standards body publication
Official protocol specification
Official product documentation
Official API documentation
Official public registry
Official court/public filing
Official security advisory
Official research paper or DOI page
Official organizational policy repository
Official signed release notes
```

Canonical source anchor fields:

```txt
source_url
source_type
source_authority
source_publisher
source_version
source_published_at
source_accessed_at
source_hash
source_license
source_retrieval_method
source_confidence
```

## Memory and RAG model

Memory is not knowledge.

RAG chunks are not knowledge.

Agents store memory and indexes to reconstruct context when needed.

Memory is limited by:

```txt
hardware
storage
context window
latency
retrieval cost
privacy policy
data retention policy
security policy
```

Therefore:

```txt
Store the minimum sufficient state.
Reconstruct the rest when needed.
```

If it is reconstructable, storing the full thing is not required.

Minimum sufficient state means:

```txt
Can we find it?
Can we access it?
Can we reconstruct it?
Can we verify source?
Can we explain provenance?
Can we respect policy?
Can we reproduce the decision context?
```

Agents store:

```txt
summary
state snapshot
working context
source anchor
artifact pointer
knowledge pointer
RAG index pointer
chunk pointer
retrieval query
reconstruction instruction
decay policy
retention policy
confidence score
last accessed time
```

Example:

```txt
Do not store the full monthly calendar in memory.
Store today's schedule as working context.
Store the calendar tool reference, source anchor, query, timezone, and reconstruction instruction.
Reconstruct the week/month from the calendar source when needed.
```

Final memory rule:

```txt
Memory stores what is needed to reconstruct useful context, not everything that happened.
```

## Government policy model

Government policy must be anchored to official government or regulator sources when available.

Examples:

```txt
Official gazette
Official legislation portal
Regulator website
Court filing portal
Public procurement portal
Standards authority
Tax authority
Data protection authority
Sector regulator
```

Media summaries, blogs, and model-generated interpretations are not canonical government policy.

They may be used as discussion or analysis artifacts only.

## Industry model

Industry-specific work definitions should be organization-controlled but can be initialized from industry templates.

Industry model fields:

```txt
industry
sector
subsector
domain
work_type
unit_of_work_definition
standard_protocols
standard_artifacts
standard_evidence
standard_sla
standard_risks
standard_controls
standard_metrics
canonical_sources
```

Examples:

```txt
Software
Support
Sales
Research
Healthcare
Banking
Insurance
Public sector
Manufacturing
Retail
Education
Legal
Cybersecurity
Logistics
Energy
Telecom
```

## Database-native without vendor lock-in

The runtime may be database-native without becoming vendor-locked.

Rule:

```txt
Use database-native enforcement for correctness, integrity, validation, indexing, relations, events, and transactional state.
Keep the operational model portable through explicit schemas, documented semantics, open protocols, and exportable artifacts.
```

Database-native means:

```txt
schema enforcement
record-level relations
indexes
constraints
events
functions
transactional consistency
queryable operational graph
```

No vendor lock-in means:

```txt
canonical model documented outside the database
schemas versioned in Git
protocols open
artifacts exportable
evidence portable
knowledge source-anchored
runtime behavior tested
migration path documented
```

## Freeze rule

Do not add more conceptual primitives before validation.

Allowed work:

```txt
validate
fix schema errors
fix scripts
fix CI
fix docs to match actual validation
produce validation report
```

Blocked work:

```txt
new schemas
new platform modules
new UI
new marketplace
new payment providers
new deployment architecture
new capability hierarchy changes
```

## Required validation

Deployment readiness depends on:

```bash
cd packages/agent-db-runtime
make check
```

Tracked by:

```txt
#14 Runtime validation gate
#16 First validation report
#17 Delivery checklist
#18 Validation agent instruction set
```
