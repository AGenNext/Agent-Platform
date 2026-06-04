# Agent DB Runtime Responsibility, Authority, and Accountability Model

Status: draft foundational enterprise governance layer.

## Purpose

Every meaningful enterprise and runtime object must have clear responsibility, authority, and accountability.

This model anchors decisions, delegation, approvals, certifications, operations, risks, obligations, value realization, learning, and improvement to accountable parties.

## Core rule

```txt
No decision without authority.
No task without responsibility.
No commitment without accountability.
No delegation without acceptance.
No value claim without beneficiary and accountable owner.
```

## Core concepts

```txt
Responsibility
  who is expected to do or manage something

Authority
  who has the right to decide, approve, certify, accredit, invoke, delegate, or override

Accountability
  who is answerable for outcome, value, risk, compliance, and consequences

Ownership
  who controls or stewards an object, asset, decision, policy, task, or outcome

Delegation
  transfer of responsibility or authority from one party to another within scope

Acceptance
  explicit acknowledgement of responsibility, authority, or commitment
```

## Governance chain

```txt
Need / Obligation / Risk
  -> Decision
    -> Authority Check
      -> Commitment
        -> Responsibility Assignment
          -> Delegation / Acceptance
            -> Execution
              -> Evidence
                -> Outcome
                  -> Accountability Review
                    -> ValueRealization
                      -> Learning
                        -> Improvement
```

## RACI model

The runtime may use RACI as a default responsibility model.

```txt
Responsible
  does the work

Accountable
  owns the result

Consulted
  provides input

Informed
  receives updates
```

Extended forms may include:

```txt
Verifier
Approver
Certifier
Auditor
Beneficiary
RiskOwner
PolicyOwner
DataOwner
ServiceOwner
ProductOwner
CapabilityOwner
```

## Object model

```txt
ResponsibilityAssignment
  links to Identity / Operator / Team / Organization
  links to Task / Project / Capability / Asset / Service / Product / Policy / Risk / Outcome
  defines role: responsible | accountable | consulted | informed | verifier | approver | certifier | auditor
  defines scope
  defines start/end time
  defines evidence requirements

AuthorityGrant
  links to Identity / Operator / Role / AccreditedAuthority
  links to action scope
  links to policy
  links to delegation chain
  defines allowed decisions/actions
  defines expiry
  defines revocation conditions

AccountabilityRecord
  links to accountable party
  links to commitment / outcome / value realization / incident / claim / SLA
  records result
  records evidence
  records review

Delegation
  links from delegator to delegatee
  links to authority or responsibility
  defines scope
  requires acceptance
  requires evidence
```

## Authority sources

Authority may come from:

```txt
role
position
ownership
policy
contract
law
regulation
standard
accreditation
certification
delegation
approval workflow
emergency override
```

## Accountability sources

Accountability may come from:

```txt
ownership
contract
commitment
policy
role
law
regulation
SLA
risk ownership
benefit ownership
project ownership
product ownership
service ownership
```

## Delegation rules

```txt
Delegation must have scope.
Delegation must have time boundary.
Delegation must be accepted.
Delegation must preserve accountability unless explicitly transferred.
Delegation must be revocable.
Delegation must log evidence.
Delegation must respect policy and authorization.
```

## Runtime mapping

```txt
ResponsibilityAssignment -> task.owner / task.assignee / governance_object
AuthorityGrant           -> authorization_decision + policy_evaluation + accreditation
AccountabilityRecord     -> decision + evidence + evaluation + value_realization
Delegation               -> handoff + responsibility + protocol_message + evidence
Acceptance               -> decision + evidence
```

## Relationship to cards

Cards should declare responsibility and authority metadata.

```yaml
responsibility:
  owner: identity:owner
  accountableParty: identity:accountable
  responsibleParties: []
  consultedParties: []
  informedParties: []
  riskOwner: null
  policyOwner: null

authority:
  issuer: registry-platform
  approvers: []
  verifiers: []
  certifiers: []
  accreditedAuthorities: []
  delegationAllowed: false
  overrideAllowed: false
```

## Decision authority

A decision is valid only if decision authority is proven.

```txt
Decision
  requires AuthorityGrant
  requires evidence of authority
  may require approval
  may require separation of duty
```

## Value accountability

Value realization must identify:

```txt
beneficiary
value owner
accountable party
measurement owner
evidence owner
review owner
```

## Final rule

```txt
Responsibility performs.
Authority permits.
Accountability answers.
Delegation transfers within scope.
Evidence proves the chain.
```
