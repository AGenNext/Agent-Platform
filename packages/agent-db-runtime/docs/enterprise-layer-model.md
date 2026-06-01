# Agent DB Runtime Enterprise Layer Model

Status: draft enterprise layer above Frozen Framework v0.1.

## Purpose

The runtime layer explains how work is executed, evidenced, evaluated, trusted, and improved.

The enterprise layer explains why work exists, who benefits, what strategy it serves, what capabilities it changes, what risks it manages, and what value it realizes.

## Enterprise-to-runtime chain

```txt
Enterprise
  -> Stakeholder
    -> Need / Opportunity / Risk / Obligation
      -> Strategy
        -> Goal
          -> Objective
            -> Metric
            -> Target
            -> Constraint
            -> Assumption / Hypothesis
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
                                  -> Enterprise Feedback
```

## Core rule

```txt
Enterprise defines why.
Runtime defines how.
Evidence connects the two.
Value realization proves whether runtime work served enterprise intent.
Learning feeds enterprise feedback.
```

## Enterprise entities

```txt
Enterprise
Organization
BusinessUnit
Department
Team
Stakeholder
Beneficiary
Customer
User
Partner
Supplier
Regulator
Community
Need
Opportunity
Risk
Obligation
Strategy
StrategicTheme
Goal
Objective
Metric
Target
Constraint
Assumption
Hypothesis
Capability
ValueStream
Portfolio
Program
Project
Investment
Budget
Benefit
Outcome
ValueRealization
Learning
Improvement
```

## Stakeholder model

A stakeholder is any party with interest, influence, responsibility, risk, benefit, or accountability.

```txt
Stakeholder
  may express Need
  may define Goal
  may approve Objective
  may fund Portfolio
  may own Capability
  may receive Benefit
  may bear Risk
  may be accountable for Outcome
```

Types:

```txt
customer
user
employee
executive
manager
operator
owner
partner
supplier
regulator
auditor
community
shareholder
citizen
agent
system
```

## Beneficiary model

A beneficiary is the party expected to receive value.

```txt
Beneficiary
  links to Need
  links to Outcome
  links to ValueRealization
  links to Benefit
```

A stakeholder may be a beneficiary, but not every stakeholder is the beneficiary.

## Need, opportunity, risk, and obligation

Enterprise work may originate from:

```txt
Need
  problem or demand requiring work

Opportunity
  potential positive value to capture

Risk
  potential harm or uncertainty to reduce

Obligation
  duty, compliance requirement, commitment, SLA, law, policy, or contract requirement
```

## Strategy model

Strategy connects enterprise intent to execution.

```txt
Strategy
  defines direction
  selects priorities
  allocates resources
  constrains choices
  defines tradeoffs
  maps to goals and capabilities
```

Strategy may contain:

```txt
strategic_theme
north_star_metric
priority_order
investment_thesis
risk_appetite
operating_principles
policy_posture
```

## Goal and objective model

```txt
Goal
  broad desired future state

Objective
  measurable target linked to goal
```

Objective must define:

```txt
metric
target
baseline
deadline
constraints
owner
beneficiary
success criteria
evidence required
```

## Metric and target model

```txt
Metric
  defines what is measured

Target
  defines desired value for metric
```

Examples:

```txt
cycle_time
cost_per_unit_of_work
value_realization_rate
incident_response_time
customer_satisfaction
trust_score
sla_compliance
risk_reduction
quality_score
adoption_rate
```

## Capability model

A capability is the enterprise ability to achieve an outcome.

```txt
Capability
  may be business capability
  may be operational capability
  may be technical capability
  may be agent capability
  may be governance capability
```

Capabilities are enabled by:

```txt
people
process
policy
data
systems
tools
skills
operators
knowledge
partners
```

Runtime mapping:

```txt
Enterprise Capability
  -> Skill
  -> Tool
  -> Operator
  -> Workflow
  -> Evidence
  -> Evaluation
```

## Value stream model

A value stream is the sequence of activities that delivers value to a beneficiary.

```txt
ValueStream
  contains capabilities
  contains work definitions
  contains projects/programs
  produces outcomes
  realizes value
```

## Portfolio and program model

```txt
Portfolio
  collection of investments/projects aligned to strategy

Program
  coordinated set of projects delivering related outcomes

Project
  scoped execution container
```

Runtime already models Project, Milestone, and Task.

Enterprise layer adds Portfolio and Program above Project.

## Investment and budget model

```txt
Investment
  allocates resources toward objective, capability, portfolio, program, or project

Budget
  constrains cost and spend
```

Value realization should compare benefit against cost.

```txt
Value Efficiency = realized value / cost
```

## Enterprise feedback loop

```txt
Outcome
  -> ValueRealization
    -> Learning
      -> Improvement
        -> Strategy Update
        -> Objective Update
        -> Capability Update
        -> Portfolio Update
        -> Policy Update
        -> WorkDefinition Update
        -> Skill / Tool / Operator Update
```

## Enterprise-runtime boundary

```txt
Enterprise Layer
  asks: why, for whom, what value, what risk, what strategy?

Runtime Layer
  asks: who executes, using what, under which policy, with what evidence?
```

Boundary mapping:

```txt
Need / Goal / Objective
  -> Project / Milestone / Task

Capability
  -> Skill / Tool / Operator / Workflow

Metric / Target
  -> Evaluation / Score / ValueMetric

Risk / Obligation
  -> Policy / Constraint / SLA / Incident / Assurance

Stakeholder / Beneficiary
  -> Identity / Organization / Responsibility

ValueRealization
  -> Evaluation / Evidence / TrustAssessment
```

## Governance rule

Enterprise intent must be traceable to runtime execution.

```txt
Need
  -> Goal
    -> Objective
      -> Project
        -> Task
          -> Evidence
            -> Outcome
              -> ValueRealization
```

If this trace is missing, the work is activity, not governed value delivery.

## Final rule

```txt
Enterprise defines intent.
Runtime executes work.
Evidence connects execution to outcome.
Value realization connects outcome to enterprise benefit.
Learning feeds improvement back into the enterprise layer.
```
