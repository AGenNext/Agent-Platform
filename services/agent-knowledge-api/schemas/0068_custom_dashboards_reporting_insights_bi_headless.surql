-- AGenNext Platform
-- 0068: Custom dashboards, reporting, insights, and headless BI integrations
-- Purpose: support tenant-specific dashboards, report definitions, insight generation, KPI catalogs, scheduled reporting, embedded/headless BI integrations, and governed analytics over platform + external enterprise data.

DEFINE TABLE analytics_metric_catalog SCHEMAFULL;
DEFINE FIELD tenant_id ON analytics_metric_catalog TYPE option<record<tenants>>;
DEFINE FIELD metric_key ON analytics_metric_catalog TYPE string;
DEFINE FIELD metric_name ON analytics_metric_catalog TYPE string;
DEFINE FIELD metric_domain ON analytics_metric_catalog TYPE string;
DEFINE FIELD metric_description ON analytics_metric_catalog TYPE option<string>;
DEFINE FIELD source_refs ON analytics_metric_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD calculation_definition ON analytics_metric_catalog TYPE object DEFAULT {};
DEFINE FIELD owner_role ON analytics_metric_catalog TYPE string DEFAULT 'analytics_owner';
DEFINE FIELD governance_status ON analytics_metric_catalog TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON analytics_metric_catalog TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON analytics_metric_catalog TYPE datetime DEFAULT time::now();
DEFINE INDEX analytics_metric_catalog_unique ON analytics_metric_catalog FIELDS tenant_id, metric_key UNIQUE;

DEFINE TABLE custom_dashboard_definitions SCHEMAFULL;
DEFINE FIELD tenant_id ON custom_dashboard_definitions TYPE record<tenants>;
DEFINE FIELD dashboard_key ON custom_dashboard_definitions TYPE string;
DEFINE FIELD dashboard_name ON custom_dashboard_definitions TYPE string;
DEFINE FIELD dashboard_domain ON custom_dashboard_definitions TYPE string;
DEFINE FIELD target_personas ON custom_dashboard_definitions TYPE array<string> DEFAULT [];
DEFINE FIELD visibility_scope ON custom_dashboard_definitions TYPE string DEFAULT 'tenant';
DEFINE FIELD layout_definition ON custom_dashboard_definitions TYPE object DEFAULT {};
DEFINE FIELD filter_definition ON custom_dashboard_definitions TYPE object DEFAULT {};
DEFINE FIELD owner_person_id ON custom_dashboard_definitions TYPE option<record<identity_persons>>;
DEFINE FIELD owner_role ON custom_dashboard_definitions TYPE string DEFAULT 'dashboard_owner';
DEFINE FIELD status ON custom_dashboard_definitions TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON custom_dashboard_definitions TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON custom_dashboard_definitions TYPE datetime DEFAULT time::now();
DEFINE INDEX custom_dashboard_definition_unique ON custom_dashboard_definitions FIELDS tenant_id, dashboard_key UNIQUE;

DEFINE TABLE dashboard_widgets SCHEMAFULL;
DEFINE FIELD tenant_id ON dashboard_widgets TYPE record<tenants>;
DEFINE FIELD dashboard_id ON dashboard_widgets TYPE record<custom_dashboard_definitions>;
DEFINE FIELD widget_key ON dashboard_widgets TYPE string;
DEFINE FIELD widget_title ON dashboard_widgets TYPE string;
DEFINE FIELD widget_kind ON dashboard_widgets TYPE string;
DEFINE FIELD metric_keys ON dashboard_widgets TYPE array<string> DEFAULT [];
DEFINE FIELD query_definition ON dashboard_widgets TYPE object DEFAULT {};
DEFINE FIELD visualization_config ON dashboard_widgets TYPE object DEFAULT {};
DEFINE FIELD drilldown_config ON dashboard_widgets TYPE object DEFAULT {};
DEFINE FIELD rbac_visibility_roles ON dashboard_widgets TYPE array<string> DEFAULT [];
DEFINE FIELD status ON dashboard_widgets TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON dashboard_widgets TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON dashboard_widgets TYPE datetime DEFAULT time::now();
DEFINE INDEX dashboard_widget_unique ON dashboard_widgets FIELDS dashboard_id, widget_key UNIQUE;

