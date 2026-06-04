# Agent DB Runtime Operating Loop Model

Status: draft enterprise/runtime loop model.

## Purpose

The runtime must be modeled as a repeating loop, not a one-time delivery chain.

Enterprise intent creates work. Runtime execution produces evidence. Evidence proves outcomes. Outcomes realize value. Value realization creates learning. Learning drives improvement. Improvement updates future enterprise intent and runtime behavior.

## Core loop

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

## Enterprise-to-runtime loop

```txt
Stakeholder
  -> Need / Opportunity / Risk / Obligation
    -> Strategy
      -> Goal
        -> Objective
          -> Metric / Target / Constraint
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
                                -> Strategy / Objective / Capability / Policy Update
```

## Runtime execution loop

```txt
Need / Task
  -> Discovery
    -> Qualification
      -> Eligibility
        -> Recommendation
          -> Selection / Rejection
            -> Authorization
              -> Execution
                -> Evidence
                  -> Evaluation
                    -> Trust Update
                      -> ValueRealization
                        -> Learning
                          -> Improvement
```

## Governance loop

```txt
Policy
  -> Authorization
    -> Action
      -> Evidence
        -> Evaluation
          -> Incident / SLA / Claim if needed
            -> Resolution
              -> Learning
                -> Policy Improvement
```

## Knowledge loop

```txt
Observation
  -> Discussion
    -> Claim
      -> Documentation
        -> Artifact
          -> Signature
            -> Verification
              -> Knowledge Candidate
                -> Governance Approval
                  -> Knowledge
                    -> Use
                      -> Evaluation
                        -> Learning
                          -> Knowledge Update / Retraction / Supersession
```

## Card lifecycle loop

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
                  -> Selected
                    -> Used
                      -> Rated / Reviewed / Scored
                        -> Re-evaluated
                          -> Continued / Suspended / Revoked / Improved
```

## Asset-to-value loop

```txt
Asset
  -> Resource
    -> Capability
      -> Process / Workflow
        -> Service / Product
          -> ValueStream
            -> Customer / Beneficiary
              -> Outcome
                -> ValueRealization
                  -> Learning
                    -> Improvement
                      -> Asset / Capability / Service / Product / ValueStream Update
```

## Loop rule

```txt
A loop is valid only if it has:
  intent
  execution
  evidence
  evaluation
  value realization
  learning
  improvement
```

If evidence is missing, the loop is not auditable.

If value realization is missing, the loop is activity only.

If learning is missing, the loop cannot improve.

If improvement is missing, learning is unused insight.

## Runtime minimum loop

The smallest valid runtime loop is:

```txt
Task
  -> ActionInvocation
    -> Evidence
      -> Evaluation
        -> Decision / Trust Update
          -> Learning
            -> ImprovementCandidate
```

## Enterprise minimum loop

The smallest valid enterprise loop is:

```txt
Objective
  -> Project
    -> Outcome
      -> ValueRealization
        -> Learning
          -> Improvement
```

## Final rule

```txt
The platform must not only execute work.
It must close the loop from enterprise intent to runtime evidence to value realization to learning to improvement.
```
