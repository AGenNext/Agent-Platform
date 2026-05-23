-- AGenNext Platform
-- 0061: Enterprise business app integration via existing IAM, IGA, and IdP stack
-- Purpose: let IT admins connect SSO/IGA first, discover apps, identify app owners, request app-level connections, and let app owners manage licenses, roles, employee lifecycle, and agent lifecycle without replacing existing tools.

DEFINE TABLE enterprise_identity_platform_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_identity_platform_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON enterprise_identity_platform_connectors TYPE string;
DEFINE FIELD platform_kind ON enterprise_identity_platform_connectors TYPE string;
DEFINE FIELD provider_name ON enterprise_identity_platform_connectors TYPE string;
DEFINE FIELD capabilities ON enterprise_identity_platform_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD connection_status ON enterprise_identity_platform_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD sync_status ON enterprise_identity_platform_connectors TYPE string DEFAULT 'not_started';
DEFINE FIELD last_synced_at ON enterprise_identity_platform_connectors TYPE option<datetime>;
DEFINE FIELD created_at ON enterprise_identity_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_identity_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_identity_platform_connector_unique ON enterprise_identity_platform_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE enterprise_discovered_business_apps SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_discovered_business_apps TYPE record<tenants>;
DEFINE FIELD source_connector_id ON enterprise_discovered_business_apps TYPE record<enterprise_identity_platform_connectors>;
DEFINE FIELD app_key ON enterprise_discovered_business_apps TYPE string;
DEFINE FIELD app_name ON enterprise_discovered_business_apps TYPE string;
DEFINE FIELD app_category ON enterprise_discovered_business_apps TYPE option<string>;
DEFINE FIELD source_system_app_id ON enterprise_discovered_business_apps TYPE option<string>;
DEFINE FIELD app_owner_person_ids ON enterprise_discovered_business_apps TYPE array<record<identity_persons>> DEFAULT [];
DEFINE FIELD app_owner_emails ON enterprise_discovered_business_apps TYPE array<string> DEFAULT [];
DEFINE FIELD user_count ON enterprise_discovered_business_apps TYPE int DEFAULT 0;
DEFINE FIELD license_count ON enterprise_discovered_business_apps TYPE int DEFAULT 0;
DEFINE FIELD integration_status ON enterprise_discovered_business_apps TYPE string DEFAULT 'discovered';
DEFINE FIELD lifecycle_status ON enterprise_discovered_business_apps TYPE string DEFAULT 'active';
DEFINE FIELD discovered_at ON enterprise_discovered_business_apps TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_discovered_business_apps TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_discovered_business_app_unique ON enterprise_discovered_business_apps FIELDS tenant_id, app_key UNIQUE;

DEFINE TABLE enterprise_app_connection_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_app_connection_requests TYPE record<tenants>;
DEFINE FIELD app_id ON enterprise_app_connection_requests TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD requested_by_person_id ON enterprise_app_connection_requests TYPE option<record<identity_persons>>;
DEFINE FIELD requested_owner_person_id ON enterprise_app_connection_requests TYPE option<record<identity_persons>>;
DEFINE FIELD requested_owner_email ON enterprise_app_connection_requests TYPE option<string>;
DEFINE FIELD request_reason ON enterprise_app_connection_requests TYPE string;
DEFINE FIELD requested_capabilities ON enterprise_app_connection_requests TYPE array<string> DEFAULT [];
DEFINE FIELD request_status ON enterprise_app_connection_requests TYPE string DEFAULT 'pending_owner_action';
DEFINE FIELD sent_at ON enterprise_app_connection_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD responded_at ON enterprise_app_connection_requests TYPE option<datetime>;

