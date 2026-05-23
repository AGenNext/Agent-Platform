-- Schema: access_control
-- DEFINE ACCESS — SurrealDB 2.x JWT-based access control.
-- Replaces DEFINE SCOPE from 1.x. Supports bearer tokens and record access.
-- Ref: https://surrealdb.com/docs/surrealql/statements/define/access

-- ─── JWT bearer token access (service-to-service) ────────────────────────────
-- Used by agent-knowledge-api to call SurrealDB directly.

DEFINE ACCESS token_api ON DATABASE TYPE JWT
    ALGORITHM HS256
    KEY env('SURREALDB_JWT_SECRET')
    DURATION FOR TOKEN 1h, FOR SESSION 24h;

-- ─── Multi-tenant user access ────────────────────────────────────────────────
-- Human users sign up / sign in and get a session scoped to their tenant.

DEFINE ACCESS user_session ON DATABASE TYPE RECORD
    SIGNUP (
        CREATE account SET
            email      = string::lowercase(string::trim($email)),
            name       = $name,
            tenant_id  = $tenant_id,
            password   = crypto::argon2::generate($password),
            role       = 'member',
            created_at = time::now()
    )
    SIGNIN (
        SELECT * FROM account
        WHERE email = string::lowercase(string::trim($email))
          AND crypto::argon2::compare(password, $password)
          AND tenant_id = $tenant_id
    )
    DURATION FOR TOKEN 1h, FOR SESSION 8h;

-- ─── Agent access (machine identity) ─────────────────────────────────────────
-- Agents authenticate with agent_id + secret to get a scoped token.

DEFINE ACCESS agent_session ON DATABASE TYPE RECORD
    SIGNIN (
        SELECT * FROM agent
        WHERE agent_id = $agent_id
          AND crypto::argon2::compare(agent_secret, $secret)
    )
    DURATION FOR TOKEN 30m, FOR SESSION 2h;

-- ─── Tenant-scoped permissions ────────────────────────────────────────────────
-- Every sensitive table locks SELECT/CREATE/UPDATE/DELETE to the auth tenant.

DEFINE PERMISSION FOR TABLE agent
    FOR select WHERE tenant_id = $auth.tenant_id
    FOR create WHERE tenant_id = $auth.tenant_id
    FOR update WHERE tenant_id = $auth.tenant_id AND $auth.role IN ['admin', 'owner']
    FOR delete WHERE tenant_id = $auth.tenant_id AND $auth.role = 'owner';

DEFINE PERMISSION FOR TABLE objective
    FOR select WHERE tenant_id = $auth.tenant_id
    FOR create WHERE tenant_id = $auth.tenant_id
    FOR update WHERE tenant_id = $auth.tenant_id
    FOR delete WHERE tenant_id = $auth.tenant_id AND $auth.role IN ['admin', 'owner'];

DEFINE PERMISSION FOR TABLE memory
    FOR select WHERE agent_id = $auth.agent_id OR $auth.role IN ['admin', 'owner']
    FOR create WHERE agent_id = $auth.agent_id
    FOR update WHERE agent_id = $auth.agent_id
    FOR delete NONE;

DEFINE PERMISSION FOR TABLE usage_record
    FOR select WHERE tenant_id = $auth.tenant_id
    FOR create WHERE tenant_id = $auth.tenant_id
    FOR update NONE
    FOR delete NONE;

DEFINE PERMISSION FOR TABLE audit_log
    FOR select WHERE tenant_id = $auth.tenant_id AND $auth.role IN ['admin', 'owner']
    FOR create WHERE tenant_id = $auth.tenant_id
    FOR update NONE
    FOR delete NONE;

-- ─── Public read (no auth required) ──────────────────────────────────────────
-- Blueprint catalog is public — no tenant isolation needed.

DEFINE PERMISSION FOR TABLE blueprint
    FOR select FULL
    FOR create WHERE $auth.role IN ['admin', 'owner']
    FOR update WHERE $auth.role IN ['admin', 'owner']
    FOR delete WHERE $auth.role = 'owner';

DEFINE PERMISSION FOR TABLE skill
    FOR select FULL
    FOR create WHERE $auth.role IN ['admin', 'owner']
    FOR update WHERE $auth.role IN ['admin', 'owner']
    FOR delete WHERE $auth.role = 'owner';
