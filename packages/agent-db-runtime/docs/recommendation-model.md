# Agent DB Runtime Recommendation Model

Status: draft, aligned with Frozen Framework v0.1, Card Model, Card Meta Model, and Discovery Model.

## Purpose

Recommendation sits between Discovery and Selection.

Discovery finds candidate cards.
Recommendation explains which candidate should be preferred, why, with what confidence, and what alternatives were considered.

```txt
Discovery
  -> Candidate Cards
    -> Recommendation
      -> Selection / Rejection
```

## Core rule

```txt
Recommendation must explain ranking, trade-offs, confidence, alternatives, risks, and rejection reasons.
```

A recommendation is not execution.

A recommendation is a decision-support artifact that may lead to selection.

## Recommendation flow

```txt
Need / Intent / Task
  -> Discovery Query
    -> Candidate Cards
      -> Eligibility Filter
        -> Ranking
          -> Recommendation
            -> Decision
              -> Selection / Rejection
                -> Evidence Logged
```

## Recommendation object model

```txt
RecommendationRequest
  describes the need, task, project scope, milestone, constraints, and evaluation criteria

RecommendationCandidate
  candidate card with eligibility, scores, ratings, reviews, evidence, and risks

RecommendationRanking
  ranked ordering of candidates

RecommendationRationale
  explanation for preferred and rejected candidates

RecommendationConfidence
  confidence score and uncertainty reasons

RecommendationDecision
  selected or rejected recommendation outcome
```

## Recommendation criteria

A recommendation should consider:

```txt
project scope
milestone deadline
task requirement
unit of work
card eligibility
signed card status
verified capability status
allowed protocols
required interfaces
available tools
available operators
trust score
quality score
safety score
compliance score
performance score
cost-efficiency score
freshness score
ratings
reviews
incident history
SLA state
risk level
evidence strength
source authority
policy fit
availability
latency
cost
```

## Recommendation card fields

Cards should support recommendation metadata through the card meta-model.

```yaml
recommendation:
  recommended: false
  recommendedFor: []
  recommendedBy: null
  recommendedAt: null
  recommendationReason: null
  confidence: null
  alternativesConsidered: []
  tradeoffs: []
  risks: []
  rejectionReasonsForAlternatives: []
  evidence: []
```

## Ranking model

Ranking should not be a hidden score.

Ranking must explain dimensions.

```txt
Rank = weighted fit across eligibility, trust, policy, capability, performance, cost, risk, and evidence.
```

Example:

```txt
Candidate A ranked higher because:
  - verified capability
  - supports required protocol
  - eligible for project scope
  - higher trust score
  - lower incident history
  - stronger evidence

Candidate B rejected because:
  - protocol not allowed
  - capability unverified
  - SLA degraded
```

## Recommendation vs selection

```txt
Recommendation = suggested choice with rationale
Selection = committed choice with decision record
```

A recommendation may be rejected by a human, operator, policy, or runtime decision.

## Recommendation evidence

Every recommendation should link to evidence:

```txt
candidate cards
scores
ratings
reviews
policy evaluations
trust assessments
incidents
SLA records
performance evaluations
source anchors
```

## Runtime mapping

```txt
RecommendationRequest  -> action_invocation / task context
RecommendationCandidate -> registry_entry + card
RecommendationRanking  -> evaluation_metric
RecommendationRationale -> decision rationale / artifact
RecommendationDecision -> decision
RecommendationEvidence -> artifact / evidence / verification_check
Selection              -> decision + action_invocation
Rejection              -> decision + issue when needed
```

## Example: tool recommendation

```txt
Task: Create a GitHub issue
  Discovery finds:
    - GitHub ToolCard
    - Generic HTTP ToolCard
    - Browser ToolCard

Recommendation:
  Preferred: GitHub ToolCard
  Reason:
    - supports IssueInterface
    - verified capability
    - project allows GitHub tool
    - lower risk than browser automation
    - stronger documentation-derived skill

Rejected:
  Generic HTTP ToolCard
    reason: less specific interface and weaker evidence

  Browser ToolCard
    reason: higher fragility and higher operational risk
```

## Example: operator recommendation

```txt
Task: Validate Agent DB Runtime
  Discovery finds:
    - code-agent.operator
    - documentation-agent.operator
    - governance-agent.operator

Recommendation:
  Preferred: code-agent.operator
  Reason:
    - required tools include GitHub, Podman, SurrealDB, npm
    - task requires execution not just documentation
    - operator has compatible skills
```

## Final rule

```txt
Discovery finds candidates.
Recommendation explains preferred candidates and alternatives.
Selection commits a choice.
Rejection records why alternatives were not chosen.
All must leave evidence.
```
