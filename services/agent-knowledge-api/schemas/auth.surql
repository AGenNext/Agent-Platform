-- Schema: auth / tenancy
-- SurrealDB built-in auth replaces Infisical for local/dev secrets
-- Namespace = tenant isolation, Database = product domain

DEFINE TABLE account SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE account TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE account TYPE string DEFAULT 'Person';

-- schema:Person / schema:Organization
DEFINE FIELD email         ON TABLE account TYPE string ASSERT string::is::email($value);
DEFINE FIELD name          ON TABLE account TYPE option<string>;
DEFINE FIELD role          ON TABLE account TYPE string DEFAULT 'member'
    ASSERT $value IN ['admin', 'member', 'viewer'];
DEFINE FIELD tenant_id     ON TABLE account TYPE option<string>;
DEFINE FIELD created_at    ON TABLE account TYPE datetime DEFAULT time::now();
DEFINE FIELD active        ON TABLE account TYPE bool DEFAULT true;

DEFINE INDEX idx_account_email     ON TABLE account COLUMNS email UNIQUE;
DEFINE INDEX idx_account_tenant    ON TABLE account COLUMNS tenant_id;

-- Scope-based auth: each tenant gets their own JWT scope
DEFINE SCOPE agent_user
    SESSION 24h
    SIGNUP (
        CREATE account CONTENT {
            email: $email,
            name: $name,
            role: 'member',
            tenant_id: $tenant_id
        }
    )
    SIGNIN (
        SELECT * FROM account
        WHERE email = $email
        AND active = true
    );
