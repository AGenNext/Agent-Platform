# Agent DB Runtime Card Meta Model

Status: draft, aligned with Frozen Framework v0.1 and Card Model v0.1.

## Purpose

This document defines the reusable meta-model that every card can use for:

```txt
eligibility
selection
rejection
scores
ratings
reviews
performance evaluation
re-evaluation
```

The Card is not only a descriptor. It is also the decision surface for whether a runtime object may be selected, executed, promoted, certified, rejected, retired, or re-evaluated.

## Core rule

```txt
Card defines eligibility.
Card records score.
Card records rating.
Card records review.
Card records selection reason.
Card records rejection reason.
Card triggers performance re-evaluation.
```

## Meta-model shape

```yaml
eligibility:
  eligible: false
  eligibilityState: unknown | eligible | ineligible | conditionally-eligible | suspended
  eligibleFor:
    - execution
    - selection
    - recommendation
    - promotion
    - publication
    - certification
  requiredConditions: []
  blockingConditions: []
  policyRequirements: []
  minimumTrustLevel: null
  minimumScore: null
  allowedScopes: []
  allowedProjects: []
  allowedEnvironments: []
  allowedProtocols: []
  rejectionReasons: []

selection:
  selected: false
  selectedFor: []
  selectedBy: null
  selectedAt: null
  selectionReason: null
  selectionEvidence: []
  rejected: false
  rejectedBy: null
  rejectedAt: null
  rejectionReasons: []
  alternativesConsidered: []

scores:
  overall: null
  trust: null
  quality: null
  reliability: null
  safety: null
  compliance: null
  performance: null
  costEfficiency: null
  freshness: null
  usability: null
  evidenceStrength: null
  lastScoredAt: null
  scoringMethod: null

ratings:
  average: null
  count: 0
  distribution: {}
  lastRatedAt: null

reviews:
  reviewRequired: false
  reviewState: not-reviewed | pending | reviewed | disputed | rejected
  reviews: []
  lastReviewedAt: null
  nextReviewAt: null

performance:
  lastEvaluatedAt: null
  nextEvaluationAt: null
  evaluationFrequency: null
  performanceState: unknown | passing | degraded | failing | suspended
  metrics: []
  incidents: []
  slaBreaches: []
  reEvaluationTriggers:
    - schedule
    - incident
    - policy-change
    - version-change
    - poor-rating
    - trust-drop
    - user-complaint
```

## Eligibility

Eligibility answers:

```txt
Can this card be used?
Can it be selected?
Can it be executed?
Can it be recommended?
Can it be promoted?
Can it be published?
Can it be certified?
```

Eligibility depends on:

```txt
policy
scope
project
milestone
environment
protocol
trust level
score
verification state
risk level
approval state
incident history
SLA state
```

## Selection

Selection records why a card was chosen.

Examples:

```txt
Tool selected because it supports required protocol.
Skill selected because it has highest trust score.
Operator selected because it is eligible for the project scope.
Artifact selected because it is signed and verified.
Protocol selected because organization policy allows it.
```

A selection must record:

```txt
selectedBy
selectedAt
selectedFor
selectionReason
selectionEvidence
alternativesConsidered
```

## Rejection

Rejection records why a card was not chosen.

Examples:

```txt
Rejected because trust score below threshold.
Rejected because protocol is not allowed for this organization.
Rejected because card is unsigned.
Rejected because capability is unverified.
Rejected because SLA is degraded.
Rejected because tool is unavailable.
Rejected because scope does not match project.
Rejected because evidence is missing.
```

A rejection must record:

```txt
rejectedBy
rejectedAt
rejectionReasons
blockingConditions
alternativesConsidered
```

## Scores

Scores are system/evaluation-derived measurements.

Standard score dimensions:

```txt
overall
trust
quality
reliability
safety
compliance
performance
costEfficiency
freshness
usability
evidenceStrength
```

Scores must be traceable to:

```txt
scoring method
evaluation
metric
source evidence
time
version
```

## Ratings

Ratings are reviewer, user, operator, or organization-provided assessments.

Ratings are not the same as scores.

```txt
Score = computed or evaluation-derived
Rating = reviewer/user/operator-provided
Review = qualitative assessment with evidence and comments
```

## Reviews

Reviews document qualitative assessment.

A review may include:

```txt
reviewer
reviewedAt
rating
comments
evidence
risks
recommendation
approval/rejection
follow-up actions
```

## Performance re-evaluation

Cards must be re-evaluated over time.

Triggers:

```txt
schedule
incident
SLA breach
policy change
version change
poor rating
trust drop
user complaint
security finding
compliance finding
new evidence
source supersession
```

Re-evaluation may result in:

```txt
keep active
suspend
revoke
deprecate
require approval
lower score
raise score
request evidence
open issue
report incident
update SLA state
```

## Card lifecycle with meta-model

```txt
Draft Card
  -> Submitted Card
    -> Eligibility Check
      -> Registry Platform Review
        -> Signed Card
          -> Verification
            -> Verified Capability
              -> Selection / Rejection
                -> Runtime Use
                  -> Evidence Logging
                    -> Evaluation
                      -> Score / Rating / Review
                        -> Re-evaluation
                          -> Continue / Suspend / Revoke / Deprecate
```

## Runtime mapping

```txt
Eligibility        -> governance_object + policy_evaluation + verification_check
Selection          -> decision + action_invocation + evidence
Rejection          -> decision + issue / claim when needed
Score              -> evaluation_metric + trust_assessment
Rating             -> evaluation / review artifact
Review             -> artifact + evaluation + decision
Performance        -> evaluation + task + incident + SLA
Re-evaluation      -> task + workflow_run + evaluation + trust_event
```

## Final rule

```txt
Cards are the selection surface.
Cards must explain eligibility, selection, rejection, score, rating, review, and re-evaluation.
A signed card is registry-issued.
A verified capability is evidence-proven.
A selected card must explain why it was selected.
A rejected card must explain why it was rejected.
```
