# Agent DB Runtime Intent, Objective, and Assumption Model

Status: draft correction to Frozen Framework v0.1.

## Purpose

The runtime lifecycle cannot start at Project alone.

A project exists because of a need, goal, objective, assumption, or hypothesis.

Value realization must be measured against the original intent.

## Correct causal chain

```txt
Need
  -> Goal
    -> Objective
      -> Assumption / Hypothesis
        -> Project
          -> Milestone
            -> Task
              -> Output
                -> Outcome
                  -> ValueRealization
                    -> Learning
                      -> Improvement
```

## Core rule

```txt
Project defines scope.
Milestone defines deadline.
Task measures progress.
Outcome measures achievement.
ValueRealization measures benefit.
Learning updates assumptions, hypotheses, objectives, policies, skills, tools, and operators.
```

## Definitions

### Need

A need is the reason work may be required.

It answers:

```txt
What problem, opportunity, duty, risk, obligation, or desire creates demand for work?
```

Examples:

```txt
Need to reduce incident response time.
Need to comply with policy.
Need to validate runtime readiness.
Need to improve customer onboarding.
Need to reduce operational cost.
```

### Goal

A goal is the desired direction or broad target.

It answers:

```txt
What desirable future state do we want?
```

### Objective

An objective is a measurable target that makes a goal actionable.

It answers:

```txt
What measurable result should be achieved?
By when?
Under what constraints?
```

### Assumption

An assumption is something believed to be true for planning purposes.

It answers:

```txt
What are we treating as true until proven otherwise?
```

Assumptions must be testable, revisable, and linked to evidence.

### Hypothesis

A hypothesis is a testable belief about cause and effect.

It answers:

```txt
If we do X, do we expect Y to happen?
```

### Outcome

An outcome is the result produced by work.

It answers:

```txt
What changed because the work was done?
```

### ValueRealization

Value realization proves whether the outcome mattered.

It answers:

```txt
Did the outcome produce benefit for the intended beneficiary?
```

### Learning

Learning converts outcome and value evidence into future improvement.

It answers:

```txt
What should change next time?
```

## Object model

```txt
Need
  links to Organization
  links to Stakeholder
  links to Evidence
  links to Discussion
  links to Claim

Goal
  links to Need
  links to Organization
  links to Policy
  links to Strategy

Objective
  links to Goal
  links to Metric
  links to Target
  links to Deadline
  links to Constraint

Assumption
  links to Objective
  links to Decision
  links to Evidence
  links to Confidence
  links to Review

Hypothesis
  links to Objective
  links to Experiment
  links to Evidence
  links to Outcome
  links to Learning

Outcome
  links to Objective
  links to Project
  links to Milestone
  links to Task
  links to Output
  links to Evidence
  links to Evaluation

ValueRealization
  links to Outcome
  links to Benefit
  links to Cost
  links to RiskReduction
  links to ValueMetric
  links to Evidence

Learning
  links to Outcome
  links to ValueRealization
  links to Assumption
  links to Hypothesis
  links to Decision
  links to Skill
  links to Tool
  links to Operator
  links to Policy
  links to Improvement
```

## Measurement chain

```txt
Need
  justified by Evidence

Goal
  translated into Objective

Objective
  measured by Target and Metric

Project
  scopes work toward Objective

Milestone
  constrains time

Task
  measures progress

Output
  records produced artifact or action result

Outcome
  records achieved change

ValueRealization
  records realized benefit

Learning
  records insight and updates future behavior
```

## Assumption lifecycle

```txt
Draft Assumption
  -> Accepted for Planning
    -> Tested
      -> Confirmed / Refuted / Revised
        -> Learning
          -> Improvement
```

## Hypothesis lifecycle

```txt
Hypothesis
  -> Experiment / Work Execution
    -> Evidence
      -> Outcome
        -> Evaluation
          -> Learning
            -> Confirm / Reject / Revise
```

## Runtime mapping

```txt
Need             -> claim + discussion + artifact
Goal             -> governance_object + project intent
Objective        -> project objective + metric target
Assumption       -> decision + claim + evidence
Hypothesis       -> decision + evaluation + evidence
Outcome          -> evaluation + artifact + evidence
ValueRealization -> evaluation + score + trust_assessment
Learning         -> artifact + decision + improvement_candidate
Improvement      -> task + workflow_run + decision
```

## Final rule

```txt
Do not measure value only against completed tasks.
Measure value against Need, Goal, Objective, Assumption, and Hypothesis.
Work without objective is activity.
Outcome without value is incomplete.
Learning without improvement is unused insight.
```
