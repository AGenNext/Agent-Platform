# Routing & Cost Control

> Use the AI Gateway to route models, set fallbacks, and watch spend.
> Authored in the [OpenLMX](https://github.com/open-lmx) canonical course format
> — every module is a hands-on read → edit → run lesson.

- **Level:** Intermediate
- **Duration:** ~40 minutes
- **Prerequisites:** Agent Platform Foundations (or equivalent)
- **Credential on completion:** `Routing & Cost Control`

---

## Why this course

The AI Gateway (model-router) is the single front door for every model call.
This course teaches how to route traffic across models, fall back on failure,
and keep spend and latency under control.

## Modules

| # | Module | Competency | What you build |
|---|--------|------------|----------------|
| 1 | **Model routes** | Routing | Define a primary route and split traffic by share |
| 2 | **Fallback policy** | Resilience | Fail over to a backup model on error or budget breach |
| 3 | **Cost dashboards** | Cost | Track requests, spend, p95 latency, and error rate per route |

### Module 1 — Model routes
Route requests to a primary model with a share-based traffic split.

```surql
DEFINE ROUTE default
  PRIMARY  claude-sonnet-4.6
  FALLBACK claude-opus-4.8
  BUDGET   "$500/day";
```

### Module 2 — Fallback policy
Fail over automatically when the primary errors or the budget is exceeded.

```surql
LET $r = fn::route("default", $request);
IF $r.error OR $r.budget_exceeded {
  RETURN fn::route_fallback("default", $request);
};
```

### Module 3 — Cost dashboards
Aggregate per-route usage for the AI Gateway view.

```surql
SELECT model, count() AS requests, math::sum(cost_usd) AS spend,
       math::percentile(latency_ms, 95) AS p95
FROM model_call GROUP BY model;
```

## Credential model

Completing all modules earns the `Routing & Cost Control` competency
credential — added to the learner's skill passport per the OpenLMX
*Knowledge → Learning → Assessment → Competency → Credential* progression.
