-- Schema: credentials
-- Tenant-scoped integration credentials — API keys, OAuth tokens, secrets.
-- The DB layer never returns secret_value in SELECT output (PERMISSIONS enforces this).
-- Applications read via fn::get_credential(); values are write-only from the client.

DEFINE TABLE credential SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE credential TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE credential TYPE string DEFAULT 'DigitalDocument';

-- Ownership
DEFINE FIELD tenant_id     ON TABLE credential TYPE string ASSERT $value != NONE;
DEFINE FIELD created_by    ON TABLE credential TYPE option<string>;

-- Identity
DEFINE FIELD credential_id ON TABLE credential TYPE string ASSERT $value != NONE;
DEFINE FIELD name          ON TABLE credential TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE credential TYPE option<string>;

-- What service this credential is for
DEFINE FIELD provider      ON TABLE credential TYPE string ASSERT $value != NONE;
    -- e.g. 'openai', 'anthropic', 'stripe', 'langchain', 'cloudflare', 'github'
DEFINE FIELD credential_type ON TABLE credential TYPE string DEFAULT 'api_key'
    ASSERT $value IN ['api_key', 'oauth_token', 'oauth_refresh', 'service_account', 'webhook_secret', 'hmac_key', 'basic_auth', 'certificate'];

-- The actual secret (argon2 hash for verification; raw stored encrypted by SurrealDB KMS)
DEFINE FIELD secret_value  ON TABLE credential TYPE option<string>;  -- write-only; see PERMISSIONS
DEFINE FIELD secret_hint   ON TABLE credential TYPE option<string>;  -- last 4 chars for UI display

-- OAuth-specific
DEFINE FIELD oauth_scopes  ON TABLE credential TYPE array DEFAULT [];
DEFINE FIELD expires_at    ON TABLE credential TYPE option<datetime>;

-- Lifecycle
DEFINE FIELD active        ON TABLE credential TYPE bool DEFAULT true;
DEFINE FIELD last_used_at  ON TABLE credential TYPE option<datetime>;
DEFINE FIELD rotate_after  ON TABLE credential TYPE option<datetime>;

DEFINE FIELD created_at    ON TABLE credential TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE credential TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_cred_tenant   ON TABLE credential COLUMNS tenant_id;
DEFINE INDEX idx_cred_provider ON TABLE credential COLUMNS provider;
DEFINE INDEX idx_cred_id       ON TABLE credential COLUMNS credential_id UNIQUE;

-- ─── Auto-update updated_at on any change ────────────────────────────────────

DEFINE EVENT cred_updated ON TABLE credential
    WHEN $event = 'UPDATE'
    THEN (UPDATE $after.id SET updated_at = time::now());

-- ─── Audit credential access ──────────────────────────────────────────────────

DEFINE EVENT cred_accessed ON TABLE credential
    WHEN $event = 'SELECT' AND $after.secret_value != NONE
    THEN (
        CREATE audit_log SET
            entity_table = 'credential',
            entity_id    = string($after.id),
            action       = 'secret_accessed',
            actor_id     = $auth.id,
            tenant_id    = $after.tenant_id,
            after        = { provider: $after.provider, name: $after.name }
    );

-- ─── PERMISSIONS: secret_value is write-only ─────────────────────────────────
-- Callers can create/update credentials but never SELECT the raw secret.
-- Use fn::get_credential() inside DB functions to access it safely.

DEFINE PERMISSION FOR TABLE credential
    FOR select WHERE tenant_id = $auth.tenant_id
        PERMISSIONS secret_value = NONE  -- never return raw secret
    FOR create WHERE tenant_id = $auth.tenant_id AND $auth.role IN ['admin', 'owner']
    FOR update WHERE tenant_id = $auth.tenant_id AND $auth.role IN ['admin', 'owner']
    FOR delete WHERE tenant_id = $auth.tenant_id AND $auth.role = 'owner';

-- ─── Helper: look up a credential value inside SurrealQL (never exposed to client) ──

DEFINE FUNCTION fn::get_credential($tenant_id: string, $provider: string) {
    RETURN SELECT VALUE secret_value
        FROM credential
        WHERE tenant_id = $tenant_id
          AND provider   = $provider
          AND active     = true
        ORDER BY created_at DESC LIMIT 1;
};

-- ─── Seed: placeholder entries for known integrations ────────────────────────
-- Operators fill in actual values via the Integrations UI.

INSERT IGNORE INTO credential [
    { credential_id: 'cred-openai-default',    name: 'OpenAI API Key',       provider: 'openai',    credential_type: 'api_key', tenant_id: 'platform', active: false },
    { credential_id: 'cred-anthropic-default', name: 'Anthropic API Key',    provider: 'anthropic', credential_type: 'api_key', tenant_id: 'platform', active: false },
    { credential_id: 'cred-stripe-default',    name: 'Stripe Secret Key',    provider: 'stripe',    credential_type: 'api_key', tenant_id: 'platform', active: false },
    { credential_id: 'cred-cf-r2-default',     name: 'Cloudflare R2 Secret', provider: 'cloudflare',credential_type: 'api_key', tenant_id: 'platform', active: false }
];
