-- AGenNext Platform
-- 0066: SIEM, data lake, distributed big data, and enterprise object storage integrations
-- Purpose: add governed native integration foundations for SIEM tools, data lakes/lakehouses, distributed big data platforms, and enterprise object storage while preserving source-of-record and security ownership.

DEFINE TABLE enterprise_security_data_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_security_data_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON enterprise_security_data_connectors TYPE string;
DEFINE FIELD connector_kind ON enterprise_security_data_connectors TYPE string;
DEFINE FIELD provider_name ON enterprise_security_data_connectors TYPE string;
DEFINE FIELD deployment_model ON enterprise_security_data_connectors TYPE string DEFAULT 'customer_managed';
DEFINE FIELD capabilities ON enterprise_security_data_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON enterprise_security_data_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD data_sensitivity ON enterprise_security_data_connectors TYPE string DEFAULT 'high';
DEFINE FIELD source_of_record_policy ON enterprise_security_data_connectors TYPE string DEFAULT 'external_system_remains_source_of_record';
DEFINE FIELD connection_status ON enterprise_security_data_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD governance_status ON enterprise_security_data_connectors TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON enterprise_security_data_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_security_data_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_security_data_connector_unique ON enterprise_security_data_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE security_event_ingestion_flows SCHEMAFULL;
DEFINE FIELD tenant_id ON security_event_ingestion_flows TYPE record<tenants>;
DEFINE FIELD connector_id ON security_event_ingestion_flows TYPE record<enterprise_security_data_connectors>;
DEFINE FIELD flow_key ON security_event_ingestion_flows TYPE string;
DEFINE FIELD flow_name ON security_event_ingestion_flows TYPE string;
DEFINE FIELD event_domains ON security_event_ingestion_flows TYPE array<string> DEFAULT [];
DEFINE FIELD ingestion_mode ON security_event_ingestion_flows TYPE string DEFAULT 'read_only_stream_or_batch';
DEFINE FIELD normalization_profile ON security_event_ingestion_flows TYPE string DEFAULT 'ecs_or_ocsf_compatible';
DEFINE FIELD retention_policy_ref ON security_event_ingestion_flows TYPE option<string>;
DEFINE FIELD pii_handling_policy ON security_event_ingestion_flows TYPE string DEFAULT 'minimize_and_mask';
DEFINE FIELD approval_required_for_queries ON security_event_ingestion_flows TYPE bool DEFAULT true;
DEFINE FIELD status ON security_event_ingestion_flows TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON security_event_ingestion_flows TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON security_event_ingestion_flows TYPE datetime DEFAULT time::now();
DEFINE INDEX security_event_ingestion_flow_unique ON security_event_ingestion_flows FIELDS tenant_id, flow_key UNIQUE;

