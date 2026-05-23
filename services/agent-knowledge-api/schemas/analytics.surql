-- Schema: analytics
-- Native analytics replacing Metabase
-- Uses SurrealDB computed fields + live queries for dashboards

DEFINE TABLE event SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE event TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE event TYPE string DEFAULT 'Event';

-- schema:Event fields
DEFINE FIELD name          ON TABLE event TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE event TYPE option<string>;

-- Event classification
DEFINE FIELD category      ON TABLE event TYPE string DEFAULT 'platform'
    ASSERT $value IN ['platform','objective','task','artifact','billing','health','agent'];
DEFINE FIELD action        ON TABLE event TYPE string;
DEFINE FIELD label         ON TABLE event TYPE option<string>;
DEFINE FIELD value         ON TABLE event TYPE option<float>;

-- Provenance
DEFINE FIELD objective_id  ON TABLE event TYPE option<record<objective>>;
DEFINE FIELD task_id       ON TABLE event TYPE option<record<task>>;
DEFINE FIELD account_id    ON TABLE event TYPE option<record<account>>;
DEFINE FIELD tenant_id     ON TABLE event TYPE option<string>;

DEFINE FIELD timestamp     ON TABLE event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata      ON TABLE event TYPE option<object>;

DEFINE INDEX idx_event_category  ON TABLE event COLUMNS category;
DEFINE INDEX idx_event_timestamp ON TABLE event COLUMNS timestamp;
DEFINE INDEX idx_event_tenant    ON TABLE event COLUMNS tenant_id;

-- Emit analytics event on every new objective (SurrealDB EVENT)
DEFINE EVENT objective_created ON TABLE objective
    WHEN $event = 'CREATE'
    THEN (
        CREATE event CONTENT {
            name: 'objective.created',
            category: 'objective',
            action: 'create',
            label: $after.goal,
            objective_id: $after.id,
            tenant_id: $after.tenant_id
        }
    );

-- Emit analytics event when objective status changes
DEFINE EVENT objective_status_changed ON TABLE objective
    WHEN $event = 'UPDATE' AND $before.status != $after.status
    THEN (
        CREATE event CONTENT {
            name: 'objective.status_changed',
            category: 'objective',
            action: $after.status,
            label: $after.goal,
            objective_id: $after.id
        }
    );
