-- Schema: time_series
-- Native SurrealDB time-series for platform metrics, agent performance,
-- and LLM latency tracking. Uses datetime indexing for bucket aggregations.

-- ─── Platform metric ─────────────────────────────────────────────────────────

DEFINE TABLE metric SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE metric TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE metric TYPE string DEFAULT 'Observation';

DEFINE FIELD name          ON TABLE metric TYPE string ASSERT $value != NONE;
DEFINE FIELD value         ON TABLE metric TYPE float ASSERT $value != NONE;
DEFINE FIELD unit          ON TABLE metric TYPE option<string>;

-- Dimensions
DEFINE FIELD tenant_id     ON TABLE metric TYPE option<string>;
DEFINE FIELD agent_id      ON TABLE metric TYPE option<string>;
DEFINE FIELD objective_id  ON TABLE metric TYPE option<record<objective>>;
DEFINE FIELD model_id      ON TABLE metric TYPE option<string>;
DEFINE FIELD labels        ON TABLE metric TYPE object DEFAULT {};

-- Time — nanosecond precision supported; use datetime for bucket queries
DEFINE FIELD recorded_at   ON TABLE metric TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_metric_name       ON TABLE metric COLUMNS name;
DEFINE INDEX idx_metric_agent      ON TABLE metric COLUMNS agent_id;
DEFINE INDEX idx_metric_tenant     ON TABLE metric COLUMNS tenant_id;
DEFINE INDEX idx_metric_recorded   ON TABLE metric COLUMNS recorded_at;
DEFINE INDEX idx_metric_name_time  ON TABLE metric COLUMNS name, recorded_at;

-- ─── LLM latency record ──────────────────────────────────────────────────────

DEFINE TABLE llm_latency SCHEMAFULL;

DEFINE FIELD model_id      ON TABLE llm_latency TYPE string ASSERT $value != NONE;
DEFINE FIELD provider      ON TABLE llm_latency TYPE option<string>;
DEFINE FIELD tenant_id     ON TABLE llm_latency TYPE option<string>;
DEFINE FIELD tokens_in     ON TABLE llm_latency TYPE int DEFAULT 0;
DEFINE FIELD tokens_out    ON TABLE llm_latency TYPE int DEFAULT 0;
DEFINE FIELD ttft_ms       ON TABLE llm_latency TYPE option<float>;  -- time to first token
DEFINE FIELD total_ms      ON TABLE llm_latency TYPE float ASSERT $value >= 0;
DEFINE FIELD success       ON TABLE llm_latency TYPE bool DEFAULT true;
DEFINE FIELD error_code    ON TABLE llm_latency TYPE option<string>;
DEFINE FIELD recorded_at   ON TABLE llm_latency TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_llm_model    ON TABLE llm_latency COLUMNS model_id;
DEFINE INDEX idx_llm_tenant   ON TABLE llm_latency COLUMNS tenant_id;
DEFINE INDEX idx_llm_recorded ON TABLE llm_latency COLUMNS recorded_at;

-- ─── Time-series query patterns ──────────────────────────────────────────────

-- 1-minute buckets for the last hour (token throughput):
-- SELECT
--     time::floor(recorded_at, 1m) AS bucket,
--     math::sum(value) AS total_tokens
-- FROM metric
-- WHERE name = 'tokens_out'
--   AND recorded_at >= time::now() - 1h
-- GROUP BY time::floor(recorded_at, 1m)
-- ORDER BY bucket ASC;

-- P50/P95 LLM latency by model over last 24h:
-- SELECT
--     model_id,
--     math::median(total_ms) AS p50_ms,
--     math::percentile(total_ms, 95) AS p95_ms,
--     math::max(total_ms) AS max_ms,
--     count() AS requests
-- FROM llm_latency
-- WHERE recorded_at >= time::now() - 24h
-- GROUP BY model_id
-- ORDER BY p95_ms DESC;

-- Error rate per model (last 1h):
-- SELECT model_id,
--     count(WHERE success = false) AS errors,
--     count() AS total,
--     (count(WHERE success = false) / count()) * 100 AS error_pct
-- FROM llm_latency
-- WHERE recorded_at >= time::now() - 1h
-- GROUP BY model_id;
