# Agent DB Runtime Certification Model

Status: draft, aligned with Frozen Framework v0.1, Card Model, Card Meta Model, Discovery, Qualification, and Recommendation.

## Purpose

Certification is the enterprise/governance layer above signed cards and verified capabilities.

A signed card means the Registry Platform issued the card.

A verified capability means evidence proves the card's capability.

A certified capability means the verified capability is approved for a defined scope, use case, organization, environment, protocol, risk level, and lifecycle.

```txt
Signed Card
  -> Verified Capability
    -> Certified Capability
      -> Eligible for governed recommendation and selection
```

## Core rule

```txt
Certification is scoped approval for use.
Verification proves the capability works.
Certification approves where and how it may be used.
```

## Certification answers

```txt
Is this capability approved for this organization?
Is it approved for this project scope?
Is it approved for this environment?
Is it approved for this protocol?
Is it approved for this risk level?
Is it approved for autonomous use?
Is human approval required?
When must it be re-certified?
What evidence supports certification?
```

## Certification object model

```txt
CertificationRequest
  request to certify a signed and verified card

CertificationScope
  organization, project, environment, protocol, data class, risk level, usage mode

CertificationEvidence
  tests, evaluations, reviews, policy results, incidents, source anchors, audit records

CertificationDecision
  approved / conditionally-approved / rejected / suspended / revoked

CertificationRecord
  durable record of certification state, scope, evidence, issuer, expiry, and conditions
```

## Certification states

```txt
not-certified
requested
under-review
certified
conditionally-certified
rejected
suspended
revoked
expired
requires-recertification
```

## Card field addition

Cards may include certification metadata:

```yaml
certification:
  certified: false
  certificationState: not-certified | requested | under-review | certified | conditionally-certified | rejected | suspended | revoked | expired | requires-recertification
  certifiedBy: null
  certifiedAt: null
  expiresAt: null
  certificationScope:
    organizations: []
    projects: []
    environments: []
    protocols: []
    riskLevels: []
    dataClasses: []
    usageModes: []
  conditions: []
  evidence: []
  rejectionReasons: []
  recertificationRequired: false
  nextRecertificationAt: null
```

## Certification vs related concepts

```txt
Signed Card
  = Registry Platform issued the card

Verified Capability
  = evidence proves the capability works

Certified Capability
  = governance approves the verified capability for scoped use

Eligible Card
  = certification/policy/trust/scope allow it to be considered

Recommended Card
  = ranked and preferred with rationale

Selected Card
  = chosen for execution with decision evidence
```

## Certification criteria

Certification should evaluate:

```txt
signed card status
verified capability status
owner/publisher/provider identity
provenance
source anchors
documentation quality
interface support
protocol conformance
security posture
privacy posture
compliance posture
performance evidence
SLA history
incident history
trust score
risk score
operator compatibility
tool compatibility
data residency
cost model
human approval requirement
re-evaluation frequency
```

## Certification and autonomy

Certification must state allowed autonomy level.

```txt
manual-only
human-approved
supervised-autonomous
autonomous-low-risk
autonomous-high-trust
not-autonomous
```

Example:

```txt
GitHub Issue Tool
  certified for: project issue creation
  environment: dev/staging
  autonomy: supervised-autonomous
  requires approval for: deleting issues, modifying protected labels
```

## Certification and re-certification

Certification expires or becomes stale.

Re-certification triggers:

```txt
version change
policy change
protocol change
security incident
SLA breach
trust drop
poor reviews
new compliance requirement
source documentation change
provider change
runtime change
```

## Runtime mapping

```txt
CertificationRequest  -> task + governance_approval
CertificationScope    -> governance_object + policy_evaluation
CertificationEvidence -> artifact + evaluation + verification_check
CertificationDecision -> decision + governance_approval
CertificationRecord   -> registry_entry + card certification section
Recertification       -> task + workflow_run + evaluation
```

## Example: certify a tool

```txt
ToolCard: GitHub Tool
  Signed: yes
  Verified Capability: yes
  Certification Request: certify for issue management in Agent DB Runtime validation project
  Evidence:
    - GitHub docs source anchor
    - smoke test result
    - policy evaluation
    - operator compatibility review
  Decision: certified with conditions
  Conditions:
    - only create/update issues
    - no repository deletion
    - evidence logging required
```

## Example: reject certification

```txt
ToolCard: Browser Tool
  Signed: yes
  Verified Capability: partial
  Certification Request: certify for GitHub issue creation
  Decision: rejected
  Rejection reasons:
    - higher fragility than GitHub API
    - weaker auditability
    - project policy prefers API tool
    - no need for browser automation
```

## Final rule

```txt
Verification proves capability.
Certification approves scoped use.
Certified capabilities are preferred for recommendation and selection.
Uncertified capabilities may still be discovered but should require explicit approval before use.
```
