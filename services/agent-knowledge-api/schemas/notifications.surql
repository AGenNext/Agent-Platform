-- Schema: notifications
-- In-platform notification system.
-- DEFINE EVENT auto-creates notifications on key state changes.
-- LIVE SELECT in the dashboard delivers them in real time — no polling.

DEFINE TABLE notification SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE notification TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE notification TYPE string DEFAULT 'Message';

DEFINE FIELD tenant_id     ON TABLE notification TYPE string ASSERT $value != NONE;
DEFINE FIELD user_id       ON TABLE notification TYPE option<string>;  -- None = broadcast to tenant
DEFINE FIELD agent_id      ON TABLE notification TYPE option<string>;  -- source agent

DEFINE FIELD title         ON TABLE notification TYPE string ASSERT $value != NONE;
DEFINE FIELD body          ON TABLE notification TYPE option<string>;
DEFINE FIELD level         ON TABLE notification TYPE string DEFAULT 'info'
    ASSERT $value IN ['info', 'success', 'warning', 'error'];
DEFINE FIELD category      ON TABLE notification TYPE string DEFAULT 'platform'
    ASSERT $value IN ['platform', 'agent', 'objective', 'trust', 'billing', 'security'];

DEFINE FIELD read          ON TABLE notification TYPE bool DEFAULT false;
DEFINE FIELD action_url    ON TABLE notification TYPE option<string>;
DEFINE FIELD metadata      ON TABLE notification TYPE object DEFAULT {};
DEFINE FIELD created_at    ON TABLE notification TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at    ON TABLE notification TYPE option<datetime>;

DEFINE INDEX idx_notif_tenant  ON TABLE notification COLUMNS tenant_id;
DEFINE INDEX idx_notif_user    ON TABLE notification COLUMNS user_id;
DEFINE INDEX idx_notif_read    ON TABLE notification COLUMNS read;
DEFINE INDEX idx_notif_created ON TABLE notification COLUMNS created_at;

-- ─── Auto-notifications from platform events ──────────────────────────────────

-- Alert when trust evaluation fails (artifact blocked)
DEFINE EVENT notify_trust_failed ON TABLE trust_record
    WHEN $event = 'CREATE' AND $after.eval_status = 'failed'
    THEN (
        CREATE notification SET
            tenant_id  = (SELECT VALUE tenant_id FROM ONLY agent WHERE agent_id = $after.agent_id LIMIT 1) ?? 'platform',
            agent_id   = $after.agent_id,
            title      = 'Artifact blocked — trust evaluation failed',
            body       = string::concat('Score: ', string($after.ratingValue), ' — below the 0.7 threshold. Review required.'),
            level      = 'error',
            category   = 'trust',
            action_url = string::concat('/artifacts?eval_status=failed'),
            metadata   = { artifact_id: $after.artifact_id, score: $after.ratingValue }
    );

-- Alert when agent goes offline (last_seen > 5 minutes — detect via heartbeat absence)
DEFINE EVENT notify_agent_degraded ON TABLE agent
    WHEN $event = 'UPDATE'
      AND $before.status != 'degraded'
      AND $after.status = 'degraded'
    THEN (
        CREATE notification SET
            tenant_id = $after.tenant_id,
            agent_id  = $after.agent_id,
            title     = string::concat('Agent degraded: ', $after.name),
            body      = 'No heartbeat received. Platform monitor will attempt auto-recovery.',
            level     = 'warning',
            category  = 'agent',
            action_url = '/health',
            metadata  = { agent_id: $after.agent_id }
    );

-- Notify when objective completes successfully
DEFINE EVENT notify_objective_completed ON TABLE objective
    WHEN $event = 'UPDATE'
      AND $before.status NOT IN ['completed']
      AND $after.status = 'completed'
    THEN (
        CREATE notification SET
            tenant_id  = $after.tenant_id,
            title      = 'Objective completed',
            body       = string::concat('Goal: ', string::slice($after.goal, 0, 100)),
            level      = 'success',
            category   = 'objective',
            action_url = string::concat('/runs'),
            metadata   = { objective_id: $after.id }
    );

-- Notify when budget alert threshold is crossed
DEFINE EVENT notify_budget_alert ON TABLE usage_record
    WHEN $event = 'CREATE'
    THEN {
        LET $budget = SELECT * FROM budget
            WHERE tenant_id = $after.tenant_id AND active = true AND period = 'monthly'
            LIMIT 1;
        IF array::len($budget) > 0 {
            LET $spent = SELECT VALUE math::sum(cost_usd) FROM usage_record
                WHERE tenant_id = $after.tenant_id
                  AND recorded_at >= time::floor(time::now(), 1month);
            LET $pct = ($spent[0] ?? 0) / $budget[0].limit_usd;
            IF $pct >= $budget[0].alert_pct AND $pct < 1.0 {
                CREATE notification SET
                    tenant_id  = $after.tenant_id,
                    title      = 'Budget alert',
                    body       = string::concat(string(math::round($pct * 100)), '% of monthly budget used'),
                    level      = 'warning',
                    category   = 'billing',
                    action_url = '/billing',
                    metadata   = { spent_usd: $spent[0], limit_usd: $budget[0].limit_usd }
            };
        };
    };

-- ─── Dashboard live query pattern ─────────────────────────────────────────────
-- LIVE SELECT * FROM notification
-- WHERE tenant_id = $auth.tenant_id AND read = false
-- ORDER BY created_at DESC;
