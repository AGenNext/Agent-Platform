-- 0077_data_governance_flows.surql
-- Enterprise data governance flow, ontology governance, model ingestion, and deployment readiness metadata.

DEFINE TABLE data_governance_flows SCHEMAFULL;
DEFINE FIELD tenant_id ON data_governance_flows TYPE option<string>;
DEFINE FIELD name ON data_governance_flows TYPE string;
DEFINE FIELD scope ON data_governance_flows TYPE string;
DEFINE FIELD lifecycle_stage ON data_governance_flows TYPE string DEFAULT 'draft';
DEFINE FIELD owner_role ON data_governance_flows TYPE string DEFAULT 'data_owner';
DEFINE FIELD steward_role ON data_governance_flows TYPE string DEFAULT 'data_steward';
DEFINE FIELD source_systems ON data_governance_flows TYPE array DEFAULT [];
DEFINE FIELD target_systems ON data_governance_flows TYPE array DEFAULT [];
DEFINE FIELD governance_steps ON data_governance_flows TYPE array DEFAULT [
  'discover', 'classify', 'map_to_ontology', 'validate_quality', 'review_access',
  'approve_sync', 'publish_to_graph', 'monitor_lineage', 'review_retention'
];
DEFINE FIELD controls ON data_governance_flows TYPE object DEFAULT {};
DEFINE FIELD evidence_refs ON data_governance_flows TYPE array DEFAULT [];
DEFINE FIELD created_at ON data_governance_flows TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON data_governance_flows TYPE datetime DEFAULT time::now();

DEFINE TABLE data_governance_flow_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON data_governance_flow_runs TYPE option<string>;
DEFINE FIELD flow_id ON data_governance_flow_runs TYPE record<data_governance_flows>;
DEFINE FIELD status ON data_governance_flow_runs TYPE string DEFAULT 'running';
DEFINE FIELD current_step ON data_governance_flow_runs TYPE string DEFAULT 'discover';
DEFINE FIELD actor_id ON data_governance_flow_runs TYPE option<string>;
DEFINE FIELD inputs ON data_governance_flow_runs TYPE object DEFAULT {};
DEFINE FIELD outputs ON data_governance_flow_runs TYPE object DEFAULT {};
DEFINE FIELD quality_findings ON data_governance_flow_runs TYPE array DEFAULT [];
DEFINE FIELD approval_decisions ON data_governance_flow_runs TYPE array DEFAULT [];
DEFINE FIELD lineage_refs ON data_governance_flow_runs TYPE array DEFAULT [];
DEFINE FIELD started_at ON data_governance_flow_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON data_governance_flow_runs TYPE option<datetime>;

DEFINE TABLE ontology_governance_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON ontology_governance_decisions TYPE option<string>;
DEFINE FIELD graph_ref ON ontology_governance_decisions TYPE option<string>;
DEFINE FIELD entity_type ON ontology_governance_decisions TYPE option<string>;
DEFINE FIELD relation_type ON ontology_governance_decisions TYPE option<string>;
DEFINE FIELD proposed_change ON ontology_governance_decisions TYPE object DEFAULT {};
DEFINE FIELD decision_status ON ontology_governance_decisions TYPE string DEFAULT 'pending_review';
DEFINE FIELD rationale ON ontology_governance_decisions TYPE string DEFAULT '';
DEFINE FIELD approver_roles ON ontology_governance_decisions TYPE array DEFAULT ['data_owner', 'enterprise_architect'];
DEFINE FIELD evidence_refs ON ontology_governance_decisions TYPE array DEFAULT [];
DEFINE FIELD created_at ON ontology_governance_decisions TYPE datetime DEFAULT time::now();

DEFINE TABLE data_model_ingestion_jobs SCHEMAFULL;
DEFINE FIELD tenant_id ON data_model_ingestion_jobs TYPE option<string>;
DEFINE FIELD source_tool ON data_model_ingestion_jobs TYPE string;
DEFINE FIELD source_category ON data_model_ingestion_jobs TYPE string;
DEFINE FIELD upload_ref ON data_model_ingestion_jobs TYPE option<string>;
DEFINE FIELD connector_ref ON data_model_ingestion_jobs TYPE option<string>;
DEFINE FIELD model_format ON data_model_ingestion_jobs TYPE string DEFAULT 'json_schema';
DEFINE FIELD mapping_status ON data_model_ingestion_jobs TYPE string DEFAULT 'pending_mapping';
DEFINE FIELD human_review_required ON data_model_ingestion_jobs TYPE bool DEFAULT true;
DEFINE FIELD generated_mappings ON data_model_ingestion_jobs TYPE array DEFAULT [];
DEFINE FIELD accepted_mappings ON data_model_ingestion_jobs TYPE array DEFAULT [];
DEFINE FIELD rejected_mappings ON data_model_ingestion_jobs TYPE array DEFAULT [];
DEFINE FIELD created_at ON data_model_ingestion_jobs TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::create_data_governance_flow($tenant_id: option<string>, $name: string, $scope: string, $source_systems: array, $target_systems: array, $controls: object) {
  RETURN CREATE data_governance_flows CONTENT {
    tenant_id: $tenant_id,
    name: $name,
    scope: $scope,
    source_systems: $source_systems,
    target_systems: $target_systems,
    controls: $controls,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::start_data_governance_flow_run($tenant_id: option<string>, $flow_id: record<data_governance_flows>, $actor_id: option<string>, $inputs: object) {
  RETURN CREATE data_governance_flow_runs CONTENT {
    tenant_id: $tenant_id,
    flow_id: $flow_id,
    actor_id: $actor_id,
    inputs: $inputs,
    status: 'running',
    current_step: 'discover',
    started_at: time::now()
  };
};

DEFINE FUNCTION fn::record_ontology_governance_decision($tenant_id: option<string>, $graph_ref: option<string>, $proposed_change: object, $rationale: string, $evidence_refs: array) {
  RETURN CREATE ontology_governance_decisions CONTENT {
    tenant_id: $tenant_id,
    graph_ref: $graph_ref,
    proposed_change: $proposed_change,
    rationale: $rationale,
    evidence_refs: $evidence_refs,
    decision_status: 'pending_review',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::create_data_model_ingestion_job($tenant_id: option<string>, $source_tool: string, $source_category: string, $model_format: string, $upload_ref: option<string>, $connector_ref: option<string>) {
  RETURN CREATE data_model_ingestion_jobs CONTENT {
    tenant_id: $tenant_id,
    source_tool: $source_tool,
    source_category: $source_category,
    model_format: $model_format,
    upload_ref: $upload_ref,
    connector_ref: $connector_ref,
    mapping_status: 'pending_mapping',
    human_review_required: true,
    created_at: time::now()
  };
};
