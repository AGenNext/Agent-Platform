-- Schema: billing / metering
-- Native cost tracking replacing Lago
-- Every objective run gets cost attribution via SurrealDB events

DEFINE TABLE usage_record SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE usage_record TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE usage_record TYPE string DEFAULT 'Invoice';

-- Usage dimensions
DEFINE FIELD tenant_id     ON TABLE usage_record TYPE string ASSERT $value != NONE;
DEFINE FIELD objective_id  ON TABLE usage_record TYPE option<record<objective>>;
DEFINE FIELD task_id       ON TABLE usage_record TYPE option<record<task>>;
DEFINE FIELD model_id      ON TABLE usage_record TYPE option<string>;
DEFINE FIELD provider      ON TABLE usage_record TYPE option<string>;

-- Metering
DEFINE FIELD tokens_in     ON TABLE usage_record TYPE int DEFAULT 0;
DEFINE FIELD tokens_out    ON TABLE usage_record TYPE int DEFAULT 0;
DEFINE FIELD cost_usd      ON TABLE usage_record TYPE float DEFAULT 0.0;
DEFINE FIELD duration_ms   ON TABLE usage_record TYPE option<int>;

DEFINE FIELD recorded_at   ON TABLE usage_record TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_usage_tenant    ON TABLE usage_record COLUMNS tenant_id;
DEFINE INDEX idx_usage_objective ON TABLE usage_record COLUMNS objective_id;
DEFINE INDEX idx_usage_recorded  ON TABLE usage_record COLUMNS recorded_at;

-- Aggregated spend view per tenant (computed via SurrealQL query)
-- Query: SELECT tenant_id, math::sum(cost_usd) AS total_spend FROM usage_record GROUP BY tenant_id

DEFINE TABLE budget SCHEMAFULL;

DEFINE FIELD tenant_id     ON TABLE budget TYPE string ASSERT $value != NONE;
DEFINE FIELD period        ON TABLE budget TYPE string DEFAULT 'monthly'
    ASSERT $value IN ['daily','weekly','monthly','annual'];
DEFINE FIELD limit_usd     ON TABLE budget TYPE float ASSERT $value > 0;
DEFINE FIELD alert_pct     ON TABLE budget TYPE float DEFAULT 0.8
    ASSERT $value > 0 AND $value <= 1.0;
DEFINE FIELD active        ON TABLE budget TYPE bool DEFAULT true;
DEFINE FIELD created_at    ON TABLE budget TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_budget_tenant ON TABLE budget COLUMNS tenant_id UNIQUE;
