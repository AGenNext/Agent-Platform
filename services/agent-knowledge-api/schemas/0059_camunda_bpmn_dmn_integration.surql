-- AGenNext Platform
-- 0059: Camunda BPMN/DMN integration
-- Purpose: support native business process modeling through Camunda-compatible BPMN and DMN assets while keeping AGenNext workflow governance, agents, approvals, and decision logs as first-class platform records.

DEFINE TABLE camunda_connectors SCHEMAFULL;
DEFINE FIELD connector_key ON camunda_connectors TYPE string;
DEFINE FIELD tenant_id ON camunda_connectors TYPE option<record<tenants>>;
DEFINE FIELD base_url ON camunda_connectors TYPE string;
DEFINE FIELD auth_mode ON camunda_connectors TYPE string DEFAULT 'oauth_client_credentials';
DEFINE FIELD status ON camunda_connectors TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON camunda_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON camunda_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX camunda_connector_key_unique ON camunda_connectors FIELDS connector_key UNIQUE;

DEFINE TABLE bpmn_models SCHEMAFULL;
DEFINE FIELD tenant_id ON bpmn_models TYPE option<record<tenants>>;
DEFINE FIELD workspace_ref ON bpmn_models TYPE option<string>;
DEFINE FIELD model_key ON bpmn_models TYPE string;
DEFINE FIELD model_name ON bpmn_models TYPE string;
DEFINE FIELD model_version ON bpmn_models TYPE string DEFAULT '1.0.0';
DEFINE FIELD bpmn_xml ON bpmn_models TYPE string;
DEFINE FIELD camunda_process_id ON bpmn_models TYPE option<string>;
DEFINE FIELD deployment_key ON bpmn_models TYPE option<string>;
DEFINE FIELD status ON bpmn_models TYPE string DEFAULT 'draft';
DEFINE FIELD governance_status ON bpmn_models TYPE string DEFAULT 'review_required';
DEFINE FIELD created_by_person_id ON bpmn_models TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON bpmn_models TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON bpmn_models TYPE datetime DEFAULT time::now();
DEFINE INDEX bpmn_model_key_unique ON bpmn_models FIELDS tenant_id, model_key UNIQUE;

DEFINE TABLE dmn_models SCHEMAFULL;
DEFINE FIELD tenant_id ON dmn_models TYPE option<record<tenants>>;
DEFINE FIELD workspace_ref ON dmn_models TYPE option<string>;
DEFINE FIELD model_key ON dmn_models TYPE string;
DEFINE FIELD model_name ON dmn_models TYPE string;
DEFINE FIELD model_version ON dmn_models TYPE string DEFAULT '1.0.0';
DEFINE FIELD dmn_xml ON dmn_models TYPE string;
DEFINE FIELD decision_id ON dmn_models TYPE option<string>;
DEFINE FIELD deployment_key ON dmn_models TYPE option<string>;
DEFINE FIELD status ON dmn_models TYPE string DEFAULT 'draft';
DEFINE FIELD governance_status ON dmn_models TYPE string DEFAULT 'review_required';
DEFINE FIELD created_by_person_id ON dmn_models TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON dmn_models TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON dmn_models TYPE datetime DEFAULT time::now();
DEFINE INDEX dmn_model_key_unique ON dmn_models FIELDS tenant_id, model_key UNIQUE;

DEFINE TABLE workflow_camunda_mappings SCHEMAFULL;
DEFINE FIELD tenant_id ON workflow_camunda_mappings TYPE option<record<tenants>>;
DEFINE FIELD workflow_ref ON workflow_camunda_mappings TYPE string;
DEFINE FIELD bpmn_model_id ON workflow_camunda_mappings TYPE option<record<bpmn_models>>;
DEFINE FIELD dmn_model_ids ON workflow_camunda_mappings TYPE array<record<dmn_models>> DEFAULT [];
DEFINE FIELD mapping_kind ON workflow_camunda_mappings TYPE string DEFAULT 'native_bpmn_dmn';
DEFINE FIELD agent_task_mappings ON workflow_camunda_mappings TYPE array<object> DEFAULT [];
DEFINE FIELD human_task_mappings ON workflow_camunda_mappings TYPE array<object> DEFAULT [];
DEFINE FIELD decision_task_mappings ON workflow_camunda_mappings TYPE array<object> DEFAULT [];
DEFINE FIELD status ON workflow_camunda_mappings TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON workflow_camunda_mappings TYPE datetime DEFAULT time::now();