DEFINE TABLE enterprise_app_owner_scopes SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_app_owner_scopes TYPE record<tenants>;
DEFINE FIELD app_id ON enterprise_app_owner_scopes TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD owner_person_id ON enterprise_app_owner_scopes TYPE record<identity_persons>;
DEFINE FIELD owner_role ON enterprise_app_owner_scopes TYPE string DEFAULT 'app_owner';
DEFINE FIELD allowed_capabilities ON enterprise_app_owner_scopes TYPE array<string> DEFAULT [];
DEFINE FIELD status ON enterprise_app_owner_scopes TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_app_owner_scopes TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_app_owner_scope_unique ON enterprise_app_owner_scopes FIELDS tenant_id, app_id, owner_person_id UNIQUE;

DEFINE TABLE enterprise_app_license_assignments SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_app_license_assignments TYPE record<tenants>;
DEFINE FIELD app_id ON enterprise_app_license_assignments TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD person_id ON enterprise_app_license_assignments TYPE record<identity_persons>;
DEFINE FIELD license_sku ON enterprise_app_license_assignments TYPE option<string>;
DEFINE FIELD assignment_status ON enterprise_app_license_assignments TYPE string DEFAULT 'assigned';
DEFINE FIELD source_system ON enterprise_app_license_assignments TYPE string;
DEFINE FIELD managed_by_person_id ON enterprise_app_license_assignments TYPE option<record<identity_persons>>;
DEFINE FIELD assigned_at ON enterprise_app_license_assignments TYPE datetime DEFAULT time::now();
DEFINE FIELD revoked_at ON enterprise_app_license_assignments TYPE option<datetime>;

DEFINE TABLE enterprise_app_role_assignments SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_app_role_assignments TYPE record<tenants>;
DEFINE FIELD app_id ON enterprise_app_role_assignments TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD person_id ON enterprise_app_role_assignments TYPE record<identity_persons>;
DEFINE FIELD role_key ON enterprise_app_role_assignments TYPE string;
DEFINE FIELD assignment_status ON enterprise_app_role_assignments TYPE string DEFAULT 'assigned';
DEFINE FIELD source_system ON enterprise_app_role_assignments TYPE string;
DEFINE FIELD managed_by_person_id ON enterprise_app_role_assignments TYPE option<record<identity_persons>>;
DEFINE FIELD assigned_at ON enterprise_app_role_assignments TYPE datetime DEFAULT time::now();
DEFINE FIELD revoked_at ON enterprise_app_role_assignments TYPE option<datetime>;

DEFINE TABLE enterprise_lifecycle_automation_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_lifecycle_automation_policies TYPE record<tenants>;
DEFINE FIELD policy_key ON enterprise_lifecycle_automation_policies TYPE string;
DEFINE FIELD policy_name ON enterprise_lifecycle_automation_policies TYPE string;
DEFINE FIELD lifecycle_domain ON enterprise_lifecycle_automation_policies TYPE string;
DEFINE FIELD trigger_kind ON enterprise_lifecycle_automation_policies TYPE string;
DEFINE FIELD applies_to_app_ids ON enterprise_lifecycle_automation_policies TYPE array<record<enterprise_discovered_business_apps>> DEFAULT [];
DEFINE FIELD automation_mode ON enterprise_lifecycle_automation_policies TYPE string DEFAULT 'recommend_then_approve';
DEFINE FIELD required_approver_roles ON enterprise_lifecycle_automation_policies TYPE array<string> DEFAULT [];
DEFINE FIELD status ON enterprise_lifecycle_automation_policies TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_lifecycle_automation_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_lifecycle_automation_policy_unique ON enterprise_lifecycle_automation_policies FIELDS tenant_id, policy_key UNIQUE;

