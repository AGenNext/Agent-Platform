-- Schema: deployments
-- Agent versioning and deployment lifecycle management.
-- Tracks agent versions, rollout strategies, canary deployments.
-- Every agent change creates a deployment record for full auditability.

DEFINE TABLE agent_version SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE agent_version TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE agent_version TYPE string DEFAULT 'SoftwareSourceCode';

DEFINE FIELD agent_id      ON TABLE agent_version TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE agent_version TYPE string ASSERT $value != NONE;
DEFINE FIELD version       ON TABLE agent_version TYPE string ASSERT $value != NONE;
    -- semver: '1.0.0', '1.1.0-canary.1'
DEFINE FIELD version_num   ON TABLE agent_version TYPE int ASSERT $value > 0;
    -- monotonic integer for ordering

-- What changed
DEFINE FIELD change_type   ON TABLE agent_version TYPE string DEFAULT 'config'
    ASSERT $value IN ['config', 'model', 'skills', 'capabilities', 'prompt', 'tools', 'full'];
DEFINE FIELD changelog     ON TABLE agent_version TYPE option<string>;
DEFINE FIELD diff_summary  ON TABLE agent_version TYPE option<object>;

-- Snapshot of the agent record at this version
DEFINE FIELD snapshot      ON TABLE agent_version TYPE object ASSERT $value != NONE;

-- Who approved this version
DEFINE FIELD approved_by   ON TABLE agent_version TYPE option<string>;
DEFINE FIELD approved_at   ON TABLE agent_version TYPE option<datetime>;

DEFINE FIELD created_by    ON TABLE agent_version TYPE option<string>;
DEFINE FIELD created_at    ON TABLE agent_version TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_ver_agent   ON TABLE agent_version COLUMNS agent_id;
DEFINE INDEX idx_ver_tenant  ON TABLE agent_version COLUMNS tenant_id;
DEFINE INDEX idx_ver_num     ON TABLE agent_version COLUMNS agent_id, version_num;

-- ─── Deployment record ────────────────────────────────────────────────────────

DEFINE TABLE deployment SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE deployment TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE deployment TYPE string DEFAULT 'Action';

DEFINE FIELD deployment_id ON TABLE deployment TYPE string ASSERT $value != NONE;
DEFINE FIELD agent_id      ON TABLE deployment TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE deployment TYPE string ASSERT $value != NONE;
DEFINE FIELD version       ON TABLE deployment TYPE string ASSERT $value != NONE;

DEFINE FIELD strategy      ON TABLE deployment TYPE string DEFAULT 'rolling'
    ASSERT $value IN ['rolling', 'canary', 'blue_green', 'recreate', 'shadow'];

-- Traffic split (canary: 0–100% to new version)
DEFINE FIELD traffic_pct   ON TABLE deployment TYPE float DEFAULT 100.0
    ASSERT $value >= 0.0 AND $value <= 100.0;
DEFINE FIELD previous_version ON TABLE deployment TYPE option<string>;

DEFINE FIELD status        ON TABLE deployment TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'in_progress', 'healthy', 'degraded', 'rolled_back', 'failed'];

-- Automated health gate
DEFINE FIELD health_checks_passed ON TABLE deployment TYPE int DEFAULT 0;
DEFINE FIELD health_checks_required ON TABLE deployment TYPE int DEFAULT 3;
DEFINE FIELD auto_rollback ON TABLE deployment TYPE bool DEFAULT true;
DEFINE FIELD rollback_threshold ON TABLE deployment TYPE float DEFAULT 0.05;
    -- error rate above 5% triggers auto-rollback

DEFINE FIELD deployed_by   ON TABLE deployment TYPE option<string>;
DEFINE FIELD started_at    ON TABLE deployment TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at  ON TABLE deployment TYPE option<datetime>;
DEFINE FIELD notes         ON TABLE deployment TYPE option<string>;

DEFINE INDEX idx_deploy_id     ON TABLE deployment COLUMNS deployment_id UNIQUE;
DEFINE INDEX idx_deploy_agent  ON TABLE deployment COLUMNS agent_id;
DEFINE INDEX idx_deploy_tenant ON TABLE deployment COLUMNS tenant_id;
DEFINE INDEX idx_deploy_status ON TABLE deployment COLUMNS status;

-- ─── Auto-snapshot agent version on CREATE ────────────────────────────────────

DEFINE EVENT agent_version_snapshot ON TABLE agent
    WHEN $event = 'CREATE'
    THEN (
        CREATE agent_version SET
            agent_id    = $after.agent_id,
            tenant_id   = $after.tenant_id,
            version     = '1.0.0',
            version_num = 1,
            change_type = 'full',
            changelog   = 'Initial registration',
            snapshot    = $after,
            created_by  = $auth.id
    );

-- ─── Auto-create deployment on agent status change ────────────────────────────

DEFINE EVENT agent_deploy_event ON TABLE deployment
    WHEN $event = 'UPDATE'
      AND $before.status = 'in_progress'
      AND $after.status = 'healthy'
    THEN (
        -- Update the agent record to point to new version
        UPDATE agent SET
            version    = $after.version,
            updated_at = time::now()
        WHERE agent_id = $after.agent_id
    );

-- ─── Auto-rollback on degraded deployment ─────────────────────────────────────

DEFINE EVENT deployment_auto_rollback ON TABLE deployment
    WHEN $event = 'UPDATE'
      AND $after.status = 'degraded'
      AND $after.auto_rollback = true
      AND $after.previous_version != NONE
    THEN (
        UPDATE $after.id SET status = 'rolled_back', completed_at = time::now();
        UPDATE agent SET version = $after.previous_version
            WHERE agent_id = $after.agent_id;
        CREATE notification SET
            tenant_id  = $after.tenant_id,
            title      = string::concat('Auto-rollback: ', $after.agent_id),
            body       = string::concat('Reverted to ', $after.previous_version, ' due to degraded health.'),
            level      = 'warning',
            category   = 'agent',
            action_url = '/agents'
    );
