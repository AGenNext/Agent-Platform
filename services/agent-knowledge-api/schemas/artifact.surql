-- Schema: artifact
-- Graph type: schema:CreativeWork
-- Artifacts are the outputs produced by agent workflows

DEFINE TABLE artifact SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE artifact TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE artifact TYPE string DEFAULT 'CreativeWork';

-- schema:CreativeWork fields
DEFINE FIELD name          ON TABLE artifact TYPE string;
DEFINE FIELD description   ON TABLE artifact TYPE option<string>;
DEFINE FIELD text          ON TABLE artifact TYPE option<string>;
DEFINE FIELD url           ON TABLE artifact TYPE option<string>;
DEFINE FIELD encodingFormat ON TABLE artifact TYPE string DEFAULT 'application/json';

-- Provenance — links back to producing objective/task
DEFINE FIELD objective_id  ON TABLE artifact TYPE option<record<objective>>;
DEFINE FIELD task_id       ON TABLE artifact TYPE option<record<task>>;

-- Trust / evaluation
DEFINE FIELD trust_score   ON TABLE artifact TYPE option<float>;
DEFINE FIELD eval_status   ON TABLE artifact TYPE option<string>;

DEFINE FIELD created_at    ON TABLE artifact TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE artifact TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_artifact_objective ON TABLE artifact COLUMNS objective_id;
DEFINE INDEX idx_artifact_type      ON TABLE artifact COLUMNS `@type`;
