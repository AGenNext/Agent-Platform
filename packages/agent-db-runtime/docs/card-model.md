# Agent DB Runtime Card Model

Status: draft, aligned with Frozen Framework v0.1.

## Core rule

Everything has a card.

A card is the portable identity, description, governance, provenance, signature, verification, and operational metadata document for a runtime object.

```txt
Signed Card
  = registry-issued card with signature and provenance

Verified Capability
  = capability whose card is signed by the Registry Platform and whose evidence passes verification

Registry Platform
  = issuer of signed cards and authority for registry publication, certification, deprecation, and revocation
```

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
Who issued the card?
Who signed it?
Who verified it?
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
Issuer: Registry Platform
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
  status: draft | active | deprecated | archived | revoked
  owner: string
  issuer: registry-platform
  publisher: string
  provider: string
  createdAt: datetime
  updatedAt: datetime
  tags: []
  labels: []

signature:
  signed: false
  issuer: registry-platform
  issuerCard: platform-card:registry-platform
  signatureRef: null
  signedAt: null
  signingKeyRef: null
  signatureAlgorithm: null
  digest: null

verification:
  verified: false
  verifiedBy: null
  verifiedAt: null
  verificationMethod: null
  verificationEvidence: []
  capabilityVerified: false
  verificationState: unverified | pending | verified | disputed | revoked

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
RegistryPlatformCard
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

### 3. Cards must be issued by the Registry Platform

A card can be drafted by a user, operator, or system, but it becomes an official runtime card only when issued by the Registry Platform.

```txt
Draft Card
  -> Submitted Card
    -> Registry Platform Review
      -> Signed Card
        -> Verified Capability when evidence passes
```

### 4. Signed cards represent registry acceptance

A signed card means:

```txt
Registry Platform issued this card.
Card identity and provenance were recorded.
Card version is known.
Card lifecycle is now governed.
```

A signed card does not automatically mean the capability is verified.

### 5. Verified capability requires signed card plus evidence

```txt
Verified Capability
  = Signed Card
  + Verification Evidence
  + Passing Evaluation
  + Governance Approval when required
```

### 6. Cards must carry ownership

Every card must identify:

```txt
owner
issuer
publisher
provider
accountable authority when applicable
```

### 7. Cards must carry governance

Cards must link to governing policies and evidence requirements.

### 8. Cards are not knowledge by default

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

### 9. Cards support portability

Cards help avoid vendor lock-in by keeping runtime semantics outside a single database engine.

## RegistryPlatformCard

```yaml
apiVersion: agennext.io/card/v0.1
kind: RegistryPlatformCard

metadata:
  id: platform-card:registry-platform
  name: registry-platform
  displayName: Registry Platform
  version: 0.1.0
  status: validation
  owner: AGenNext
  issuer: registry-platform

registryPlatform:
  role: card-issuer
  responsibilities:
    - issue-cards
    - sign-cards
    - verify-capabilities
    - publish-registry-entries
    - certify-registry-entries
    - deprecate-registry-entries
    - revoke-cards
  signaturePolicy:
    required: true
    algorithm: TBD
    keyManagement: TBD
  verificationPolicy:
    evidenceRequired: true
    evaluationRequired: true
    governanceApprovalRequiredWhenRiskHigh: true
```

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
  issuer: registry-platform
  publisher: identity:publisher
  provider: identity:provider

signature:
  signed: false
  issuer: registry-platform
  signatureRef: null

verification:
  verified: false
  capabilityVerified: false
  verificationState: unverified

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
  issuer: registry-platform
  publisher: identity:platform
  provider: GitHub

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:github-tool-card-v0.1

verification:
  verified: true
  verifiedBy: registry-platform
  verificationEvidence:
    - artifact:github-docs-source-anchor
    - evaluation:github-tool-smoke-test
  capabilityVerified: true
  verificationState: verified

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
  issuer: registry-platform

signature:
  signed: false
  issuer: registry-platform
  signatureRef: null

verification:
  verified: false
  capabilityVerified: false
  verificationState: pending

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
  issuer: registry-platform

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:agent-issue-operator-card-v0.1

verification:
  verified: true
  capabilityVerified: true
  verificationState: verified

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
  issuer: registry-platform

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:agent-db-runtime-validation-project-card-v0.1

verification:
  verified: true
  capabilityVerified: false
  verificationState: verified

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
  issuer: registry-platform

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:runtime-validation-v0.1-milestone-card

verification:
  verified: true
  capabilityVerified: false
  verificationState: verified

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
  issuer: registry-platform

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:run-make-check-task-card-v0.1

verification:
  verified: true
  capabilityVerified: false
  verificationState: verified

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
  issuer: registry-platform

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:knowledge-card-example-v0.1

verification:
  verified: false
  capabilityVerified: false
  verificationState: pending

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
  issuer: registry-platform

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:runtime-validation-work-definition-card-v0.1

verification:
  verified: true
  capabilityVerified: false
  verificationState: verified

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
  issuer: registry-platform
  repository: AGenNext/Agent-Platform

signature:
  signed: true
  issuer: registry-platform
  signatureRef: signature:agennext-agent-platform-card-v0.1

verification:
  verified: true
  capabilityVerified: false
  verificationState: verified

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
The Registry Platform is the issuer of signed cards.
A signed card means the card is accepted into registry governance.
A verified capability means the signed card has passed evidence-based verification.
Cards describe identity, governance, provenance, evidence, trust, interfaces, protocols, dependencies, and lifecycle.
Cards do not automatically create knowledge.
Knowledge still requires signed, verified, governed artifact promotion.
```
