# Agent DB Runtime Qualification Model

Status: draft, aligned with Frozen Framework v0.1, Card Model, Card Meta Model, Discovery Model, and Recommendation Model.

## Purpose

Qualification is the step that determines whether a card is even worth considering before eligibility, recommendation, selection, or rejection.

```txt
Discovery
  -> Qualification
    -> Eligibility
      -> Recommendation
        -> Selection / Rejection
```

## Core rule

```txt
Qualification determines whether a candidate is relevant enough to enter eligibility evaluation.
Eligibility determines whether it is allowed to be used.
Recommendation determines whether it should be preferred.
Selection commits the choice.
```

## Qualification answers

```txt
Is this candidate relevant?
Does it match the requested capability?
Does it support the required interface?
Does it belong to the right domain?
Does it have enough documentation?
Does it expose enough evidence?
Does it have a card?
Is the card signed?
Is it in scope for deeper eligibility evaluation?
```

## Qualification object model

```txt
QualificationRequest
  describes the need, task, scope, domain, capability, and minimum metadata required

QualificationCandidate
  card or registry entry being considered

QualificationCriteria
  relevance, capability match, interface match, documentation sufficiency, evidence sufficiency, domain fit

QualificationResult
  qualified / not-qualified / needs-more-information

QualificationReason
  why candidate qualified or failed qualification
```

## Qualification criteria

Common criteria:

```txt
card exists
card kind matches need
card status is not revoked
capability description matches request
required interface present
required protocol declared
required documentation present
evidence references present
owner/publisher/provider present
version present
scope match possible
source/provenance available
```

## Qualification vs eligibility

```txt
Qualification = relevant enough to evaluate
Eligibility = allowed enough to use
Recommendation = preferred enough to suggest
Selection = chosen enough to execute
```

Example:

```txt
Candidate ToolCard: Browser Tool
  Qualification: yes, can interact with web pages
  Eligibility: no, project policy requires GitHub API not browser automation
  Recommendation: no
  Selection: rejected with reason
```

## Qualification states

```txt
unknown
qualified
not-qualified
needs-more-information
insufficient-documentation
insufficient-evidence
wrong-scope
wrong-interface
wrong-domain
revoked
```

## Card field addition

Cards may include qualification metadata:

```yaml
qualification:
  qualified: false
  qualificationState: unknown | qualified | not-qualified | needs-more-information
  qualifiedFor: []
  criteria: []
  qualificationEvidence: []
  qualificationReasons: []
  disqualificationReasons: []
  lastQualifiedAt: null
```

## Runtime mapping

```txt
QualificationRequest  -> action_invocation / task context
QualificationCandidate -> registry_entry + card
QualificationCriteria -> schema_definition + governance_object
QualificationResult   -> verification_check + decision
QualificationReason   -> decision rationale + evidence
```

## Example: tool qualification

```txt
Need: create GitHub issue
Candidate: GitHub ToolCard

Qualification:
  card exists: yes
  tool kind: yes
  supports IssueInterface: yes
  has documentation source: yes
  has provider: yes
  has protocol: yes

Result: qualified
```

## Example: skill qualification

```txt
Need: validate SurrealDB schema
Candidate: GitHub Issue Management Skill

Qualification:
  card exists: yes
  skill kind: yes
  capability match: no
  required interface: no

Result: not-qualified
Reason: wrong capability domain
```

## Final rule

```txt
Discovery finds possible candidates.
Qualification filters for relevance.
Eligibility filters for allowed use.
Recommendation ranks and explains preference.
Selection commits a choice.
Rejection explains why a candidate was not chosen.
```
