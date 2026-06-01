# Agent DB Runtime Accreditation Model

Status: draft, aligned with Frozen Framework v0.1, Card Model, Certification Model, and Registry Platform model.

## Purpose

Accreditation governs authorities.

Certification governs capabilities.

```txt
Capability is certified.
Authority is accredited.
```

A certified tool, skill, operator, protocol, artifact, or knowledge source is approved for scoped use.

An accredited registry, issuer, reviewer, evaluator, certifier, or standards authority is trusted to issue, verify, certify, review, or evaluate within a defined scope.

## Core rule

```txt
Certification approves a verified capability for scoped use.
Accreditation approves an authority to certify, review, evaluate, issue, or govern within scoped authority.
```

## Accreditation chain

```txt
Registry Platform
  -> issues Signed Cards
    -> verifies Capabilities
      -> certifies Capabilities
        -> accredits Authorities
          -> delegates scoped trust
```

## Accreditation answers

```txt
Who is allowed to issue cards?
Who is allowed to sign cards?
Who is allowed to verify capabilities?
Who is allowed to certify capabilities?
Who is allowed to review ratings and evaluations?
Who is allowed to approve knowledge promotion?
Who is allowed to define standards or policies?
For which scope is this authority trusted?
When does accreditation expire?
What evidence supports accreditation?
```

## Accreditation object model

```txt
AccreditationRequest
  request to recognize an authority for scoped trust

AccreditedAuthority
  organization, registry, certifier, reviewer, evaluator, standards body, source authority, or governance body

AccreditationScope
  domain, industry, jurisdiction, protocol, capability class, risk class, organization, environment

AccreditationEvidence
  charter, legal status, prior performance, reviews, audits, certifications, source anchors, policy approval

AccreditationDecision
  approved / conditional / rejected / suspended / revoked / expired

AccreditationRecord
  durable record of authority, scope, evidence, issuer, expiry, and conditions
```

## Accreditation states

```txt
not-accredited
requested
under-review
accredited
conditionally-accredited
rejected
suspended
revoked
expired
requires-reaccreditation
```

## Card field addition

Cards for authorities may include accreditation metadata:

```yaml
accreditation:
  accredited: false
  accreditationState: not-accredited | requested | under-review | accredited | conditionally-accredited | rejected | suspended | revoked | expired | requires-reaccreditation
  accreditedBy: null
  accreditedAt: null
  expiresAt: null
  accreditationScope:
    organizations: []
    industries: []
    domains: []
    jurisdictions: []
    protocols: []
    capabilityClasses: []
    riskLevels: []
    environments: []
  conditions: []
  evidence: []
  rejectionReasons: []
  reaccreditationRequired: false
  nextReaccreditationAt: null
```

## Certification vs accreditation

```txt
Signed Card
  = Registry Platform issued the card

Verified Capability
  = evidence proves the capability works

Certified Capability
  = governance approves capability for scoped use

Accredited Authority
  = governance approves an authority to issue, verify, certify, review, evaluate, or govern within scope
```

## Authority types

```txt
Registry Platform
Card Issuer
Card Signer
Capability Verifier
Capability Certifier
Evaluator
Reviewer
Auditor
Policy Authority
Standards Authority
Knowledge Authority
Source Authority
Industry Authority
Government Authority
Compliance Authority
Security Authority
SLA Authority
Insurance Authority
```

## Accreditation criteria

Accreditation should evaluate:

```txt
identity verification
legal/accountable authority
scope of authority
source provenance
track record
conflict of interest
policy alignment
security controls
privacy controls
compliance controls
audit history
incident history
review quality
certification quality
trust score
reputation
public canonical source anchors
revocation history
```

## Delegated trust

Accreditation enables delegated trust.

Example:

```txt
AGenNext Registry Platform
  accredits CNCF as Standards Authority for cloud-native project metadata
    cards citing CNCF standards may inherit source authority within that scope
```

Another example:

```txt
Organization Registry
  accredits Internal Security Team as Capability Certifier for production tools
    Security Team may certify ToolCards for production use
```

## Accreditation and knowledge

Knowledge promotion may require accredited authorities.

```txt
Knowledge Candidate
  requires verified artifact
  requires governance approval
  may require accredited source authority
  may require accredited reviewer
```

## Accreditation and public canonical sources

Public canonical sources can act as source authorities, but the runtime should still record why the source is considered authoritative.

Examples:

```txt
Government regulator
Official standards body
Official API documentation publisher
Court/public filing portal
Official product vendor documentation
Research DOI publisher
```

## Re-accreditation

Accreditation expires or becomes stale.

Re-accreditation triggers:

```txt
scope change
policy change
jurisdiction change
incident
trust drop
poor review quality
certification failure
source authority change
organizational change
expired evidence
new regulation
```

## Runtime mapping

```txt
AccreditationRequest  -> task + governance_approval
AccreditedAuthority   -> identity + entity + registry_entry
AccreditationScope    -> governance_object + policy_evaluation
AccreditationEvidence -> artifact + evaluation + verification_check
AccreditationDecision -> decision + governance_approval
AccreditationRecord   -> registry_entry + card accreditation section
Reaccreditation       -> task + workflow_run + evaluation
```

## Example: accredit a registry

```txt
Authority: Organization Tool Registry
Scope: production tool certification for internal business applications
Evidence:
  - policy charter
  - reviewer identities
  - audit trail
  - certification workflow
Decision: accredited with annual review
```

## Example: accredit a standards source

```txt
Authority: Official Kubernetes Documentation
Scope: Kubernetes API and operational semantics
Evidence:
  - official source URL
  - publisher identity
  - source freshness
  - versioned documentation
Decision: accredited source authority for Kubernetes-related knowledge anchors
```

## Final rule

```txt
Certification approves capabilities.
Accreditation approves authorities.
Certified capabilities can be selected.
Accredited authorities can issue, verify, certify, review, evaluate, or govern within scoped authority.
```
