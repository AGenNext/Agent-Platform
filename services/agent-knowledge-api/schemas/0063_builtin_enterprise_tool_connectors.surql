-- AGenNext Platform
-- 0063: Built-in enterprise tool connectors
-- Purpose: register first-class tool connector categories for web search, RAG, storage, DXP, metadata, PIM, commerce, CRM, cloud, DevOps, containers, OpenShift, and serverless while preserving existing enterprise systems as source of record.

DEFINE TABLE builtin_tool_connector_catalog SCHEMAFULL;
DEFINE FIELD connector_key ON builtin_tool_connector_catalog TYPE string;
DEFINE FIELD display_name ON builtin_tool_connector_catalog TYPE string;
DEFINE FIELD connector_category ON builtin_tool_connector_catalog TYPE string;
DEFINE FIELD provider_family ON builtin_tool_connector_catalog TYPE string;
DEFINE FIELD supported_capabilities ON builtin_tool_connector_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON builtin_tool_connector_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD default_execution_mode ON builtin_tool_connector_catalog TYPE string DEFAULT 'read_first_recommend_then_approve_execute';
DEFINE FIELD source_of_record_policy ON builtin_tool_connector_catalog TYPE string DEFAULT 'external_system_remains_source_of_record';
DEFINE FIELD requires_owner_approval ON builtin_tool_connector_catalog TYPE bool DEFAULT true;
DEFINE FIELD requires_human_confirmation_for_write ON builtin_tool_connector_catalog TYPE bool DEFAULT true;
DEFINE FIELD active ON builtin_tool_connector_catalog TYPE bool DEFAULT true;
DEFINE FIELD created_at ON builtin_tool_connector_catalog TYPE datetime DEFAULT time::now();
DEFINE INDEX builtin_tool_connector_catalog_unique ON builtin_tool_connector_catalog FIELDS connector_key UNIQUE;

