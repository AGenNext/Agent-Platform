-- Schema: task
-- Graph type: schema:Action > sub-action of an objective
-- Tasks are child actions within an objective run

DEFINE TABLE task SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE task TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE task TYPE string DEFAULT 'Action';

DEFINE FIELD name          ON TABLE task TYPE string;
DEFINE FIELD description   ON TABLE task TYPE string;

-- Relationship back to parent objective
DEFINE FIELD objective_id  ON TABLE task TYPE record<objective> ASSERT $value != NONE;

-- Task runtime fields
DEFINE FIELD agent_id      ON TABLE task TYPE option<string>;
DEFINE FIELD status        ON TABLE task TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'running', 'completed', 'failed', 'skipped'];
DEFINE FIELD input         ON TABLE task TYPE option<object>;
DEFINE FIELD output        ON TABLE task TYPE option<object>;
DEFINE FIELD error         ON TABLE task TYPE option<string>;
DEFINE FIELD created_at    ON TABLE task TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE task TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_task_objective ON TABLE task COLUMNS objective_id;
DEFINE INDEX idx_task_status    ON TABLE task COLUMNS status;