DEFINE TABLE report_definitions SCHEMAFULL;
DEFINE FIELD tenant_id ON report_definitions TYPE record<tenants>;
DEFINE FIELD report_key ON report_definitions TYPE string;
DEFINE FIELD report_name ON report_definitions TYPE string;
DEFINE FIELD report_domain ON report_definitions TYPE string;
DEFINE FIELD report_kind ON report_definitions TYPE string DEFAULT 'operational';
DEFINE FIELD sections ON report_definitions TYPE array<object> DEFAULT [];
DEFINE FIELD data_sources ON report_definitions TYPE array<string> DEFAULT [];
DEFINE FIELD output_formats ON report_definitions TYPE array<string> DEFAULT ['html','pdf','xlsx'];
DEFINE FIELD schedule_policy ON report_definitions TYPE object DEFAULT {};
DEFINE FIELD recipient_roles ON report_definitions TYPE array<string> DEFAULT [];
DEFINE FIELD status ON report_definitions TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON report_definitions TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON report_definitions TYPE datetime DEFAULT time::now();
DEFINE INDEX report_definition_unique ON report_definitions FIELDS tenant_id, report_key UNIQUE;

DEFINE TABLE report_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON report_runs TYPE record<tenants>;
DEFINE FIELD report_id ON report_runs TYPE record<report_definitions>;
DEFINE FIELD run_ref ON report_runs TYPE string;
DEFINE FIELD run_kind ON report_runs TYPE string DEFAULT 'manual';
DEFINE FIELD run_status ON report_runs TYPE string DEFAULT 'queued';
DEFINE FIELD generated_assets ON report_runs TYPE array<object> DEFAULT [];
DEFINE FIELD generated_by_person_id ON report_runs TYPE option<record<identity_persons>>;
DEFINE FIELD started_at ON report_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON report_runs TYPE option<datetime>;
DEFINE INDEX report_run_ref_unique ON report_runs FIELDS run_ref UNIQUE;

DEFINE TABLE insight_definitions SCHEMAFULL;
DEFINE FIELD tenant_id ON insight_definitions TYPE record<tenants>;
DEFINE FIELD insight_key ON insight_definitions TYPE string;
DEFINE FIELD insight_name ON insight_definitions TYPE string;
DEFINE FIELD insight_domain ON insight_definitions TYPE string;
DEFINE FIELD trigger_policy ON insight_definitions TYPE object DEFAULT {};
DEFINE FIELD evaluation_query ON insight_definitions TYPE object DEFAULT {};
DEFINE FIELD severity_policy ON insight_definitions TYPE object DEFAULT {};
DEFINE FIELD recommended_action_policy ON insight_definitions TYPE object DEFAULT {};
DEFINE FIELD owner_role ON insight_definitions TYPE string DEFAULT 'insight_owner';
DEFINE FIELD status ON insight_definitions TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON insight_definitions TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON insight_definitions TYPE datetime DEFAULT time::now();
DEFINE INDEX insight_definition_unique ON insight_definitions FIELDS tenant_id, insight_key UNIQUE;

DEFINE TABLE generated_insights SCHEMAFULL;
DEFINE FIELD tenant_id ON generated_insights TYPE record<tenants>;
DEFINE FIELD insight_definition_id ON generated_insights TYPE option<record<insight_definitions>>;
DEFINE FIELD insight_ref ON generated_insights TYPE string;
DEFINE FIELD insight_title ON generated_insights TYPE string;
DEFINE FIELD insight_summary ON generated_insights TYPE string;
DEFINE FIELD insight_domain ON generated_insights TYPE string;
DEFINE FIELD severity ON generated_insights TYPE string DEFAULT 'info';
DEFINE FIELD supporting_evidence_refs ON generated_insights TYPE array<string> DEFAULT [];
DEFINE FIELD recommended_actions ON generated_insights TYPE array<object> DEFAULT [];
DEFINE FIELD related_decision_id ON generated_insights TYPE option<record<enterprise_decision_logs>>;
DEFINE FIELD status ON generated_insights TYPE string DEFAULT 'open';
DEFINE FIELD created_at ON generated_insights TYPE datetime DEFAULT time::now();
DEFINE FIELD resolved_at ON generated_insights TYPE option<datetime>;
DEFINE INDEX generated_insight_ref_unique ON generated_insights FIELDS insight_ref UNIQUE;

