-- Schema: trace
-- A2A (agent-to-agent) handoff trace records
-- OpenTelemetry-aligned

DEFINE TABLE trace SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE trace TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE trace TYPE string DEFAULT 'Action';

DEFINE FIELD trace_id      ON TABLE trace TYPE string ASSERT $value != NONE;
DEFINE FIELD span_id       ON TABLE trace TYPE string ASSERT $value != NONE;
DEFINE FIELD parent_span   ON TABLE trace TYPE option<string>;

-- Source / target agents
DEFINE FIELD from_agent    ON TABLE trace TYPE option<string>;
DEFINE FIELD to_agent      ON TABLE trace TYPE option<string>;

-- Relationship to objective and task
DEFINE FIELD objective_id  ON TABLE trace TYPE option<record<objective>>;
DEFINE FIELD task_id       ON TABLE trace TYPE option<record<task>>;

DEFINE FIELD event_type    ON TABLE trace TYPE string DEFAULT 'event';
DEFINE FIELD payload       ON TABLE trace TYPE option<object>;
DEFINE FIELD timestamp     ON TABLE trace TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_trace_trace_id    ON TABLE trace COLUMNS trace_id;
DEFINE INDEX idx_trace_objective   ON TABLE trace COLUMNS objective_id;
DEFINE INDEX idx_trace_timestamp   ON TABLE trace COLUMNS timestamp;
