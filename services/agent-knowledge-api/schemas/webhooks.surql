-- Schema: webhooks
-- Outbound webhook delivery system.
-- Agents and platform events trigger webhook_delivery records.
-- A background process (or DEFINE EVENT) sends them to registered endpoints.

DEFINE TABLE webhook_endpoint SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE webhook_endpoint TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE webhook_endpoint TYPE string DEFAULT 'EntryPoint';

DEFINE FIELD name          ON TABLE webhook_endpoint TYPE string ASSERT $value != NONE;
DEFINE FIELD url           ON TABLE webhook_endpoint TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE webhook_endpoint TYPE string ASSERT $value != NONE;
DEFINE FIELD secret        ON TABLE webhook_endpoint TYPE option<string>;  -- HMAC signing secret

-- Which events trigger this endpoint
DEFINE FIELD events        ON TABLE webhook_endpoint TYPE array DEFAULT []
    ASSERT array::len($value) > 0;
-- e.g. ['agent.registered', 'objective.completed', 'artifact.evaluated', 'trust.failed']

DEFINE FIELD active        ON TABLE webhook_endpoint TYPE bool DEFAULT true;
DEFINE FIELD headers       ON TABLE webhook_endpoint TYPE object DEFAULT {};
DEFINE FIELD created_at    ON TABLE webhook_endpoint TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_webhook_tenant ON TABLE webhook_endpoint COLUMNS tenant_id;
DEFINE INDEX idx_webhook_active ON TABLE webhook_endpoint COLUMNS active;

-- ─── Delivery records (append-only) ──────────────────────────────────────────

DEFINE TABLE webhook_delivery SCHEMAFULL;

DEFINE FIELD endpoint_id   ON TABLE webhook_delivery TYPE record<webhook_endpoint> ASSERT $value != NONE;
DEFINE FIELD event_name    ON TABLE webhook_delivery TYPE string ASSERT $value != NONE;
DEFINE FIELD payload       ON TABLE webhook_delivery TYPE object ASSERT $value != NONE;

DEFINE FIELD status        ON TABLE webhook_delivery TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'sent', 'failed', 'retrying'];
DEFINE FIELD attempt       ON TABLE webhook_delivery TYPE int DEFAULT 0;
DEFINE FIELD max_attempts  ON TABLE webhook_delivery TYPE int DEFAULT 3;
DEFINE FIELD response_code ON TABLE webhook_delivery TYPE option<int>;
DEFINE FIELD response_body ON TABLE webhook_delivery TYPE option<string>;
DEFINE FIELD error         ON TABLE webhook_delivery TYPE option<string>;

DEFINE FIELD scheduled_at  ON TABLE webhook_delivery TYPE datetime DEFAULT time::now();
DEFINE FIELD sent_at       ON TABLE webhook_delivery TYPE option<datetime>;

DEFINE INDEX idx_delivery_endpoint ON TABLE webhook_delivery COLUMNS endpoint_id;
DEFINE INDEX idx_delivery_status   ON TABLE webhook_delivery COLUMNS status;
DEFINE INDEX idx_delivery_event    ON TABLE webhook_delivery COLUMNS event_name;

-- ─── Auto-enqueue webhook on key platform events ──────────────────────────────

-- Fire webhook when an objective completes
DEFINE EVENT webhook_objective_completed ON TABLE objective
    WHEN $event = 'UPDATE'
      AND $before.status != 'completed'
      AND $after.status = 'completed'
    THEN {
        LET $endpoints = SELECT * FROM webhook_endpoint
            WHERE active = true
              AND tenant_id = $after.tenant_id
              AND events CONTAINS 'objective.completed';
        FOR $ep IN $endpoints {
            CREATE webhook_delivery SET
                endpoint_id = $ep.id,
                event_name  = 'objective.completed',
                payload     = {
                    objective_id: $after.id,
                    goal:         $after.goal,
                    status:       $after.status,
                    tenant_id:    $after.tenant_id
                };
        };
    };

-- Fire webhook when trust evaluation fails
DEFINE EVENT webhook_trust_failed ON TABLE trust_record
    WHEN $event = 'CREATE' AND $after.eval_status = 'failed'
    THEN {
        LET $endpoints = SELECT * FROM webhook_endpoint
            WHERE active = true
              AND events CONTAINS 'trust.failed';
        FOR $ep IN $endpoints {
            CREATE webhook_delivery SET
                endpoint_id = $ep.id,
                event_name  = 'trust.failed',
                payload     = {
                    artifact_id:  $after.artifact_id,
                    rating_value: $after.ratingValue,
                    agent_id:     $after.agent_id
                };
        };
    };

-- Fire webhook when agent is registered
DEFINE EVENT webhook_agent_registered ON TABLE agent
    WHEN $event = 'CREATE'
    THEN {
        LET $endpoints = SELECT * FROM webhook_endpoint
            WHERE active = true
              AND tenant_id = $after.tenant_id
              AND events CONTAINS 'agent.registered';
        FOR $ep IN $endpoints {
            CREATE webhook_delivery SET
                endpoint_id = $ep.id,
                event_name  = 'agent.registered',
                payload     = {
                    agent_id:  $after.agent_id,
                    name:      $after.name,
                    tenant_id: $after.tenant_id
                };
        };
    };