DEFINE TABLE data_lake_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON data_lake_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON data_lake_connectors TYPE string;
DEFINE FIELD provider_name ON data_lake_connectors TYPE string;
DEFINE FIELD lake_kind ON data_lake_connectors TYPE string;
DEFINE FIELD catalog_integration ON data_lake_connectors TYPE option<string>;
DEFINE FIELD supported_table_formats ON data_lake_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_query_engines ON data_lake_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON data_lake_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD source_of_record_policy ON data_lake_connectors TYPE string DEFAULT 'external_lake_remains_source_of_record';
DEFINE FIELD connection_status ON data_lake_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD governance_status ON data_lake_connectors TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON data_lake_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON data_lake_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX data_lake_connector_unique ON data_lake_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE bigdata_platform_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON bigdata_platform_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON bigdata_platform_connectors TYPE string;
DEFINE FIELD provider_name ON bigdata_platform_connectors TYPE string;
DEFINE FIELD platform_kind ON bigdata_platform_connectors TYPE string;
DEFINE FIELD capabilities ON bigdata_platform_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON bigdata_platform_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD workload_modes ON bigdata_platform_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD source_of_record_policy ON bigdata_platform_connectors TYPE string DEFAULT 'external_platform_remains_source_of_record';
DEFINE FIELD connection_status ON bigdata_platform_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD governance_status ON bigdata_platform_connectors TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON bigdata_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON bigdata_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX bigdata_platform_connector_unique ON bigdata_platform_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE enterprise_object_storage_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_object_storage_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON enterprise_object_storage_connectors TYPE string;
DEFINE FIELD provider_name ON enterprise_object_storage_connectors TYPE string;
DEFINE FIELD storage_kind ON enterprise_object_storage_connectors TYPE string;
DEFINE FIELD endpoint_ref ON enterprise_object_storage_connectors TYPE option<string>;
DEFINE FIELD capabilities ON enterprise_object_storage_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON enterprise_object_storage_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD encryption_policy ON enterprise_object_storage_connectors TYPE string DEFAULT 'customer_managed_or_provider_managed';
DEFINE FIELD retention_policy_ref ON enterprise_object_storage_connectors TYPE option<string>;
DEFINE FIELD source_of_record_policy ON enterprise_object_storage_connectors TYPE string DEFAULT 'external_storage_remains_source_of_record';
DEFINE FIELD connection_status ON enterprise_object_storage_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD governance_status ON enterprise_object_storage_connectors TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON enterprise_object_storage_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_object_storage_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_object_storage_connector_unique ON enterprise_object_storage_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE governed_data_access_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON governed_data_access_requests TYPE record<tenants>;
DEFINE FIELD request_ref ON governed_data_access_requests TYPE string;
DEFINE FIELD connector_ref ON governed_data_access_requests TYPE string;
DEFINE FIELD connector_kind ON governed_data_access_requests TYPE string;
DEFINE FIELD requested_by_person_id ON governed_data_access_requests TYPE option<record<identity_persons>>;
DEFINE FIELD access_intent ON governed_data_access_requests TYPE string;
DEFINE FIELD query_or_path_summary ON governed_data_access_requests TYPE string;
DEFINE FIELD data_domains ON governed_data_access_requests TYPE array<string> DEFAULT [];
DEFINE FIELD sensitivity_level ON governed_data_access_requests TYPE string DEFAULT 'internal';
DEFINE FIELD approval_status ON governed_data_access_requests TYPE string DEFAULT 'pending_data_owner_review';
DEFINE FIELD execution_status ON governed_data_access_requests TYPE string DEFAULT 'not_executed';
DEFINE FIELD decision_id ON governed_data_access_requests TYPE option<record<enterprise_decision_logs>>;
DEFINE FIELD evidence_refs ON governed_data_access_requests TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON governed_data_access_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON governed_data_access_requests TYPE option<datetime>;
DEFINE FIELD executed_at ON governed_data_access_requests TYPE option<datetime>;
DEFINE INDEX governed_data_access_request_ref_unique ON governed_data_access_requests FIELDS request_ref UNIQUE;