DEFINE TABLE headless_bi_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON headless_bi_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON headless_bi_connectors TYPE string;
DEFINE FIELD provider_name ON headless_bi_connectors TYPE string;
DEFINE FIELD provider_kind ON headless_bi_connectors TYPE string DEFAULT 'bi';
DEFINE FIELD capabilities ON headless_bi_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON headless_bi_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD embedding_mode ON headless_bi_connectors TYPE string DEFAULT 'headless_api';
DEFINE FIELD source_of_record_policy ON headless_bi_connectors TYPE string DEFAULT 'external_bi_remains_source_of_record';
DEFINE FIELD connection_status ON headless_bi_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD governance_status ON headless_bi_connectors TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON headless_bi_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON headless_bi_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX headless_bi_connector_unique ON headless_bi_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE bi_asset_mappings SCHEMAFULL;
DEFINE FIELD tenant_id ON bi_asset_mappings TYPE record<tenants>;
DEFINE FIELD connector_id ON bi_asset_mappings TYPE record<headless_bi_connectors>;
DEFINE FIELD external_asset_ref ON bi_asset_mappings TYPE string;
DEFINE FIELD external_asset_kind ON bi_asset_mappings TYPE string;
DEFINE FIELD platform_dashboard_id ON bi_asset_mappings TYPE option<record<custom_dashboard_definitions>>;
DEFINE FIELD platform_report_id ON bi_asset_mappings TYPE option<record<report_definitions>>;
DEFINE FIELD sync_direction ON bi_asset_mappings TYPE string DEFAULT 'read_from_bi';
DEFINE FIELD owner_role ON bi_asset_mappings TYPE string DEFAULT 'analytics_owner';
DEFINE FIELD status ON bi_asset_mappings TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON bi_asset_mappings TYPE datetime DEFAULT time::now();
DEFINE INDEX bi_asset_mapping_unique ON bi_asset_mappings FIELDS tenant_id, connector_id, external_asset_ref UNIQUE;

