# Agent DB Runtime Card Model

Status: draft, aligned with Frozen Framework v0.1.

## Core rule

Everything has a card.

A card is the portable identity, description, governance, provenance, and operational metadata document for a runtime object.

```txt
Entity
  has Card

Platform
  has PlatformCard

Artifact
  has ArtifactCard

Tool
  has ToolCard

Skill
  has SkillCard

Operator
  has OperatorCard

Project
  has ProjectCard

Milestone
  has MilestoneCard

Task
  has TaskCard

Knowledge
  has KnowledgeCard

Protocol
  has ProtocolCard
```

## Card purpose

A card answers:

```txt
What is it?
Who owns it?
Who published it?
Who can use it?
What version is it?
What status is it in?
What does it depend on?
What policy governs it?
What evidence supports it?
What protocols does it use?
What interfaces does it expose?
What risks exist?
What trust level does it have?
Can it be executed, cited, reused, promoted, or retired?
```

## Recommended language and version

```txt
Authoring language: YAML
Machine format: JSON / JSON-LD
Schema vocabulary: schema.org + AGenNext runtime schema
Version: agennext.io/card/v0.1
```

## Base card shape

```yaml
apiVersion: agennext.io/card/v0.1
kind: Card

metadata:
  id: string
  name: string
  displayName: string
  description: string
  version: string
  status: draft | active | deprecated | archived
  owner: string
  publisher: string
  provider: string
  createdAt: datetime
  updatedAt: datetime
  tags: []
  labels: []

governance:
  policies: []
  approvals: []
  riskLevel: low | medium | high | critical
  compliance: []
  evidenceRequired: true
  reviewRequired: false

provenance:
  source: string
  sourceType: string
  sourceAuthority: string
  sourceVersion: string
  sourceUrl: string
  sourceHash: string
  sourceAccessedAt: datetime

trust:
  trustLevel: unknown | low | medium | high | verified
  score: number
  verificationState: unverified | pending | verified | disputed | revoked
  lastEvaluatedAt: datetime

evidence:
  artifacts: []
  signatures: []
  evaluations: []
  decisions: []
  claims: []

interfaces: []
protocols: []
dependencies: []
relationships: []
```

## Card kinds

```txt
PlatformCard
EntityCard
ArtifactCard
ToolCard
ToolkitCard
SkillCard
OperatorCard
ProjectCard
MilestoneCard
TaskCard
ProtocolCard
InterfaceCard
ApiCard
KnowledgeCard
MemoryCard
DecisionCard
EvidenceCard
PolicyCard
IssueCard
IncidentCard
AssuranceCard
InsuranceCard
CommitmentCard
SlaCard
WorkDefinitionCard
UnitOfWorkCard
```

## Card rules

### 1. Cards are descriptors, not always the object itself

A card describes an object. The object may be a database record, artifact, protocol, external system, agent, tool, or signed document.

### 2. Cards must be versioned

Every card must include:

```txt
apiVersion
kind
metadata.version
metadata.status
```

### 3. Cards must carry ownership

Every card must identify:

```txt
owner
publisher
provider
accountable authority when applicable
```

### 4. Cards must carry governance

Cards must link to governing policies and evidence requirements.

### 5. Cards are not knowledge by default

A card can describe a knowledge artifact, but the card itself does not automatically make something knowledge.

Knowledge still requires:

```txt
documented artifact
signature
provenance
evidence
verification
governance approval
canonical source anchor when available
```

### 6. Cards support portability

Cards help avoid vendor lock-in by keeping runtime semantics outside a single database engine.

## ArtifactCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: ArtifactCard

metadata:
  id: artifact:example
  name: example-artifact
  displayName: Example Artifact
  version: 0.1.0
  status: draft
  owner: identity:owner
  publisher: identity:publisher
  provider: identity:provider

artifact:
  artifactType: document
  mediaType: text/markdown
  uri: ./artifacts/example.md
  hash: sha256:...
  signed: false
  signatureRef: null
  documentationStatus: draft
  promotionEligibleForKnowledge: false

knowledgePolicy:
  canBecomeKnowledge: false
  reason: unsigned-unverified-artifact
  requiredForPromotion:
    - signature
    - verification
    - governanceApproval
    - canonicalSourceAnchor
```

## ToolCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: ToolCard

metadata:
  id: tool:github
  name: github-tool
  displayName: GitHub Tool
  version: 0.1.0
  status: active
  owner: identity:platform
  publisher: identity:platform
  provider: GitHub

tool:
  toolType: external-system
  outsideKernel: true
  dataSource: true
  evidenceSource: true
  reconstructionSource: true
  documentationSource: https://docs.github.com
  supportedOperations:
    - github.issue.create
    - github.pull_request.create
    - github.workflow.read

interfaces:
  - IssueInterface
  - PullRequestInterface
  - WorkflowInterface

protocols:
  - HTTP
  - Webhook
  - MCP

skillSource:
  documentationDerived: true
  skills:
    - github-issue-management
    - pull-request-review
    - ci-failure-triage
```

## SkillCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: SkillCard

metadata:
  id: skill:github-issue-management
  name: github-issue-management
  displayName: GitHub Issue Management Skill
  version: 0.1.0
  status: draft
  owner: identity:platform

skill:
  description: Create, update, triage, and link GitHub issues using documented GitHub tool behavior.
  derivedFromDocumentation:
    - tool:github
  requiredTools:
    - tool:github
  requiredOperators:
    - operator:agent.issue_operator
  requiredInterfaces:
    - IssueInterface
  evaluationCriteria:
    - issue-created
    - correct-labels
    - linked-to-parent-work
    - evidence-logged
```

## OperatorCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: OperatorCard

metadata:
  id: operator:agent.issue_operator
  name: agent-issue-operator
  displayName: Agent Issue Operator
  version: 0.1.0
  status: active
  owner: identity:platform

operator:
  operatorType: agent
  identity: identity:agent.issue_operator
  executesSkills:
    - skill:github-issue-management
  allowedTools:
    - tool:github
  decisionRequired: true
  evidenceRequired: true
  trustRequired: medium
```

## ProjectCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: ProjectCard

metadata:
  id: project:agent-db-runtime-validation
  name: agent-db-runtime-validation
  displayName: Agent DB Runtime Validation
  version: 0.1.0
  status: active
  owner: identity:platform

project:
  scope: packages/agent-db-runtime
  included:
    - schema validation
    - live SurrealDB apply
    - seed
    - smoke
  excluded:
    - new schemas
    - platform UI
    - payment provider integration
  allowedTools:
    - tool:surrealdb
    - tool:podman
    - tool:github
  allowedOperators:
    - operator:code-agent
  successCriteria:
    - make-check-passes
    - validation-report-posted
```

## MilestoneCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: MilestoneCard

metadata:
  id: milestone:runtime-validation-v0.1
  name: runtime-validation-v0.1
  displayName: Runtime Validation v0.1
  version: 0.1.0
  status: active

milestone:
  project: project:agent-db-runtime-validation
  deadline: null
  deliverables:
    - Agent DB Runtime Validation Report v0.1
  acceptanceCriteria:
    - make-check-executed
    - first-failure-captured
    - follow-up-fix-created
```

## TaskCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: TaskCard

metadata:
  id: task:run-make-check
  name: run-make-check
  displayName: Run make check
  version: 0.1.0
  status: open

task:
  project: project:agent-db-runtime-validation
  milestone: milestone:runtime-validation-v0.1
  workDefinition: work-definition:runtime-validation
  plannedUnits: 1
  completedUnits: 0
  progress: 0
  command: |
    cd packages/agent-db-runtime
    make check
  evidenceRequired: true
```

## KnowledgeCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: KnowledgeCard

metadata:
  id: knowledge:example
  name: example-knowledge
  displayName: Example Knowledge
  version: 0.1.0
  status: candidate

knowledge:
  sourceArtifact: artifact:example
  canonicalSourceAnchor: null
  signed: false
  verified: false
  governanceApproved: false
  canBecomeCanonical: false
```

## WorkDefinitionCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: WorkDefinitionCard

metadata:
  id: work-definition:runtime-validation
  name: runtime-validation
  displayName: Runtime Validation Work Definition
  version: 0.1.0
  status: active

workDefinition:
  organization: AGenNext
  unitName: validation-cycle
  unitDescription: One validation cycle that runs install, static validation, live apply, seed, and smoke.
  measurementRule: completed validation gates / planned validation gates
  evidenceRequired:
    - command output
    - failure logs
    - validation report
  completionCriteria:
    - make-check-passes-or-first-failure-reported
```

## PlatformCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: PlatformCard

metadata:
  id: platform:agennext-agent-platform
  name: agennext-agent-platform
  displayName: AGenNext Agent Platform
  version: 0.1.0
  status: validation
  owner: AGenNext
  repository: AGenNext/Agent-Platform

platform:
  primaryPackage: packages/agent-db-runtime
  frozenFramework: packages/agent-db-runtime/docs/frozen-framework-v0.1.md
  deploymentReady: false
  productionReady: false
  nextArtifact: Agent DB Runtime Validation Report v0.1
```

## Final rule

```txt
Everything has a card.
Cards describe identity, governance, provenance, evidence, trust, interfaces, protocols, dependencies, and lifecycle.
Cards do not automatically create knowledge.
Knowledge still requires signed, verified, governed artifact promotion.
```
