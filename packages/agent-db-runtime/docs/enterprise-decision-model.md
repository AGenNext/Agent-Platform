# Agent DB Runtime Enterprise Decision Model

Status: draft enterprise layer extension.

## Purpose

Decision is the central object connecting enterprise intent, runtime execution, governance, evidence, value realization, learning, and improvement.

The runtime already records decisions as execution artifacts. This model elevates Decision as an enterprise object.

## Core rule

```txt
Every meaningful choice must be represented as a Decision.
Every Decision must explain context, options, tradeoffs, evidence, authority, impact, and outcome.
```

## Decision chain

```txt
Need / Opportunity / Risk / Obligation
  -> Decision
    -> Commitment
      -> Project / Policy / Investment / Selection / Action
        -> Evidence
          -> Evaluation
            -> Outcome
              -> ValueRealization
                -> Learning
                  -> Future Decision Improvement
```

## Decision answers

```txt
What was decided?
Why was it decided?
Who decided?
Who had authority?
What options were considered?
What was selected?
What was rejected?
What tradeoffs were accepted?
What evidence supported it?
What assumptions were used?
What risks were accepted?
What obligations were created?
What value was expected?
What outcome happened?
What did we learn?
```

## Decision types

```txt
strategic_decision
investment_decision
portfolio_decision
program_decision
project_decision
architecture_decision
policy_decision
governance_decision
risk_decision
compliance_decision
selection_decision
recommendation_decision
authorization_decision
certification_decision
accreditation_decision
knowledge_promotion_decision
incident_decision
claim_decision
value_decision
learning_decision
improvement_decision
```

## Decision object model

```txt
Decision
  links to Need / Opportunity / Risk / Obligation
  links to Goal / Objective / Strategy
  links to Project / Milestone / Task
  links to Options
  links to Selection
  links to Rejection
  links to Evidence
  links to Assumption / Hypothesis
  links to Risk
  links to Commitment
  links to Duty / Responsibility
  links to Policy / Control
  links to Outcome
  links to ValueRealization
  links to Learning
  links to Improvement
```

## Option model

```txt
Option
  candidate choice considered in a decision

SelectedOption
  chosen option

RejectedOption
  not chosen option with rejection reason
```

Every rejected option should record a rejection reason.

## Tradeoff model

```txt
Tradeoff
  value or risk accepted when choosing one option over another
```

Examples:

```txt
speed over cost
security over usability
standardization over flexibility
short-term delivery over long-term maintainability
automation over manual control
local-first over cloud convenience
```

## Authority model

Decisions require authority.

Authority may come from:

```txt
role
policy
accreditation
delegation
contract
law
regulation
ownership
approval workflow
```

Decision authority must be evidence-backed.

## Decision quality

A decision can be evaluated.

Decision quality dimensions:

```txt
clarity
traceability
evidence_strength
option_coverage
risk_awareness
policy_alignment
value_alignment
outcome_quality
reversibility
learning_quality
```

## Decision lifecycle

```txt
Proposed
  -> Discussed
    -> Evaluated
      -> Approved / Rejected / Deferred
        -> Executed
          -> Outcome Observed
            -> Value Evaluated
              -> Learned
                -> Reaffirmed / Revised / Reversed / Superseded
```

## Decision and knowledge

Decision records can become knowledge only through the knowledge promotion path.

```txt
Decision Record
  -> Documented Artifact
    -> Signed Artifact
      -> Verified Artifact
        -> Governed Knowledge Candidate
          -> Approved Knowledge
```

## Runtime mapping

```txt
Decision              -> decision table / artifact / event
Option                -> decision.option object
SelectedOption        -> selection
RejectedOption        -> rejection
Tradeoff              -> decision.tradeoffs
Authority             -> authorization_decision + policy_evaluation + accreditation
DecisionEvidence      -> evidence
DecisionOutcome       -> outcome + evaluation
DecisionLearning      -> learning_record
DecisionImprovement   -> improvement_candidate
```

## Events to add

```txt
agennext.decision.proposed.v0
agennext.decision.approved.v0
agennext.decision.rejected.v0
agennext.decision.deferred.v0
agennext.decision.executed.v0
agennext.decision.revised.v0
agennext.decision.superseded.v0
```

## Final rule

```txt
Decisions are not comments.
Decisions are governed, evidence-backed commitments to a selected path among alternatives.
A runtime that cannot explain decisions cannot be trusted.
```
