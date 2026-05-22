-- Schema: objective
-- Graph type: schema:Action (JSON-LD)
-- All objectives are stored as Schema.org Actions in SurrealDB

DEFINE TABLE objective SCHEMAFULL;

-- JSON-LD identity
DEFINE FIELD `@context`    ON TABLE objective TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE objective TYPE string DEFAULT 'Action';

-- schema:Action fields
DEFINE FIELD name          ON TABLE objective TYPE string;
DEFINE FIELD description   ON TABLE objective TYPE string;

-- Platform runtime fields
DEFINE FIELD goal          ON TABLE objective TYPE string ASSERT $value != NONE;
DEFINE FIELD agent_context ON TABLE objective TYPE object DEFAULT {};
DEFINE FIELD priority      ON TABLE objective TYPE int    DEFAULT 1
    ASSERT $value >= 1 AND $value <= 10;
DEFINE FIELD status        ON TABLE objective TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'running', 'completed', 'failed'];
DEFINE FIELD created_at    ON TABLE objective TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE objective TYPE datetime DEFAULT time::now();
DEFINE FIELD result        ON TABLE objective TYPE option<object>;
DEFINE FIELD error         ON TABLE objective TYPE option<string>;
DEFINE FIELD jsonld        ON TABLE objective TYPE object DEFAULT {};

-- Indexes
DEFINE INDEX idx_objective_status     ON TABLE objective COLUMNS status;
DEFINE INDEX idx_objective_created_at ON TABLE objective COLUMNS created_at;
DEFINE INDEX idx_objective_priority   ON TABLE objective COLUMNS priority;