DEFINE TABLE tenant_tool_connector_instances SCHEMAFULL;
DEFINE FIELD tenant_id ON tenant_tool_connector_instances TYPE record<tenants>;
DEFINE FIELD connector_key ON tenant_tool_connector_instances TYPE string;
DEFINE FIELD app_id ON tenant_tool_connector_instances TYPE option<record<enterprise_discovered_business_apps>>;
DEFINE FIELD connected_by_person_id ON tenant_tool_connector_instances TYPE option<record<identity_persons>>;
DEFINE FIELD connection_status ON tenant_tool_connector_instances TYPE string DEFAULT 'pending';
DEFINE FIELD enabled_capabilities ON tenant_tool_connector_instances TYPE array<string> DEFAULT [];
DEFINE FIELD environment_scope ON tenant_tool_connector_instances TYPE string DEFAULT 'enterprise';
DEFINE FIELD data_access_scope ON tenant_tool_connector_instances TYPE object DEFAULT {};
DEFINE FIELD governance_status ON tenant_tool_connector_instances TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON tenant_tool_connector_instances TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON tenant_tool_connector_instances TYPE datetime DEFAULT time::now();
DEFINE INDEX tenant_tool_connector_instance_unique ON tenant_tool_connector_instances FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE tenant_tool_capability_grants SCHEMAFULL;
DEFINE FIELD tenant_id ON tenant_tool_capability_grants TYPE record<tenants>;
DEFINE FIELD connector_instance_id ON tenant_tool_capability_grants TYPE record<tenant_tool_connector_instances>;
DEFINE FIELD capability_key ON tenant_tool_capability_grants TYPE string;
DEFINE FIELD granted_to_role ON tenant_tool_capability_grants TYPE string;
DEFINE FIELD grant_scope ON tenant_tool_capability_grants TYPE object DEFAULT {};
DEFINE FIELD approval_required ON tenant_tool_capability_grants TYPE bool DEFAULT true;
DEFINE FIELD status ON tenant_tool_capability_grants TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON tenant_tool_capability_grants TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::install_builtin_tool_connector($tenant_id: record<tenants>, $connector_key: string, $app_id: option<record<enterprise_discovered_business_apps>>, $connected_by_person_id: option<record<identity_persons>>, $enabled_capabilities: array<string>, $data_access_scope: object) {
  LET $catalog = SELECT * FROM ONLY builtin_tool_connector_catalog WHERE connector_key = $connector_key AND active = true LIMIT 1;
  IF $catalog = NONE THEN { THROW 'builtin_tool_connector_not_found'; };
  RETURN UPSERT type::thing('tenant_tool_connector_instances', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    app_id: $app_id,
    connected_by_person_id: $connected_by_person_id,
    connection_status: 'connected',
    enabled_capabilities: $enabled_capabilities,
    environment_scope: 'enterprise',
    data_access_scope: $data_access_scope,
    governance_status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::builtin_tool_connector_context($tenant_id: record<tenants>) {
  RETURN {
    catalog: SELECT * FROM builtin_tool_connector_catalog WHERE active = true ORDER BY connector_category, display_name,
    installed: SELECT * FROM tenant_tool_connector_instances WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    grants: SELECT * FROM tenant_tool_capability_grants WHERE tenant_id = $tenant_id AND status = 'active'
  };
};

CREATE builtin_tool_connector_catalog:web_search CONTENT { connector_key: 'web_search', display_name: 'Web Search', connector_category: 'research', provider_family: 'web', supported_capabilities: ['search_web', 'fetch_page', 'summarize_sources', 'source_citation'], supported_auth_modes: ['managed'], default_execution_mode: 'read_only', source_of_record_policy: 'web_sources_cited', requires_owner_approval: false, requires_human_confirmation_for_write: false, active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:rag_anything CONTENT { connector_key: 'rag_anything', display_name: 'RAG Anything', connector_category: 'knowledge', provider_family: 'multimodal_graph_rag', supported_capabilities: ['document_rag', 'graph_rag', 'multimodal_rag', 'semantic_search', 'entity_extraction', 'evidence_grounding'], supported_auth_modes: ['tenant_managed', 'service_account'], default_execution_mode: 'read_first_recommend_then_approve_execute', source_of_record_policy: 'retrieval_index_not_source_of_record', requires_owner_approval: true, requires_human_confirmation_for_write: true, active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:cloud_storage CONTENT { connector_key: 'cloud_storage', display_name: 'Cloud Storage', connector_category: 'storage', provider_family: 's3_gcs_azure_blob_r2', supported_capabilities: ['read_object', 'write_object', 'list_bucket', 'metadata_extract', 'retention_policy'], supported_auth_modes: ['iam_role', 'service_account', 'oauth'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:liferay_dxp CONTENT { connector_key: 'liferay_dxp', display_name: 'Liferay DXP', connector_category: 'digital_experience_platform', provider_family: 'liferay', supported_capabilities: ['read_content', 'draft_content', 'publish_content_after_approval', 'manage_pages', 'metadata_sync'], supported_auth_modes: ['oauth', 'service_account'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:openmetadata CONTENT { connector_key: 'openmetadata', display_name: 'OpenMetadata', connector_category: 'metadata_management', provider_family: 'openmetadata', supported_capabilities: ['read_catalog', 'lineage_lookup', 'glossary_lookup', 'classification_lookup', 'data_product_context'], supported_auth_modes: ['jwt', 'service_account'], default_execution_mode: 'read_only', active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:pim CONTENT { connector_key: 'pim', display_name: 'Product Information Management', connector_category: 'pim', provider_family: 'akeneo_salsify_inriver_pimcore', supported_capabilities: ['read_product_data', 'draft_product_updates', 'taxonomy_mapping', 'attribute_enrichment', 'approval_based_writeback'], supported_auth_modes: ['oauth', 'api_key', 'service_account'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:commercetools CONTENT { connector_key: 'commercetools', display_name: 'commercetools', connector_category: 'commerce', provider_family: 'commercetools', supported_capabilities: ['read_catalog', 'read_orders', 'draft_product_changes', 'promotion_analysis', 'approval_based_writeback'], supported_auth_modes: ['oauth_client_credentials'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:adobe_commerce CONTENT { connector_key: 'adobe_commerce', display_name: 'Adobe Commerce', connector_category: 'commerce', provider_family: 'adobe_commerce_magento', supported_capabilities: ['read_catalog', 'read_orders', 'draft_product_changes', 'content_sync', 'approval_based_writeback'], supported_auth_modes: ['oauth', 'api_token'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:salesforce CONTENT { connector_key: 'salesforce', display_name: 'Salesforce', connector_category: 'crm', provider_family: 'salesforce', supported_capabilities: ['read_accounts', 'read_opportunities', 'draft_updates', 'case_context', 'approval_based_writeback'], supported_auth_modes: ['oauth', 'connected_app'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:cloud_infra CONTENT { connector_key: 'cloud_infra', display_name: 'Cloud Infrastructure', connector_category: 'cloud', provider_family: 'aws_azure_gcp_oracle_ibm', supported_capabilities: ['inventory_read', 'cost_read', 'policy_read', 'deployment_plan', 'approval_based_provisioning'], supported_auth_modes: ['iam_role', 'workload_identity', 'service_principal'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:github CONTENT { connector_key: 'github', display_name: 'GitHub', connector_category: 'devops', provider_family: 'github', supported_capabilities: ['read_repos', 'read_prs', 'create_branch', 'draft_pr', 'code_search', 'ci_status'], supported_auth_modes: ['github_app', 'oauth'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:docker CONTENT { connector_key: 'docker', display_name: 'Docker', connector_category: 'containers', provider_family: 'docker', supported_capabilities: ['image_metadata', 'build_context', 'registry_lookup', 'sbom_lookup', 'deploy_plan'], supported_auth_modes: ['registry_token', 'service_account'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:openshift CONTENT { connector_key: 'openshift', display_name: 'OpenShift', connector_category: 'platform_runtime', provider_family: 'red_hat_openshift', supported_capabilities: ['cluster_inventory', 'deployment_status', 'route_lookup', 'operator_context', 'approval_based_deploy'], supported_auth_modes: ['service_account', 'oauth'], active: true, created_at: time::now() };
CREATE builtin_tool_connector_catalog:aws_serverless CONTENT { connector_key: 'aws_serverless', display_name: 'AWS Serverless', connector_category: 'serverless', provider_family: 'aws_lambda_eventbridge_stepfunctions_apigw', supported_capabilities: ['read_functions', 'read_events', 'deployment_plan', 'log_lookup', 'approval_based_deploy'], supported_auth_modes: ['iam_role', 'oidc'], active: true, created_at: time::now() };
