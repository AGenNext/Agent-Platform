-- Schema: alert_rules
-- Configurable alerting thresholds for platform health, spend, and agent behavior.
-- Complements the hard-coded DEFINE EVENT notifications with dynamic user-defined rules.
-- Evaluators run on a schedule or on data writes; results create notifications.

DEFINE TABLE alert_rule SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE alert_rule TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE alert_rule TYPE string DEFAULT 'Rule';

DEFINE FIELD rule_id       ON TABLE alert_rule TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE alert_rule TYPE string ASSERT $value != NONE;
DEFINE FIELD name          ON TABLE alert_rule TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE alert_rule TYPE option<string>;

-- What this alert monitors
DEFINE FIELD category      ON TABLE alert_rule TYPE string DEFAULT 'platform'
    ASSERT $value IN ['platform', 'agent', 'billing', 'trust', 'latency', 'quota', 'security', 'custom'];
DEFINE FIELD source_table  ON TABLE alert_rule TYPE string ASSERT $value != NONE;
    -- table to query: 'metric', 'health_check', 'usage_record', 'llm_latency', etc.

-- Trigger condition (SurrealQL expression returning bool)
DEFINE FIELD condition     ON TABLE alert_rule TYPE string ASSERT $value != NONE;
    -- e.g. 'math::mean(value) > 500' or 'count() > 100'
DEFINE FIELD window        ON TABLE alert_rule TYPE string DEFAULT '5m'
    ASSERT $value IN ['1m', '5m', '15m', '1h', '6h', '1d'];
DEFINE FIELD filter        ON TABLE alert_rule TYPE option<string>;
    -- additional WHERE clause: 'name = ''cpu_pct'' AND agent_id = $agent_id'

-- Severity
DEFINE FIELD severity      ON TABLE alert_rule TYPE string DEFAULT 'warning'
    ASSERT $value IN ['info', 'warning', 'error', 'critical'];
DEFINE FIELD notification_level ON TABLE alert_rule TYPE string DEFAULT 'warning'
    ASSERT $value IN ['info', 'success', 'warning', 'error'];

-- Notification target
DEFINE FIELD notify_users  ON TABLE alert_rule TYPE array DEFAULT [];
DEFINE FIELD notify_webhooks ON TABLE alert_rule TYPE array DEFAULT [];

-- Cooldown: don't re-fire within this window after last alert
DEFINE FIELD cooldown      ON TABLE alert_rule TYPE string DEFAULT '15m';
DEFINE FIELD last_fired    ON TABLE alert_rule TYPE option<datetime>;
DEFINE FIELD fire_count    ON TABLE alert_rule TYPE int DEFAULT 0;

-- Auto-resolve when condition clears
DEFINE FIELD auto_resolve  ON TABLE alert_rule TYPE bool DEFAULT true;
DEFINE FIELD resolved_at   ON TABLE alert_rule TYPE option<datetime>;

DEFINE FIELD active        ON TABLE alert_rule TYPE bool DEFAULT true;
DEFINE FIELD created_by    ON TABLE alert_rule TYPE option<string>;
DEFINE FIELD created_at    ON TABLE alert_rule TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE alert_rule TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_rule_id       ON TABLE alert_rule COLUMNS rule_id UNIQUE;
DEFINE INDEX idx_rule_tenant   ON TABLE alert_rule COLUMNS tenant_id;
DEFINE INDEX idx_rule_category ON TABLE alert_rule COLUMNS category;
DEFINE INDEX idx_rule_active   ON TABLE alert_rule COLUMNS active;

-- ─── Alert instance (each firing of a rule) ───────────────────────────────────

DEFINE TABLE alert_instance SCHEMAFULL;

DEFINE FIELD rule_id       ON TABLE alert_instance TYPE record<alert_rule> ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE alert_instance TYPE string ASSERT $value != NONE;
DEFINE FIELD status        ON TABLE alert_instance TYPE string DEFAULT 'firing'
    ASSERT $value IN ['firing', 'resolved', 'silenced', 'acknowledged'];
DEFINE FIELD severity      ON TABLE alert_instance TYPE string;
DEFINE FIELD summary       ON TABLE alert_instance TYPE string;
DEFINE FIELD value         ON TABLE alert_instance TYPE option<float>;
DEFINE FIELD context       ON TABLE alert_instance TYPE option<object>;
DEFINE FIELD acknowledged_by ON TABLE alert_instance TYPE option<string>;
DEFINE FIELD acknowledged_at ON TABLE alert_instance TYPE option<datetime>;
DEFINE FIELD fired_at      ON TABLE alert_instance TYPE datetime DEFAULT time::now();
DEFINE FIELD resolved_at   ON TABLE alert_instance TYPE option<datetime>;

DEFINE INDEX idx_ai_rule    ON TABLE alert_instance COLUMNS rule_id;
DEFINE INDEX idx_ai_tenant  ON TABLE alert_instance COLUMNS tenant_id;
DEFINE INDEX idx_ai_status  ON TABLE alert_instance COLUMNS status;
DEFINE INDEX idx_ai_fired   ON TABLE alert_instance COLUMNS fired_at;

-- ─── Auto-create notification when alert fires ────────────────────────────────

DEFINE EVENT alert_notify ON TABLE alert_instance
    WHEN $event = 'CREATE' AND $after.status = 'firing'
    THEN (
        CREATE notification SET
            tenant_id  = $after.tenant_id,
            title      = string::concat('[', string::uppercase($after.severity), '] ', $after.summary),
            body       = $after.summary,
            level      = $after.severity,
            category   = 'platform',
            action_url = '/health',
            metadata   = { alert_instance: string($after.id), value: $after.value }
    );

-- ─── Auto-update rule last_fired + fire_count ────────────────────────────────

DEFINE EVENT alert_rule_fired ON TABLE alert_instance
    WHEN $event = 'CREATE'
    THEN (
        UPDATE $after.rule_id SET
            last_fired = time::now(),
            fire_count += 1
    );

-- ─── Seed: default platform alert rules ──────────────────────────────────────

INSERT IGNORE INTO alert_rule [
    {
        rule_id: 'alert-agent-degraded', tenant_id: 'platform',
        name: 'Agent health degraded', category: 'agent',
        source_table: 'health_check', window: '5m', severity: 'warning',
        condition: 'count(WHERE status = ''degraded'') > 0',
        notification_level: 'warning', active: true
    },
    {
        rule_id: 'alert-trust-fail-rate', tenant_id: 'platform',
        name: 'High trust failure rate', category: 'trust',
        source_table: 'trust_record', window: '1h', severity: 'error',
        condition: '(count(WHERE eval_status = ''failed'') / count()) > 0.2',
        notification_level: 'error', active: true
    },
    {
        rule_id: 'alert-high-latency', tenant_id: 'platform',
        name: 'P95 LLM latency > 10s', category: 'latency',
        source_table: 'llm_latency', window: '15m', severity: 'warning',
        condition: 'math::percentile(total_ms, 95) > 10000',
        notification_level: 'warning', active: true
    },
    {
        rule_id: 'alert-budget-90pct', tenant_id: 'platform',
        name: 'Budget > 90%', category: 'billing',
        source_table: 'usage_record', window: '1d', severity: 'critical',
        condition: 'fn::over_budget($auth.tenant_id)',
        notification_level: 'error', active: true
    }
];