DEFINE FUNCTION fn::create_custom_dashboard($tenant_id: record<tenants>, $dashboard_key: string, $dashboard_name: string, $dashboard_domain: string, $target_personas: array<string>, $layout_definition: object, $owner_person_id: option<record<identity_persons>>, $owner_role: string) {
  RETURN UPSERT type::thing('custom_dashboard_definitions', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $dashboard_key)) CONTENT {
    tenant_id: $tenant_id,
    dashboard_key: $dashboard_key,
    dashboard_name: $dashboard_name,
    dashboard_domain: $dashboard_domain,
    target_personas: $target_personas,
    visibility_scope: 'tenant',
    layout_definition: $layout_definition,
    filter_definition: {},
    owner_person_id: $owner_person_id,
    owner_role: $owner_role,
    status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::add_dashboard_widget($tenant_id: record<tenants>, $dashboard_id: record<custom_dashboard_definitions>, $widget_key: string, $widget_title: string, $widget_kind: string, $metric_keys: array<string>, $query_definition: object, $visualization_config: object, $rbac_visibility_roles: array<string>) {
  RETURN CREATE dashboard_widgets CONTENT {
    tenant_id: $tenant_id,
    dashboard_id: $dashboard_id,
    widget_key: $widget_key,
    widget_title: $widget_title,
    widget_kind: $widget_kind,
    metric_keys: $metric_keys,
    query_definition: $query_definition,
    visualization_config: $visualization_config,
    drilldown_config: {},
    rbac_visibility_roles: $rbac_visibility_roles,
    status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::register_headless_bi_connector($tenant_id: record<tenants>, $connector_key: string, $provider_name: string, $capabilities: array<string>, $supported_auth_modes: array<string>) {
  RETURN UPSERT type::thing('headless_bi_connectors', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    provider_name: $provider_name,
    provider_kind: 'bi',
    capabilities: $capabilities,
    supported_auth_modes: $supported_auth_modes,
    embedding_mode: 'headless_api',
    source_of_record_policy: 'external_bi_remains_source_of_record',
    connection_status: 'connected',
    governance_status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::record_generated_insight($tenant_id: record<tenants>, $insight_definition_id: option<record<insight_definitions>>, $insight_title: string, $insight_summary: string, $insight_domain: string, $severity: string, $supporting_evidence_refs: array<string>, $recommended_actions: array<object>, $related_decision_id: option<record<enterprise_decision_logs>>) {
  RETURN CREATE generated_insights CONTENT {
    tenant_id: $tenant_id,
    insight_definition_id: $insight_definition_id,
    insight_ref: rand::uuid(),
    insight_title: $insight_title,
    insight_summary: $insight_summary,
    insight_domain: $insight_domain,
    severity: $severity,
    supporting_evidence_refs: $supporting_evidence_refs,
    recommended_actions: $recommended_actions,
    related_decision_id: $related_decision_id,
    status: 'open',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::analytics_reporting_context($tenant_id: record<tenants>) {
  RETURN {
    metrics: SELECT * FROM analytics_metric_catalog WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY metric_domain, metric_name,
    dashboards: SELECT * FROM custom_dashboard_definitions WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    widgets: SELECT * FROM dashboard_widgets WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    reports: SELECT * FROM report_definitions WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    report_runs: SELECT * FROM report_runs WHERE tenant_id = $tenant_id ORDER BY started_at DESC LIMIT 50,
    insights: SELECT * FROM generated_insights WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    insight_definitions: SELECT * FROM insight_definitions WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    bi_connectors: SELECT * FROM headless_bi_connectors WHERE tenant_id = $tenant_id ORDER BY provider_name,
    bi_asset_mappings: SELECT * FROM bi_asset_mappings WHERE tenant_id = $tenant_id ORDER BY created_at DESC
  };
};

-- Built-in headless BI connector templates.
CREATE headless_bi_connectors:powerbi_template CONTENT { connector_key: 'powerbi', provider_name: 'Microsoft Power BI', provider_kind: 'bi', capabilities: ['dataset_read','report_embed','semantic_model_query','dashboard_inventory','rbac_sync'], supported_auth_modes: ['service_principal','oauth','managed_identity'], embedding_mode: 'headless_api', source_of_record_policy: 'external_bi_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE headless_bi_connectors:tableau_template CONTENT { connector_key: 'tableau', provider_name: 'Tableau', provider_kind: 'bi', capabilities: ['workbook_inventory','view_embed','metadata_api','extract_refresh_context','rbac_sync'], supported_auth_modes: ['personal_access_token','oauth','connected_app'], embedding_mode: 'headless_api', source_of_record_policy: 'external_bi_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE headless_bi_connectors:looker_template CONTENT { connector_key: 'looker', provider_name: 'Looker', provider_kind: 'bi', capabilities: ['semantic_model_query','dashboard_embed','look_inventory','explore_query','rbac_sync'], supported_auth_modes: ['api_client','oauth'], embedding_mode: 'headless_api', source_of_record_policy: 'external_bi_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE headless_bi_connectors:superset_template CONTENT { connector_key: 'superset', provider_name: 'Apache Superset', provider_kind: 'bi', capabilities: ['dashboard_inventory','chart_embed','sql_lab_context','dataset_read'], supported_auth_modes: ['oauth','service_account','jwt'], embedding_mode: 'headless_api', source_of_record_policy: 'external_bi_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE headless_bi_connectors:metabase_template CONTENT { connector_key: 'metabase', provider_name: 'Metabase', provider_kind: 'bi', capabilities: ['question_inventory','dashboard_embed','dataset_query','collection_context'], supported_auth_modes: ['api_key','jwt','oauth'], embedding_mode: 'headless_api', source_of_record_policy: 'external_bi_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE headless_bi_connectors:thoughtspot_template CONTENT { connector_key: 'thoughtspot', provider_name: 'ThoughtSpot', provider_kind: 'bi', capabilities: ['liveboard_embed','search_query','answer_context','semantic_query'], supported_auth_modes: ['trusted_auth','oauth','api_token'], embedding_mode: 'headless_api', source_of_record_policy: 'external_bi_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
