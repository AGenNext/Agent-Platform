-- Schema: trust
-- Trust, provenance, and evaluation records.
-- Every artifact must have a trust record before it can be surfaced to users.

DEFINE TABLE trust_record SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE trust_record TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE trust_record TYPE string DEFAULT 'Rating';

-- schema:Rating fields
DEFINE FIELD name          ON TABLE trust_record TYPE string DEFAULT 'trust-evaluation';
DEFINE FIELD ratingValue   ON TABLE trust_record TYPE float DEFAULT 0.0
    ASSERT $value >= 0.0 AND $value <= 1.0;
DEFINE FIELD bestRating    ON TABLE trust_record TYPE float DEFAULT 1.0;
DEFINE FIELD worstRating   ON TABLE trust_record TYPE float DEFAULT 0.0;

-- Provenance chain
DEFINE FIELD artifact_id   ON TABLE trust_record TYPE option<record<artifact>>;
DEFINE FIELD objective_id  ON TABLE trust_record TYPE option<record<objective>>;
DEFINE FIELD agent_id      ON TABLE trust_record TYPE option<string>;

-- Evidence
DEFINE FIELD evidence      ON TABLE trust_record TYPE array DEFAULT [];
DEFINE FIELD eval_status   ON TABLE trust_record TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'passed', 'failed', 'manual_review'];
DEFINE FIELD reviewer      ON TABLE trust_record TYPE option<string>;
DEFINE FIELD notes         ON TABLE trust_record TYPE option<string>;

DEFINE FIELD evaluated_at  ON TABLE trust_record TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_trust_artifact  ON TABLE trust_record COLUMNS artifact_id;
DEFINE INDEX idx_trust_objective ON TABLE trust_record COLUMNS objective_id;
DEFINE INDEX idx_trust_status    ON TABLE trust_record COLUMNS eval_status;

-- Event: emit analytics event when artifact is trusted/rejected
DEFINE EVENT trust_evaluated ON TABLE trust_record
    WHEN $event = 'UPDATE' AND $before.eval_status = 'pending' AND $after.eval_status != 'pending'
    THEN (
        CREATE event CONTENT {
            name: string::concat('trust.', $after.eval_status),
            category: 'artifact',
            action: $after.eval_status,
            value: $after.ratingValue,
            metadata: { artifact_id: $after.artifact_id }
        }
    );
