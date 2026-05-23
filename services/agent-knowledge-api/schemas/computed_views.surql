-- Schema: computed_views
-- DEFINE TABLE ... AS SELECT ... — materialized aggregation views.
-- SurrealDB keeps these live: inserts/updates to source tables
-- automatically propagate to the view. No ETL, no refresh jobs.
-- Ref: https://surrealdb.com/docs/surrealql/statements/define/table#pre-computed-table-views

-- ─── Agent registry summary ──────────────────────────────────────────────────
-- Live count of agents by status, per tenant

DEFINE TABLE view_agent_status_summary AS
    SELECT
        tenant_id,
        status,
        count() AS agent_count
    FROM agent
    GROUP BY tenant_id, status;

-- ─── Daily spend per tenant ──────────────────────────────────────────────────
-- Rolling live aggregation: cost by tenant by day

DEFINE TABLE view_daily_spend AS
    SELECT
        tenant_id,
        time::day(recorded_at)   AS day,
        time::month(recorded_at) AS month,
        time::year(recorded_at)  AS year,
        math::sum(cost_usd)      AS spend_usd,
        math::sum(tokens_in + tokens_out) AS total_tokens,
        count()                  AS call_count
    FROM usage_record
    GROUP BY tenant_id, time::day(recorded_at), time::month(recorded_at), time::year(recorded_at);

-- ─── Objective completion rate ───────────────────────────────────────────────

DEFINE TABLE view_objective_stats AS
    SELECT
        tenant_id,
        status,
        count()                               AS total,
        math::mean(priority)                  AS avg_priority
    FROM objective
    GROUP BY tenant_id, status;

-- ─── Trust pass rate per tenant ──────────────────────────────────────────────

DEFINE TABLE view_trust_stats AS
    SELECT
        agent_id,
        eval_status,
        count()                  AS total,
        math::mean(ratingValue)  AS avg_score
    FROM trust_record
    GROUP BY agent_id, eval_status;

-- ─── Memory type distribution per agent ─────────────────────────────────────

DEFINE TABLE view_memory_distribution AS
    SELECT
        agent_id,
        memory_type,
        count()           AS count,
        math::mean(importance) AS avg_importance
    FROM memory
    GROUP BY agent_id, memory_type;

-- ─── Model cost leaderboard ─────────────────────────────────────────────────

DEFINE TABLE view_model_cost_leaderboard AS
    SELECT
        model_id,
        provider,
        math::sum(cost_usd)         AS total_spend_usd,
        math::mean(cost_usd)        AS avg_cost_per_call,
        math::sum(tokens_in)        AS total_tokens_in,
        math::sum(tokens_out)       AS total_tokens_out,
        count()                     AS call_count
    FROM usage_record
    GROUP BY model_id, provider;

-- ─── Querying views (same as any table) ─────────────────────────────────────
-- SELECT * FROM view_daily_spend WHERE tenant_id = 'tenant-acme' ORDER BY day DESC;
-- SELECT * FROM view_model_cost_leaderboard ORDER BY total_spend_usd DESC LIMIT 10;
-- SELECT * FROM view_agent_status_summary WHERE tenant_id = $auth.tenant_id;
