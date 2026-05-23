-- Schema: rate_limits
-- API quota and rate-limit tracking per tenant/agent.
-- Hard limits enforced at the SurrealDB layer via DEFINE PARAM + ASSERT.
-- Soft limits tracked via quota_usage for dashboard visibility.

-- ─── Rate limit configuration ─────────────────────────────────────────────────

DEFINE TABLE rate_limit_config SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE rate_limit_config TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE rate_limit_config TYPE string DEFAULT 'DigitalDocument';

DEFINE FIELD tenant_id     ON TABLE rate_limit_config TYPE string ASSERT $value != NONE;
DEFINE FIELD resource      ON TABLE rate_limit_config TYPE string ASSERT $value != NONE;
    -- e.g. 'api_calls', 'llm_tokens', 'agent_runs', 'artifact_evals', 'webhook_deliveries'
DEFINE FIELD scope         ON TABLE rate_limit_config TYPE string DEFAULT 'tenant'
    ASSERT $value IN ['tenant', 'agent', 'user', 'api_key'];
DEFINE FIELD scope_id      ON TABLE rate_limit_config TYPE option<string>;
    -- tenant_id, agent_id, user_id, or credential_id depending on scope

-- Limit definition
DEFINE FIELD limit_value   ON TABLE rate_limit_config TYPE int ASSERT $value > 0;
DEFINE FIELD window        ON TABLE rate_limit_config TYPE string DEFAULT '1m'
    ASSERT $value IN ['1s', '10s', '1m', '5m', '1h', '1d', '1w', '1month'];
DEFINE FIELD burst_limit   ON TABLE rate_limit_config TYPE option<int>;
    -- allow short burst above limit_value
DEFINE FIELD action        ON TABLE rate_limit_config TYPE string DEFAULT 'throttle'
    ASSERT $value IN ['throttle', 'block', 'warn', 'queue'];

DEFINE FIELD active        ON TABLE rate_limit_config TYPE bool DEFAULT true;
DEFINE FIELD created_at    ON TABLE rate_limit_config TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_rl_tenant    ON TABLE rate_limit_config COLUMNS tenant_id;
DEFINE INDEX idx_rl_resource  ON TABLE rate_limit_config COLUMNS resource;
DEFINE INDEX idx_rl_scope     ON TABLE rate_limit_config COLUMNS scope, scope_id;

-- ─── Quota usage tracking ─────────────────────────────────────────────────────

DEFINE TABLE quota_usage SCHEMAFULL;

DEFINE FIELD tenant_id     ON TABLE quota_usage TYPE string ASSERT $value != NONE;
DEFINE FIELD resource      ON TABLE quota_usage TYPE string ASSERT $value != NONE;
DEFINE FIELD scope         ON TABLE quota_usage TYPE string DEFAULT 'tenant';
DEFINE FIELD scope_id      ON TABLE quota_usage TYPE option<string>;

-- Rolling window counter (reset by window)
DEFINE FIELD window_start  ON TABLE quota_usage TYPE datetime DEFAULT time::now();
DEFINE FIELD window        ON TABLE quota_usage TYPE string DEFAULT '1m';
DEFINE FIELD count         ON TABLE quota_usage TYPE int DEFAULT 0;
DEFINE FIELD limit_value   ON TABLE quota_usage TYPE int DEFAULT 0;

-- Derived
DEFINE FIELD utilization   ON TABLE quota_usage TYPE float DEFAULT 0.0;
    -- count / limit_value (0.0–1.0)

DEFINE FIELD updated_at    ON TABLE quota_usage TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_quota_tenant  ON TABLE quota_usage COLUMNS tenant_id;
DEFINE INDEX idx_quota_res     ON TABLE quota_usage COLUMNS resource;
DEFINE INDEX idx_quota_window  ON TABLE quota_usage COLUMNS window_start;

-- ─── Rate limit violation log (append-only) ──────────────────────────────────

DEFINE TABLE rate_limit_violation SCHEMAFULL;

DEFINE FIELD tenant_id     ON TABLE rate_limit_violation TYPE string ASSERT $value != NONE;
DEFINE FIELD resource      ON TABLE rate_limit_violation TYPE string ASSERT $value != NONE;
DEFINE FIELD scope_id      ON TABLE rate_limit_violation TYPE option<string>;
DEFINE FIELD count_at_time ON TABLE rate_limit_violation TYPE int;
DEFINE FIELD limit_value   ON TABLE rate_limit_violation TYPE int;
DEFINE FIELD action_taken  ON TABLE rate_limit_violation TYPE string;
DEFINE FIELD request_meta  ON TABLE rate_limit_violation TYPE option<object>;
DEFINE FIELD recorded_at   ON TABLE rate_limit_violation TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_rlv_tenant   ON TABLE rate_limit_violation COLUMNS tenant_id;
DEFINE INDEX idx_rlv_resource ON TABLE rate_limit_violation COLUMNS resource;
DEFINE INDEX idx_rlv_time     ON TABLE rate_limit_violation COLUMNS recorded_at;

-- ─── Helper: check if a resource is over limit ───────────────────────────────

DEFINE FUNCTION fn::is_rate_limited($tenant_id: string, $resource: string) {
    LET $config = SELECT * FROM rate_limit_config
        WHERE tenant_id = $tenant_id
          AND resource  = $resource
          AND active    = true
        LIMIT 1;
    IF array::len($config) = 0 { RETURN false; };
    LET $window_start = time::floor(time::now(), duration($config[0].window));
    LET $count = SELECT VALUE count() FROM quota_usage
        WHERE tenant_id   = $tenant_id
          AND resource    = $resource
          AND window_start >= $window_start;
    RETURN ($count[0] ?? 0) >= $config[0].limit_value;
};

-- ─── Default platform limits (seeded on startup) ─────────────────────────────

INSERT IGNORE INTO rate_limit_config [
    { tenant_id: 'platform', resource: 'api_calls',       scope: 'tenant', limit_value: 1000,  window: '1m',    action: 'throttle' },
    { tenant_id: 'platform', resource: 'llm_tokens',      scope: 'tenant', limit_value: 100000, window: '1h',   action: 'throttle' },
    { tenant_id: 'platform', resource: 'agent_runs',      scope: 'tenant', limit_value: 100,   window: '1h',    action: 'warn'     },
    { tenant_id: 'platform', resource: 'artifact_evals',  scope: 'tenant', limit_value: 500,   window: '1h',    action: 'throttle' },
    { tenant_id: 'platform', resource: 'webhook_deliveries', scope: 'tenant', limit_value: 200, window: '1m',  action: 'queue'    }
];