DEFINE TABLE camunda_deployment_records SCHEMAFULL;
DEFINE FIELD connector_id ON camunda_deployment_records TYPE record<camunda_connectors>;
DEFINE FIELD tenant_id ON camunda_deployment_records TYPE option<record<tenants>>;
DEFINE FIELD bpmn_model_id ON camunda_deployment_records TYPE option<record<bpmn_models>>;
DEFINE FIELD dmn_model_id ON camunda_deployment_records TYPE option<record<dmn_models>>;
DEFINE FIELD deployment_key ON camunda_deployment_records TYPE string;
DEFINE FIELD deployment_status ON camunda_deployment_records TYPE string DEFAULT 'submitted';
DEFINE FIELD deployed_by_person_id ON camunda_deployment_records TYPE option<record<identity_persons>>;
DEFINE FIELD evidence_refs ON camunda_deployment_records TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON camunda_deployment_records TYPE datetime DEFAULT time::now();

DEFINE TABLE camunda_process_instances SCHEMAFULL;
DEFINE FIELD tenant_id ON camunda_process_instances TYPE option<record<tenants>>;
DEFINE FIELD bpmn_model_id ON camunda_process_instances TYPE record<bpmn_models>;
DEFINE FIELD process_instance_key ON camunda_process_instances TYPE string;
DEFINE FIELD business_key ON camunda_process_instances TYPE option<string>;
DEFINE FIELD status ON camunda_process_instances TYPE string DEFAULT 'running';
DEFINE FIELD variables ON camunda_process_instances TYPE object DEFAULT {};
DEFINE FIELD started_by_person_id ON camunda_process_instances TYPE option<record<identity_persons>>;
DEFINE FIELD started_at ON camunda_process_instances TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON camunda_process_instances TYPE option<datetime>;

DEFINE TABLE camunda_task_events SCHEMAFULL;
DEFINE FIELD tenant_id ON camunda_task_events TYPE option<record<tenants>>;
DEFINE FIELD process_instance_id ON camunda_task_events TYPE option<record<camunda_process_instances>>;
DEFINE FIELD task_key ON camunda_task_events TYPE string;
DEFINE FIELD task_type ON camunda_task_events TYPE string;
DEFINE FIELD event_type ON camunda_task_events TYPE string;
DEFINE FIELD payload ON camunda_task_events TYPE object DEFAULT {};
DEFINE FIELD observed_at ON camunda_task_events TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::register_camunda_connector($connector_key: string, $tenant_id: option<record<tenants>>, $base_url: string, $auth_mode: string) {
  RETURN UPSERT type::thing('camunda_connectors', $connector_key) CONTENT {
    connector_key: $connector_key,
    tenant_id: $tenant_id,
    base_url: $base_url,
    auth_mode: $auth_mode,
    status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::save_bpmn_model($tenant_id: option<record<tenants>>, $workspace_ref: option<string>, $model_key: string, $model_name: string, $bpmn_xml: string, $created_by_person_id: option<record<identity_persons>>) {
  RETURN UPSERT type::thing('bpmn_models', $model_key) CONTENT {
    tenant_id: $tenant_id,
    workspace_ref: $workspace_ref,
    model_key: $model_key,
    model_name: $model_name,
    bpmn_xml: $bpmn_xml,
    status: 'draft',
    governance_status: 'review_required',
    created_by_person_id: $created_by_person_id,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::save_dmn_model($tenant_id: option<record<tenants>>, $workspace_ref: option<string>, $model_key: string, $model_name: string, $dmn_xml: string, $created_by_person_id: option<record<identity_persons>>) {
  RETURN UPSERT type::thing('dmn_models', $model_key) CONTENT {
    tenant_id: $tenant_id,
    workspace_ref: $workspace_ref,
    model_key: $model_key,
    model_name: $model_name,
    dmn_xml: $dmn_xml,
    status: 'draft',
    governance_status: 'review_required',
    created_by_person_id: $created_by_person_id,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::map_workflow_to_camunda($tenant_id: option<record<tenants>>, $workflow_ref: string, $bpmn_model_id: option<record<bpmn_models>>, $dmn_model_ids: array<record<dmn_models>>, $agent_task_mappings: array<object>, $human_task_mappings: array<object>, $decision_task_mappings: array<object>) {
  RETURN CREATE workflow_camunda_mappings CONTENT {
    tenant_id: $tenant_id,
    workflow_ref: $workflow_ref,
    bpmn_model_id: $bpmn_model_id,
    dmn_model_ids: $dmn_model_ids,
    mapping_kind: 'native_bpmn_dmn',
    agent_task_mappings: $agent_task_mappings,
    human_task_mappings: $human_task_mappings,
    decision_task_mappings: $decision_task_mappings,
    status: 'active',
    created_at: time::now()
  };
};
