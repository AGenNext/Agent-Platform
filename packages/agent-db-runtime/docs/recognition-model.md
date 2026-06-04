# Agent DB Runtime Recognition Model

Status: draft, aligned with Frozen Framework v0.1, Card Model, Certification, Accreditation, Discovery, and Recommendation.

## Purpose

Recognition models ecosystem acceptance, reputation, social proof, and market/community confidence.

Accreditation is formal authority.

Recognition is observed acceptance.

```txt
Accredited = formally trusted authority
Recognized = accepted, known, used, reviewed, or respected by an ecosystem
```

Both matter, but they are not the same.

## Core rule

```txt
Accreditation grants formal authority.
Recognition records ecosystem acceptance.
```

A card, tool, skill, operator, protocol, authority, artifact, or knowledge source may be:

```txt
accredited but not recognized
recognized but not accredited
both accredited and recognized
neither accredited nor recognized
```

## Recognition answers

```txt
Is this widely used?
Who recognizes it?
Which ecosystem recognizes it?
How strong is the recognition?
Is recognition based on evidence or popularity only?
Is recognition current or stale?
Does recognition improve recommendation confidence?
Does recognition create bias or herd-risk?
```

## Recognition object model

```txt
RecognitionSignal
  usage, citation, review, adoption, endorsement, benchmark, certification reference, marketplace adoption, community acceptance

RecognitionSource
  organization, user group, ecosystem, marketplace, standards body, reviewer, evaluator, public source

RecognitionScope
  domain, industry, geography, jurisdiction, protocol, capability class, project type

RecognitionScore
  measured ecosystem confidence, adoption, reputation, or acceptance

RecognitionRecord
  durable record of signal, source, score, scope, evidence, freshness, and bias risk
```

## Recognition states

```txt
unknown
emerging
recognized
widely-recognized
contested
declining
stale
revoked
```

## Card field addition

Cards may include recognition metadata:

```yaml
recognition:
  recognitionState: unknown | emerging | recognized | widely-recognized | contested | declining | stale | revoked
  recognizedBy: []
  recognitionScope:
    organizations: []
    industries: []
    domains: []
    geographies: []
    protocols: []
    capabilityClasses: []
  signals: []
  score: null
  evidence: []
  freshness: null
  biasRisk: low | medium | high | unknown
  lastAssessedAt: null
  nextAssessmentAt: null
```

## Recognition signals

Examples:

```txt
usage count
successful task count
verified deployments
positive reviews
third-party reviews
marketplace adoption
community adoption
standard references
public citations
benchmark presence
audited usage
low incident history
strong SLA history
high trust score over time
repeat selection
```

## Recognition risks

Recognition can be useful, but it can also mislead.

Risks:

```txt
popularity bias
vendor influence
stale reputation
review manipulation
ecosystem lock-in
regional mismatch
industry mismatch
outdated benchmark
unverified endorsements
```

Therefore recognition must be evidence-backed and time-aware.

## Recognition vs related concepts

```txt
Signed Card
  = Registry Platform issued the card

Verified Capability
  = evidence proves capability works

Certified Capability
  = governance approves capability for scoped use

Accredited Authority
  = authority is approved to certify, verify, review, evaluate, or govern

Recognized Card
  = ecosystem has evidence of adoption, reputation, acceptance, or repeated successful use
```

## Recognition and recommendation

Recognition can influence recommendation, but it must not override policy, eligibility, or certification.

```txt
Policy > Eligibility > Certification > Trust > Evidence > Recognition > Popularity
```

Recognition should increase confidence only when evidence is current and relevant to the scope.

## Runtime mapping

```txt
RecognitionSignal -> usage_record + evaluation + review + citation artifact
RecognitionSource -> identity + registry_entry + source anchor
RecognitionScope  -> governance_object + schema_definition
RecognitionScore  -> evaluation_metric + trust_assessment
RecognitionRecord -> registry_entry + card recognition section
```

## Example: recognized but not accredited

```txt
Tool: Popular Browser Automation Tool
Recognition: widely used by community
Accreditation: none
Certification: not approved for production
Recommendation: may be suggested for sandbox only, requires human approval
```

## Example: accredited but not recognized

```txt
Authority: Newly created internal compliance board
Accreditation: approved by organization
Recognition: emerging
Recommendation: valid for internal governance, but low external ecosystem weight
```

## Example: both accredited and recognized

```txt
Authority: Official Kubernetes Documentation
Accreditation: source authority for Kubernetes semantics
Recognition: widely recognized in cloud-native ecosystem
Recommendation: high confidence canonical source anchor
```

## Final rule

```txt
Accreditation is formal authority.
Recognition is ecosystem acceptance.
Recognition can support recommendation, but it cannot bypass policy, eligibility, certification, or evidence.
```
