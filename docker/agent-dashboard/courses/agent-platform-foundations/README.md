# Building Governed Agents on the Agent Platform

> A hands-on course covering everything used to build the Agent Platform —
> from a plain-language objective to a governed, evaluated, deployed agent.
>
> Authored in the [OpenLMX](https://github.com/open-lmx) canonical course
> format ("Open Operating Standard for Learning & Excellence"): every module
> is a hands-on lesson (read → edit → run → earn competency), and completion
> maps to a verifiable competency credential on the learner's skill passport.

- **Level:** Intermediate
- **Duration:** ~90 minutes
- **Prerequisites:** TypeScript, basic SQL, basic AI/agent concepts
- **Stack used:** SurrealDB · AgentQL/SurrealQL functions · React + Tailwind dashboard · AI Gateway (model-router)
- **Credential on completion:** `Agent Platform Foundations`

---

## Why this course

The platform's promise: *agents propose, the database records, gates enforce.*
This course teaches that loop end-to-end using the exact primitives the
platform is built from — Spaces, Objectives, the Composer, policy gates, CLEAR
evaluation, trust scoring, agent-to-agent handoffs, and the AI Gateway.

## Modules

| # | Module | Competency | What you build |
|---|--------|------------|----------------|
| 1 | **Spaces & Objectives** | Spaces, Objectives | Create a governed workspace and hand agents a typed goal |
| 2 | **Composer & AgentQL** | Composer, AgentQL | Turn a plain-language objective into a SurrealQL agent pipeline |
| 3 | **Policy Gates** | Governance, Policy | Block any run that fails a runtime policy before agents act |
| 4 | **CLEAR Evaluation** | Evaluation, CLEAR | Score artifacts across dimensions and gate on a composite threshold |
| 5 | **Trust Scoring** | Trust | Accumulate evidence-weighted trust and feed the publish gate |
| 6 | **Preview & Deploy** | Deploy, Endpoints | Dry-run the pipeline and publish it as a callable endpoint |
| 7 | **AI Gateway: Routing & Cost** | Routing, Cost | Route across models with fallbacks and watch spend/latency |

### Module 1 — Spaces & Objectives
A Space is a governed workspace; an Objective is a goal you hand to agents.
Everything is a record in SurrealDB.

```surql
CREATE objective SET
  title  = "Compare Q3 vendors",
  type   = "generation",
  space  = space:vendor_intel,
  status = "pending";
```

### Module 2 — Composer & AgentQL
The Composer turns an objective into a typed pipeline. Agents propose, the DB
records.

```surql
DEFINE FUNCTION fn::run($obj: record<objective>) {
  LET $plan  = fn::start_agent($obj, "planner");
  LET $draft = fn::handoff($plan, "writer");
  RETURN $draft.artifact;
};
```

### Module 3 — Policy Gates
Policy gates run before any agent acts. A denied policy throws; the pipeline
never executes — governance by construction.

```surql
LET $p = fn::evaluate_policy($obj, "AGX-RUNTIME-DEFAULT");
IF $p.effect != "allow" { THROW "blocked by governance policy"; };
```

### Module 4 — CLEAR Evaluation
CLEAR scores an artifact across weighted dimensions and gates on a composite
threshold.

```surql
LET $eval = fn::record_evaluation($artifact, "CLEAR");
IF $eval.composite_score < 0.7 { THROW "failed CLEAR eval gate"; };
```

### Module 5 — Trust Scoring
Trust accumulates evidence over an artifact's life and feeds the publish gate.

```surql
LET $trust = fn::update_trust($artifact);
RETURN { score: $trust.score, evidence: $trust.evidence_count };
```

### Module 6 — Preview & Deploy
Preview dry-runs the pipeline as an agent step flow; Deploy publishes it as a
versioned endpoint once gates pass.

```surql
LET $check = fn::preview(fn::run, objective:8f2a);
IF $check.gates_passed { RETURN fn::deploy(fn::run, { name: "vendor-pipeline" }); };
```

### Module 7 — AI Gateway: Routing & Cost
Route requests across models with fallbacks, then track cost and latency per
route.

```surql
DEFINE ROUTE default
  PRIMARY  claude-sonnet-4.6
  FALLBACK claude-opus-4.8
  BUDGET   "$500/day";
```

---

## Related canonical courses (OpenLMX)

These build on the same code-first, governed approach and are referenced from
the [open-lmx/courses](https://github.com/open-lmx/courses) catalog:

- **LangGraph + Next.js** — code-first autonomous AI systems with the LangGraph
  Deep Agent Framework (Intermediate–Advanced, 8 weeks).
- **Building Multi-Tenant Enterprise SaaS in 60 Minutes** — production SaaS
  foundation with Next.js, SurrealDB, Auth, RBAC, SSO, Billing, Audit Logs.

## Credential model

On completing all modules, the learner earns the `Agent Platform Foundations`
competency credential — added to their skill passport per the OpenLMX
*Knowledge → Learning → Assessment → Competency → Credential → Work Readiness*
progression.
