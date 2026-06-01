# Agent DB Runtime Discovery Model

Status: draft, aligned with Frozen Framework v0.1, Card Model v0.1, and Card Meta Model.

## Purpose

Discovery is the runtime process that finds, filters, ranks, selects, or rejects cards.

Discovery applies to:

```txt
ToolCard
SkillCard
OperatorCard
ProtocolCard
InterfaceCard
ApiCard
ArtifactCard
KnowledgeCard
ProjectCard
TaskCard
WorkDefinitionCard
```

## Core rule

```txt
Discovery works over Cards.
Cards define eligibility.
Discovery uses eligibility, scores, ratings, reviews, policies, scope, protocols, and trust to produce selection or rejection.
```

## Discovery flow

```txt
Need / Intent / Task
  -> Discovery Query
    -> Registry Search
      -> Candidate Cards
        -> Eligibility Filter
          -> Policy Filter
            -> Protocol Filter
              -> Scope Filter
                -> Score / Rating / Review Ranking
                  -> Selection Decision
                    -> Selected Card
                      -> Evidence Logged
```

Rejected cards must record rejection reasons.

```txt
Rejected Candidate
  -> Rejection Reason
    -> Evidence
      -> Decision
```

## Discovery object model

```txt
DiscoveryQuery
  asks for a capability, tool, skill, operator, artifact, protocol, or knowledge source

DiscoveryCandidate
  card returned by registry search

DiscoveryFilter
  policy, scope, protocol, trust, environment, risk, credential, cost, or availability constraint

DiscoveryRanking
  ordering based on score, rating, freshness, trust, cost, performance, compliance, or fit

DiscoveryDecision
  selects or rejects candidate cards

DiscoveryEvidence
  logs why something was selected or rejected
```

## Discovery criteria

Discovery should consider:

```txt
project scope
milestone deadline
task requirement
unit of work
allowed protocols
allowed tools
allowed operators
required interfaces
required credentials
risk level
trust score
capability verification
card signature
score
rating
review history
performance history
SLA state
incident history
cost
latency
freshness
data residency
compliance
availability
```

## Discovery and registry

The Registry Platform issues signed cards.

Discovery searches the registry and evaluates card metadata.

```txt
Registry Platform
  issues Signed Cards
    Registry indexes Cards
      Discovery queries Registry
        Discovery evaluates Card Meta Model
          Runtime selects or rejects Card
```

## Discovery and tools

Everything outside the kernel is a tool, so discovery is the default way to select outside capabilities.

Example:

```txt
Task: Create GitHub issue
  Discovery Query: find tool with IssueInterface and GitHub protocol support
    Candidate: GitHub ToolCard
      Eligible: yes
      Verified Capability: yes
      Selected because: supports required interface, protocol, and project scope
```

## Discovery and skills

Tool documentation is source material for skills.

Discovery can find skills derived from tool documentation.

```txt
Tool Documentation
  -> SkillCard
    -> Discovery
      -> Skill selected for Task
```

## Discovery and operators

Every agent is an operator during execution.

Discovery can select an eligible operator for a task.

```txt
Task
  requires Skill
    Discovery finds OperatorCard
      filters by allowed tools, trust, scope, availability
        selects Operator
```

## Runtime mapping

```txt
DiscoveryQuery     -> action_invocation + registry search context
DiscoveryCandidate -> registry_entry + card
DiscoveryFilter    -> governance_object + policy_evaluation
DiscoveryRanking   -> evaluation_metric + trust_assessment
DiscoveryDecision  -> decision
DiscoveryEvidence  -> artifact / evidence / verification_check
Selection          -> card_selection
Rejection          -> card_rejection
```

## Final rule

```txt
Discovery is not search alone.
Discovery is governed selection over signed and scored cards.
A selected card must explain why it was selected.
A rejected card must explain why it was rejected.
```
