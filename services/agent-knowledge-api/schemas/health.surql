-- Schema: health
-- Native health monitoring replacing Uptime Kuma.
-- Every agent must emit health_check records — no health = no active status.

DEFINE TABLE health_check SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE health_check TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE health_check TYPE string DEFAULT 'CheckAction';

-- schema:CheckAction fields
DEFINE FIELD name          ON TABLE health_check TYPE string DEFAULT 'agent-health';
DEFINE FIELD agent_id      ON TABLE health_check TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE health_check TYPE option<string>;

-- Health state
DEFINE FIELD status        ON TABLE health_check TYPE string DEFAULT 'healthy'
    ASSERT $value IN ['healthy', 'degraded', 'unhealthy', 'unknown'];
DEFINE FIELD latency_ms    ON TABLE health_check TYPE option<int>;
DEFINE FIELD message       ON TABLE health_check TYPE option<string>;
DEFINE FIELD details       ON TABLE health_check TYPE option<object>;
DEFINE FIELD checked_at    ON TABLE health_check TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_health_agent   ON TABLE health_check COLUMNS agent_id;
DEFINE INDEX idx_health_checked ON TABLE health_check COLUMNS checked_at;
DEFINE INDEX idx_health_status  ON TABLE health_check COLUMNS status;

-- Event: deactivate agent if last health check > 5 minutes ago (checked via query)
-- Query: SELECT agent_id FROM health_check
--        WHERE agent_id = $agent_id
--        ORDER BY checked_at DESC LIMIT 1
--        FETCH agent_id;
