# Agent DB Runtime Value Realization and Learning Model

Status: draft correction to Frozen Framework v0.1.

## Purpose

The runtime lifecycle is incomplete if it stops at operation or improvement.

The platform must prove that work produced measurable value, and then convert value evidence into learning that improves future work.

## Correct lifecycle

```txt
Define
  -> Design
    -> Implement
      -> Validate
        -> Certify
          -> Deploy
            -> Operate
              -> Realize Value
                -> Learn
                  -> Improve
```

## Correct maturity chain

```txt
Defined
  -> Designed
    -> Implemented
      -> Tested
        -> Validated
          -> Certified
            -> Deployed
              -> Operated
                -> Value Realized
                  -> Learned
                    -> Improved
                      -> Trusted
```

## Core rule

```txt
Task measures progress.
Evidence proves execution.
Evaluation judges quality.
Trust records confidence.
Value Realization proves outcome value.
Learning converts outcome evidence into reusable improvement.
Improvement updates future work, policy, skill, tool, operator, recommendation, and trust behavior.
```

## Work to value chain

```txt
Work
  -> Output
    -> Outcome
      -> Value
        -> Learning
          -> Improvement
```

## Concept distinctions

```txt
UnitOfWork
  = unit of measurement for work

Task
  = progress unit

Output
  = produced deliverable

Outcome
  = achieved result

ValueRealization
  = evidenced benefit from outcome

Learning
  = insight generated from outcome and value evidence

Improvement
  = applied change based on learning
```

## Value Realization answers

```txt
Did the work achieve the intended outcome?
Did it produce measurable business, operational, user, compliance, trust, cost, speed, quality, or risk-reduction value?
Was the value realized by the intended beneficiary?
Was the value realized within scope, deadline, policy, and SLA?
Was the value worth the cost?
What evidence proves the value?
```

## Learning answers

```txt
What did we learn from this work?
What should change next time?
Which skill improved?
Which tool performed better or worse?
Which operator became more or less trusted?
Which policy needs adjustment?
Which recommendation was right or wrong?
Which assumptions were invalid?
Which evidence should become documentation?
Which artifacts should become knowledge candidates?
```

## Value dimensions

```txt
business_value
user_value
operational_value
financial_value
compliance_value
trust_value
knowledge_value
risk_reduction
cost_reduction
time_saved
quality_improvement
reliability_improvement
sla_improvement
```

## Learning dimensions

```txt
decision_learning
skill_learning
tool_learning
operator_learning
policy_learning
recommendation_learning
selection_learning
trust_learning
knowledge_learning
workflow_learning
cost_learning
risk_learning
quality_learning
```

## Object model

```txt
Outcome
  links to Project
  links to Milestone
  links to Task
  links to UnitOfWork
  links to Evidence
  links to Evaluation

ValueRealization
  links to Outcome
  links to Benefit
  links to ValueMetric
  links to Cost
  links to RiskReduction
  links to Evidence
  links to TrustAssessment

Learning
  links to ValueRealization
  links to Outcome
  links to Evaluation
  links to Evidence
  links to Decision
  links to Task
  links to Project
  links to Skill
  links to Tool
  links to Operator
  links to Policy
  links to TrustAssessment
  links to KnowledgeCandidate

Improvement
  links to Learning
  links to ChangeRequest
  links to PolicyUpdate
  links to SkillUpdate
  links to ToolUpdate
  links to OperatorUpdate
  links to WorkDefinitionUpdate
```

## Learning is not Knowledge by default

Learning produces learning records, insights, and improvement candidates.

Learning becomes knowledge only through the existing promotion rule:

```txt
Documented Artifact
  -> Signed Artifact
    -> Verified Artifact
      -> Governed Knowledge Candidate
        -> Approved Knowledge
```

## Runtime mapping

```txt
Outcome              -> entity + artifact + evaluation
ValueRealization     -> evaluation + evidence + score + trust_assessment
Benefit              -> evaluation_metric
ValueMetric          -> score / evaluation_metric
Learning             -> decision + artifact + evaluation + trust_event
LearningRecord       -> artifact + evidence + decision
Insight              -> claim / artifact / knowledge_candidate
ImprovementCandidate -> task + decision + issue
Improvement          -> task + workflow_run + decision + evidence
```

## Events to add

```txt
agennext.outcome.recorded.v0
agennext.value.realized.v0
agennext.learning.recorded.v0
agennext.improvement.created.v0
agennext.improvement.applied.v0
```

## Final rule

```txt
Execution without value realization is activity.
Value realization without learning is reporting.
Learning without improvement is unused insight.
Improvement with evidence increases trust.
```
