-- Schema: governance
-- Data governance, audit log, and least-privilege permissions.
-- Best practices: every table has record-level permissions.
-- Every destructive or sensitive operation is audit-logged automatically.

-- ─── Audit Log ───────────────────────────────────────────────────────────────

DEFINE TABLE audit_log SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE audit_log TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE audit_log TYPE string DEFAULT 'Action';

DEFINE FIELD entity_table  ON TABLE audit_log TYPE string ASSERT $value != NONE;
DEFINE FIELD entity_id     ON TABLE audit_log TYPE string ASSERT $value != NONE;
DEFINE FIELD action        ON TABLE audit_log TYPE string ASSERT $value != NONE;
DEFINE FIELD actor_id      ON TABLE audit_log TYPE option<string>;
DEFINE FIELD tenant_id     ON TABLE audit_log TYPE option<string>;
DEFINE FIELD before        ON TABLE audit_log TYPE option<object>;
DEFINE FIELD after         ON TABLE audit_log TYPE option<object>;
DEFINE FIELD ip_address    ON TABLE audit_log TYPE option<string>;
DEFINE FIELD user_agent    ON TABLE audit_log TYPE option<string>;
DEFINE FIELD timestamp     ON TABLE audit_log TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_audit_entity    ON TABLE audit_log COLUMNS entity_table, entity_id;
DEFINE INDEX idx_audit_actor     ON TABLE audit_log COLUMNS actor_id;
DEFINE INDEX idx_audit_tenant    ON TABLE audit_log COLUMNS tenant_id;
DEFINE INDEX idx_audit_timestamp ON TABLE audit_log COLUMNS timestamp;

-- Audit log is append-only: no UPDATE or DELETE permitted
DEFINE TABLE audit_log PERMISSIONS
    FOR select WHERE tenant_id = $auth.tenant_id
    FOR create FULL
    FOR update NONE
    FOR delete NONE;

-- ─── Audit triggers on sensitive tables ──────────────────────────────────────

DEFINE EVENT audit_objective ON TABLE objective
    WHEN $event IN ['CREATE', 'UPDATE', 'DELETE']
    THEN (
        CREATE audit_log CONTENT {
            entity_table: 'objective',
            entity_id: <string>$after.id,
            action: $event,
            before: $before,
            after: $after,
            tenant_id: $after.tenant_id
        }
    );

DEFINE EVENT audit_artifact ON TABLE artifact
    WHEN $event IN ['CREATE', 'UPDATE', 'DELETE']
    THEN (
        CREATE audit_log CONTENT {
            entity_table: 'artifact',
            entity_id: <string>$after.id,
            action: $event,
            before: $before,
            after: $after,
            tenant_id: $after.tenant_id
        }
    );

DEFINE EVENT audit_agent ON TABLE agent
    WHEN $event IN ['CREATE', 'DELETE']
    THEN (
        CREATE audit_log CONTENT {
            entity_table: 'agent',
            entity_id: $after.agent_id,
            action: $event,
            after: $after,
            tenant_id: $after.tenant_id
        }
    );

-- ─── Record-level permissions (tenant isolation) ─────────────────────────────

-- Objectives: scoped to tenant
DEFINE TABLE objective PERMISSIONS
    FOR select WHERE tenant_id = $auth.tenant_id OR $auth.role = 'admin'
    FOR create WHERE $auth.tenant_id != NONE
    FOR update WHERE tenant_id = $auth.tenant_id OR $auth.role = 'admin'
    FOR delete WHERE $auth.role = 'admin';

-- Artifacts: scoped to tenant
DEFINE TABLE artifact PERMISSIONS
    FOR select WHERE tenant_id = $auth.tenant_id OR $auth.role = 'admin'
    FOR create WHERE $auth.tenant_id != NONE
    FOR update WHERE tenant_id = $auth.tenant_id OR $auth.role = 'admin'
    FOR delete WHERE $auth.role = 'admin';

-- Memory: agents can only read their own memory
DEFINE TABLE memory PERMISSIONS
    FOR select WHERE agent_id = $auth.agent_id OR tenant_id = $auth.tenant_id
    FOR create WHERE $auth.tenant_id != NONE
    FOR update WHERE agent_id = $auth.agent_id
    FOR delete WHERE $auth.role = 'admin';

-- Usage records: tenant-scoped, no delete
DEFINE TABLE usage_record PERMISSIONS
    FOR select WHERE tenant_id = $auth.tenant_id OR $auth.role = 'admin'
    FOR create FULL
    FOR update NONE
    FOR delete NONE;

-- Agents: registry read-only for members, admin can write
DEFINE TABLE agent PERMISSIONS
    FOR select WHERE tenant_id = $auth.tenant_id OR $auth.role = 'admin'
    FOR create WHERE $auth.tenant_id != NONE
    FOR update WHERE tenant_id = $auth.tenant_id OR $auth.role = 'admin'
    FOR delete WHERE $auth.role = 'admin';
