-- Schema: policy / constraints
-- Agent-Constraints contract: runtime guardrails stored in SurrealDB.
-- Every objective is evaluated against active policies before execution.

DEFINE TABLE policy SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE policy TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE policy TYPE string DEFAULT 'DigitalDocument';

DEFINE FIELD name          ON TABLE policy TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE policy TYPE option<string>;
DEFINE FIELD policy_id     ON TABLE policy TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE policy TYPE option<string>;

-- Policy type
DEFINE FIELD category      ON TABLE policy TYPE string DEFAULT 'guardrail'
    ASSERT $value IN ['guardrail', 'cost', 'model', 'data', 'security', 'compliance'];

-- Policy rule (SurrealQL expression evaluated at runtime)
DEFINE FIELD rule          ON TABLE policy TYPE string ASSERT $value != NONE;
DEFINE FIELD action        ON TABLE policy TYPE string DEFAULT 'block'
    ASSERT $value IN ['block', 'warn', 'log', 'allow'];
DEFINE FIELD priority      ON TABLE policy TYPE int DEFAULT 100;
DEFINE FIELD active        ON TABLE policy TYPE bool DEFAULT true;

DEFINE FIELD created_at    ON TABLE policy TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE policy TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata      ON TABLE policy TYPE option<object>;

DEFINE INDEX idx_policy_id       ON TABLE policy COLUMNS policy_id UNIQUE;
DEFINE INDEX idx_policy_tenant   ON TABLE policy COLUMNS tenant_id;
DEFINE INDEX idx_policy_category ON TABLE policy COLUMNS category;
DEFINE INDEX idx_policy_active   ON TABLE policy COLUMNS active;

-- ─── Default platform policies (seeded on startup) ───────────────────────────
-- Insert only if not already present. Applied by schema_loader on startup.

INSERT IGNORE INTO policy [
    {
        policy_id: 'cost.no-unattributed-objective',
        name: 'No objective without cost attribution',
        description: 'Every objective run must have a tenant_id for billing attribution.',
        category: 'cost',
        rule: '$objective.tenant_id != NONE',
        action: 'block',
        priority: 1
    },
    {
        policy_id: 'agent.no-unregistered-execution',
        name: 'No execution without registry entry',
        description: 'Agents must be registered with all capabilities before executing.',
        category: 'guardrail',
        rule: '$agent.capabilities.analytics = true AND $agent.capabilities.billing = true',
        action: 'block',
        priority: 1
    },
    {
        policy_id: 'data.no-secrets-in-artifacts',
        name: 'No secrets in artifact content',
        description: 'Artifacts must not contain secrets, API keys, or credentials.',
        category: 'security',
        rule: 'NOT string::contains($artifact.text, "sk-") AND NOT string::contains($artifact.text, "ghp_")',
        action: 'block',
        priority: 1
    },
    {
        policy_id: 'trust.no-unevaluated-artifact',
        name: 'No artifact surfaced without trust evaluation',
        description: 'Every artifact must have a passing trust_record before surfacing.',
        category: 'compliance',
        rule: '$trust.eval_status = "passed"',
        action: 'block',
        priority: 2
    }
];