DEFINE TABLE enterprise_agent_app_lifecycle_links SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_agent_app_lifecycle_links TYPE record<tenants>;
DEFINE FIELD app_id ON enterprise_agent_app_lifecycle_links TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD agent_ref ON enterprise_agent_app_lifecycle_links TYPE string;
DEFINE FIELD lifecycle_status ON enterprise_agent_app_lifecycle_links TYPE string DEFAULT 'evaluating';
DEFINE FIELD owning_app_owner_person_id ON enterprise_agent_app_lifecycle_links TYPE option<record<identity_persons>>;
DEFINE FIELD permissions_source ON enterprise_agent_app_lifecycle_links TYPE string DEFAULT 'existing_stack';
DEFINE FIELD role_bindings ON enterprise_agent_app_lifecycle_links TYPE array<object> DEFAULT [];
DEFINE FIELD created_at ON enterprise_agent_app_lifecycle_links TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_agent_app_lifecycle_links TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::register_enterprise_identity_platform_connector($tenant_id: record<tenants>, $connector_key: string, $platform_kind: string, $provider_name: string, $capabilities: array<string>) {
  RETURN UPSERT type::thing('enterprise_identity_platform_connectors', $connector_key) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    platform_kind: $platform_kind,
    provider_name: $provider_name,
    capabilities: $capabilities,
    connection_status: 'active',
    sync_status: 'ready',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::record_discovered_business_app($tenant_id: record<tenants>, $source_connector_id: record<enterprise_identity_platform_connectors>, $app_key: string, $app_name: string, $app_category: option<string>, $source_system_app_id: option<string>, $owner_emails: array<string>, $user_count: int, $license_count: int) {
  RETURN UPSERT type::thing('enterprise_discovered_business_apps', $app_key) CONTENT {
    tenant_id: $tenant_id,
    source_connector_id: $source_connector_id,
    app_key: $app_key,
    app_name: $app_name,
    app_category: $app_category,
    source_system_app_id: $source_system_app_id,
    app_owner_emails: $owner_emails,
    user_count: $user_count,
    license_count: $license_count,
    integration_status: 'discovered',
    lifecycle_status: 'active',
    discovered_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::request_business_app_connection($tenant_id: record<tenants>, $app_id: record<enterprise_discovered_business_apps>, $requested_by_person_id: option<record<identity_persons>>, $requested_owner_person_id: option<record<identity_persons>>, $requested_owner_email: option<string>, $request_reason: string, $requested_capabilities: array<string>) {
  RETURN CREATE enterprise_app_connection_requests CONTENT {
    tenant_id: $tenant_id,
    app_id: $app_id,
    requested_by_person_id: $requested_by_person_id,
    requested_owner_person_id: $requested_owner_person_id,
    requested_owner_email: $requested_owner_email,
    request_reason: $request_reason,
    requested_capabilities: $requested_capabilities,
    request_status: 'pending_owner_action',
    sent_at: time::now()
  };
};

DEFINE FUNCTION fn::grant_app_owner_scope($tenant_id: record<tenants>, $app_id: record<enterprise_discovered_business_apps>, $owner_person_id: record<identity_persons>, $allowed_capabilities: array<string>) {
  UPDATE $app_id SET integration_status = 'owner_connected', updated_at = time::now();
  RETURN CREATE enterprise_app_owner_scopes CONTENT {
    tenant_id: $tenant_id,
    app_id: $app_id,
    owner_person_id: $owner_person_id,
    owner_role: 'app_owner',
    allowed_capabilities: $allowed_capabilities,
    status: 'active',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::enterprise_app_integration_context($tenant_id: record<tenants>) {
  RETURN {
    connectors: SELECT * FROM enterprise_identity_platform_connectors WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    apps: SELECT * FROM enterprise_discovered_business_apps WHERE tenant_id = $tenant_id ORDER BY app_name,
    connection_requests: SELECT * FROM enterprise_app_connection_requests WHERE tenant_id = $tenant_id ORDER BY sent_at DESC,
    owner_scopes: SELECT * FROM enterprise_app_owner_scopes WHERE tenant_id = $tenant_id AND status = 'active',
    lifecycle_policies: SELECT * FROM enterprise_lifecycle_automation_policies WHERE tenant_id = $tenant_id AND status = 'active',
    agent_links: SELECT * FROM enterprise_agent_app_lifecycle_links WHERE tenant_id = $tenant_id ORDER BY updated_at DESC
  };
};