DEFINE FUNCTION fn::register_enterprise_security_data_connector($tenant_id: record<tenants>, $connector_key: string, $connector_kind: string, $provider_name: string, $capabilities: array<string>, $supported_auth_modes: array<string>) {
  RETURN UPSERT type::thing('enterprise_security_data_connectors', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    connector_kind: $connector_kind,
    provider_name: $provider_name,
    deployment_model: 'customer_managed',
    capabilities: $capabilities,
    supported_auth_modes: $supported_auth_modes,
    data_sensitivity: 'high',
    source_of_record_policy: 'external_system_remains_source_of_record',
    connection_status: 'connected',
    governance_status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::register_data_lake_connector($tenant_id: record<tenants>, $connector_key: string, $provider_name: string, $lake_kind: string, $supported_table_formats: array<string>, $supported_query_engines: array<string>, $supported_auth_modes: array<string>) {
  RETURN UPSERT type::thing('data_lake_connectors', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    provider_name: $provider_name,
    lake_kind: $lake_kind,
    supported_table_formats: $supported_table_formats,
    supported_query_engines: $supported_query_engines,
    supported_auth_modes: $supported_auth_modes,
    source_of_record_policy: 'external_lake_remains_source_of_record',
    connection_status: 'connected',
    governance_status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::register_bigdata_platform_connector($tenant_id: record<tenants>, $connector_key: string, $provider_name: string, $platform_kind: string, $capabilities: array<string>, $supported_auth_modes: array<string>, $workload_modes: array<string>) {
  RETURN UPSERT type::thing('bigdata_platform_connectors', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    provider_name: $provider_name,
    platform_kind: $platform_kind,
    capabilities: $capabilities,
    supported_auth_modes: $supported_auth_modes,
    workload_modes: $workload_modes,
    source_of_record_policy: 'external_platform_remains_source_of_record',
    connection_status: 'connected',
    governance_status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::register_enterprise_object_storage_connector($tenant_id: record<tenants>, $connector_key: string, $provider_name: string, $storage_kind: string, $endpoint_ref: option<string>, $capabilities: array<string>, $supported_auth_modes: array<string>) {
  RETURN UPSERT type::thing('enterprise_object_storage_connectors', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    provider_name: $provider_name,
    storage_kind: $storage_kind,
    endpoint_ref: $endpoint_ref,
    capabilities: $capabilities,
    supported_auth_modes: $supported_auth_modes,
    encryption_policy: 'customer_managed_or_provider_managed',
    source_of_record_policy: 'external_storage_remains_source_of_record',
    connection_status: 'connected',
    governance_status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::request_governed_data_access($tenant_id: record<tenants>, $connector_ref: string, $connector_kind: string, $requested_by_person_id: option<record<identity_persons>>, $access_intent: string, $query_or_path_summary: string, $data_domains: array<string>, $sensitivity_level: string, $decision_id: option<record<enterprise_decision_logs>>, $evidence_refs: array<string>) {
  RETURN CREATE governed_data_access_requests CONTENT {
    tenant_id: $tenant_id,
    request_ref: rand::uuid(),
    connector_ref: $connector_ref,
    connector_kind: $connector_kind,
    requested_by_person_id: $requested_by_person_id,
    access_intent: $access_intent,
    query_or_path_summary: $query_or_path_summary,
    data_domains: $data_domains,
    sensitivity_level: $sensitivity_level,
    approval_status: IF $sensitivity_level IN ['confidential','restricted','regulated'] THEN 'pending_data_owner_review' ELSE 'approved' END,
    execution_status: 'not_executed',
    decision_id: $decision_id,
    evidence_refs: $evidence_refs,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::security_data_lake_context($tenant_id: record<tenants>) {
  RETURN {
    siem_connectors: SELECT * FROM enterprise_security_data_connectors WHERE tenant_id = $tenant_id ORDER BY provider_name,
    security_ingestion_flows: SELECT * FROM security_event_ingestion_flows WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    data_lakes: SELECT * FROM data_lake_connectors WHERE tenant_id = $tenant_id ORDER BY provider_name,
    bigdata_platforms: SELECT * FROM bigdata_platform_connectors WHERE tenant_id = $tenant_id ORDER BY provider_name,
    object_storage: SELECT * FROM enterprise_object_storage_connectors WHERE tenant_id = $tenant_id ORDER BY provider_name,
    access_requests: SELECT * FROM governed_data_access_requests WHERE tenant_id = $tenant_id ORDER BY created_at DESC
  };
};

-- Built-in connector templates for common SIEM, lakehouse, big data, and object storage ecosystems.
CREATE enterprise_security_data_connectors:splunk_template CONTENT { connector_key: 'splunk', connector_kind: 'siem', provider_name: 'Splunk', capabilities: ['search_events','saved_search_context','alert_context','notable_event_context','incident_enrichment'], supported_auth_modes: ['token','oauth','service_account'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_security_data_connectors:microsoft_sentinel_template CONTENT { connector_key: 'microsoft_sentinel', connector_kind: 'siem', provider_name: 'Microsoft Sentinel', capabilities: ['kql_query','incident_context','alert_context','entity_context','automation_rule_context'], supported_auth_modes: ['managed_identity','service_principal','oauth'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_security_data_connectors:elastic_security_template CONTENT { connector_key: 'elastic_security', connector_kind: 'siem', provider_name: 'Elastic Security', capabilities: ['search_events','rule_context','alert_context','case_context'], supported_auth_modes: ['api_key','service_account'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_security_data_connectors:chronicle_secops_template CONTENT { connector_key: 'google_chronicle_secops', connector_kind: 'siem', provider_name: 'Google Chronicle SecOps', capabilities: ['udm_search','case_context','threat_intel_context','detection_context'], supported_auth_modes: ['service_account','workload_identity'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_security_data_connectors:qradar_template CONTENT { connector_key: 'qradar', connector_kind: 'siem', provider_name: 'IBM QRadar', capabilities: ['aql_query','offense_context','event_context','asset_context'], supported_auth_modes: ['api_token','service_account'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };

CREATE data_lake_connectors:databricks_template CONTENT { connector_key: 'databricks', provider_name: 'Databricks Lakehouse', lake_kind: 'lakehouse', supported_table_formats: ['delta'], supported_query_engines: ['databricks_sql','spark'], supported_auth_modes: ['service_principal','pat','oauth'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE data_lake_connectors:snowflake_template CONTENT { connector_key: 'snowflake', provider_name: 'Snowflake', lake_kind: 'warehouse_lakehouse', supported_table_formats: ['iceberg','native_tables'], supported_query_engines: ['snowflake_sql'], supported_auth_modes: ['key_pair','oauth','service_user'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE data_lake_connectors:bigquery_template CONTENT { connector_key: 'bigquery', provider_name: 'Google BigQuery', lake_kind: 'cloud_data_warehouse', supported_table_formats: ['biglake','iceberg','native_tables'], supported_query_engines: ['bigquery_sql'], supported_auth_modes: ['service_account','workload_identity'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE data_lake_connectors:azure_synapse_template CONTENT { connector_key: 'azure_synapse', provider_name: 'Azure Synapse / Fabric', lake_kind: 'cloud_lakehouse', supported_table_formats: ['delta','parquet'], supported_query_engines: ['spark','sql'], supported_auth_modes: ['managed_identity','service_principal'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };

CREATE bigdata_platform_connectors:hadoop_template CONTENT { connector_key: 'hadoop', provider_name: 'Apache Hadoop / HDFS', platform_kind: 'distributed_bigdata', capabilities: ['hdfs_read','hive_query','spark_job_context','yarn_context'], supported_auth_modes: ['kerberos','service_account'], workload_modes: ['batch','analytics'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE bigdata_platform_connectors:emr_template CONTENT { connector_key: 'aws_emr', provider_name: 'Amazon EMR', platform_kind: 'managed_bigdata', capabilities: ['cluster_inventory','spark_context','hive_context','s3_data_context'], supported_auth_modes: ['iam_role','oidc'], workload_modes: ['batch','streaming','analytics'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE bigdata_platform_connectors:confluent_kafka_template CONTENT { connector_key: 'confluent_kafka', provider_name: 'Confluent Kafka', platform_kind: 'event_streaming', capabilities: ['topic_inventory','schema_registry_context','consumer_lag_context','event_flow_context'], supported_auth_modes: ['api_key','oauth','service_account'], workload_modes: ['streaming','event_driven'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };

CREATE enterprise_object_storage_connectors:aws_s3_template CONTENT { connector_key: 'aws_s3', provider_name: 'Amazon S3', storage_kind: 'object_storage', capabilities: ['list_bucket','read_object','write_object_after_approval','metadata_extract','lifecycle_policy_context'], supported_auth_modes: ['iam_role','access_key','oidc'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_object_storage_connectors:azure_blob_template CONTENT { connector_key: 'azure_blob', provider_name: 'Azure Blob Storage / ADLS Gen2', storage_kind: 'object_storage_data_lake', capabilities: ['list_container','read_object','write_object_after_approval','metadata_extract','acl_context'], supported_auth_modes: ['managed_identity','service_principal','sas'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_object_storage_connectors:gcs_template CONTENT { connector_key: 'gcs', provider_name: 'Google Cloud Storage', storage_kind: 'object_storage', capabilities: ['list_bucket','read_object','write_object_after_approval','metadata_extract','iam_context'], supported_auth_modes: ['service_account','workload_identity'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_object_storage_connectors:minio_template CONTENT { connector_key: 'minio', provider_name: 'MinIO', storage_kind: 's3_compatible_object_storage', capabilities: ['list_bucket','read_object','write_object_after_approval','metadata_extract'], supported_auth_modes: ['access_key','service_account'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE enterprise_object_storage_connectors:ceph_template CONTENT { connector_key: 'ceph', provider_name: 'Ceph Object Gateway', storage_kind: 'distributed_object_storage', capabilities: ['list_bucket','read_object','write_object_after_approval','metadata_extract','cluster_context'], supported_auth_modes: ['access_key','service_account'], connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
