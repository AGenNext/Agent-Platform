-- Schema: skill
-- Skill registry — maps agent capabilities to executable skill definitions.
-- An agent must declare its skill_ids at registration time.

DEFINE TABLE skill SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE skill TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE skill TYPE string DEFAULT 'HowToStep';

-- schema:HowToStep identity
DEFINE FIELD name          ON TABLE skill TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE skill TYPE option<string>;

-- Skill classification
DEFINE FIELD skill_id      ON TABLE skill TYPE string ASSERT $value != NONE;
DEFINE FIELD category      ON TABLE skill TYPE string DEFAULT 'general';
DEFINE FIELD input_schema  ON TABLE skill TYPE option<object>;
DEFINE FIELD output_schema ON TABLE skill TYPE option<object>;

-- Which agents own this skill
DEFINE FIELD agent_id      ON TABLE skill TYPE option<string>;
DEFINE FIELD tenant_id     ON TABLE skill TYPE option<string>;

DEFINE FIELD version       ON TABLE skill TYPE string DEFAULT '0.1.0';
DEFINE FIELD active        ON TABLE skill TYPE bool DEFAULT true;
DEFINE FIELD created_at    ON TABLE skill TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_skill_id       ON TABLE skill COLUMNS skill_id UNIQUE;
DEFINE INDEX idx_skill_agent    ON TABLE skill COLUMNS agent_id;
DEFINE INDEX idx_skill_category ON TABLE skill COLUMNS category;
