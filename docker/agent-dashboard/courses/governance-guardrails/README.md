# Governance & Guardrails

> Add policy gates, CLEAR evaluation, and trust scoring so agents ship safely.
> Authored in the [OpenLMX](https://github.com/open-lmx) canonical course format
> — every module is a hands-on read → edit → run lesson.

- **Level:** Intermediate
- **Duration:** ~50 minutes
- **Prerequisites:** Agent Platform Foundations (or equivalent)
- **Credential on completion:** `Governance & Guardrails`

---

## Why this course

Governance on the platform is *by construction*: gates run before agents act,
evaluation gates publishing, and trust accumulates as evidence. This course
teaches the three guardrails that keep autonomous agents safe.

## Modules

| # | Module | Competency | What you build |
|---|--------|------------|----------------|
| 1 | **Policy gates** | Governance, Policy | Block any run that fails a runtime policy before agents act |
| 2 | **CLEAR eval** | Evaluation, CLEAR | Score artifacts across dimensions, gate on a composite threshold |
| 3 | **Trust scoring** | Trust | Accumulate evidence-weighted trust feeding the publish gate |
| 4 | **Failure handling** | Resilience | Throw, audit, and recover when a gate denies |

### Module 1 — Policy gates
A denied policy throws before agents run; the pipeline never executes.

```surql
LET $p = fn::evaluate_policy($obj, "AGX-RUNTIME-DEFAULT");
IF $p.effect != "allow" { THROW "blocked by governance policy"; };
```

### Module 2 — CLEAR eval
CLEAR scores an artifact across weighted dimensions and gates publishing.

```surql
LET $eval = fn::record_evaluation($artifact, "CLEAR");
IF $eval.composite_score < 0.7 { THROW "failed CLEAR eval gate"; };
```

### Module 3 — Trust scoring
Trust accumulates evidence over an artifact's life and feeds the publish gate.

```surql
LET $trust = fn::update_trust($artifact);
RETURN { score: $trust.score, evidence: $trust.evidence_count };
```

### Module 4 — Failure handling
A denied gate is an audited event, not a crash — catch, record, and route.

```surql
LET $result = (SELECT * FROM fn::run($obj)) CATCH $err {
  CREATE audit SET event = "gate_denied", reason = $err, at = time::now();
  RETURN { status: "blocked", reason: $err };
};
```

## Credential model

Completing all modules earns the `Governance & Guardrails` competency
credential — added to the learner's skill passport per the OpenLMX
*Knowledge → Learning → Assessment → Competency → Credential* progression.
