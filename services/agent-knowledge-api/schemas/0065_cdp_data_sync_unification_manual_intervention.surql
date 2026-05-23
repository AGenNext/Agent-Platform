-- AGenNext Platform
-- 0065: CDP integration, data sync, data unification workflows, and manual data intervention
-- Purpose: integrate with customer data platforms such as Apache Unomi; support data sync, data flows, data unification across siloed systems, documents/files/manual uploads, and human correction inside AI-augmented workflows.

DEFINE TABLE customer_data_platform_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON customer_data_platform_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON customer_data_platform_connectors TYPE string;
DEFINE FIELD provider_name ON customer_data_platform_connectors TYPE string;
DEFINE FIELD provider_kind ON customer_data_platform_connectors TYPE string DEFAULT 'cdp';
DEFINE FIELD capabilities ON customer_data_platform_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD connection_status ON customer_data_platform_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD sync_status ON customer_data_platform_connectors TYPE string DEFAULT 'not_started';
DEFINE FIELD last_synced_at ON customer_data_platform_connectors TYPE option<datetime>;
DEFINE FIELD source_of_record_policy ON customer_data_platform_connectors TYPE string DEFAULT 'external_cdp_remains_source_of_record';
DEFINE FIELD created_at ON customer_data_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON customer_data_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX customer_data_platform_connector_unique ON customer_data_platform_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE data_source_connections SCHEMAFULL;
DEFINE FIELD tenant_id ON data_source_connections TYPE record<tenants>;
DEFINE FIELD source_key ON data_source_connections TYPE string;
DEFINE FIELD source_name ON data_source_connections TYPE string;
DEFINE FIELD source_kind ON data_source_connections TYPE string;
DEFINE FIELD connector_ref ON data_source_connections TYPE option<string>;
DEFINE FIELD owning_team_role ON data_source_connections TYPE string DEFAULT 'data_owner';
DEFINE FIELD data_domains ON data_source_connections TYPE array<string> DEFAULT [];
DEFINE FIELD sync_mode ON data_source_connections TYPE string DEFAULT 'scheduled';
DEFINE FIELD access_mode ON data_source_connections TYPE string DEFAULT 'read_first_approve_writeback';
DEFINE FIELD status ON data_source_connections TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON data_source_connections TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON data_source_connections TYPE datetime DEFAULT time::now();
DEFINE INDEX data_source_connection_unique ON data_source_connections FIELDS tenant_id, source_key UNIQUE;

DEFINE TABLE data_sync_flows SCHEMAFULL;
DEFINE FIELD tenant_id ON data_sync_flows TYPE record<tenants>;
DEFINE FIELD flow_key ON data_sync_flows TYPE string;
DEFINE FIELD flow_name ON data_sync_flows TYPE string;
DEFINE FIELD flow_kind ON data_sync_flows TYPE string DEFAULT 'data_sync';
DEFINE FIELD source_connection_ids ON data_sync_flows TYPE array<record<data_source_connections>> DEFAULT [];
DEFINE FIELD target_connection_ids ON data_sync_flows TYPE array<record<data_source_connections>> DEFAULT [];
DEFINE FIELD schedule_kind ON data_sync_flows TYPE string DEFAULT 'manual_or_scheduled';
DEFINE FIELD transformation_policy ON data_sync_flows TYPE object DEFAULT {};
DEFINE FIELD validation_policy ON data_sync_flows TYPE object DEFAULT {};
DEFINE FIELD conflict_resolution_policy ON data_sync_flows TYPE string DEFAULT 'human_review_on_conflict';
DEFINE FIELD approval_required ON data_sync_flows TYPE bool DEFAULT true;
DEFINE FIELD status ON data_sync_flows TYPE string DEFAULT 'draft';
DEFINE FIELD created_at ON data_sync_flows TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON data_sync_flows TYPE datetime DEFAULT time::now();
DEFINE INDEX data_sync_flow_unique ON data_sync_flows FIELDS tenant_id, flow_key UNIQUE;

DEFINE TABLE data_unification_workflows SCHEMAFULL;
DEFINE FIELD tenant_id ON data_unification_workflows TYPE record<tenants>;
DEFINE FIELD workflow_key ON data_unification_workflows TYPE string;
DEFINE FIELD workflow_name ON data_unification_workflows TYPE string;
DEFINE FIELD entity_kind ON data_unification_workflows TYPE string;
DEFINE FIELD source_connection_ids ON data_unification_workflows TYPE array<record<data_source_connections>> DEFAULT [];
DEFINE FIELD identity_resolution_rules ON data_unification_workflows TYPE array<object> DEFAULT [];
DEFINE FIELD merge_rules ON data_unification_workflows TYPE array<object> DEFAULT [];
DEFINE FIELD survivorship_rules ON data_unification_workflows TYPE array<object> DEFAULT [];
DEFINE FIELD confidence_thresholds ON data_unification_workflows TYPE object DEFAULT { auto_merge: 0.95, human_review: 0.75 };
DEFINE FIELD manual_review_required_below_confidence ON data_unification_workflows TYPE bool DEFAULT true;
DEFINE FIELD status ON data_unification_workflows TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON data_unification_workflows TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON data_unification_workflows TYPE datetime DEFAULT time::now();
DEFINE INDEX data_unification_workflow_unique ON data_unification_workflows FIELDS tenant_id, workflow_key UNIQUE;

DEFINE TABLE manual_data_upload_batches SCHEMAFULL;
DEFINE FIELD tenant_id ON manual_data_upload_batches TYPE record<tenants>;
DEFINE FIELD batch_ref ON manual_data_upload_batches TYPE string;
DEFINE FIELD upload_kind ON manual_data_upload_batches TYPE string;
DEFINE FIELD source_name ON manual_data_upload_batches TYPE string;
DEFINE FIELD file_refs ON manual_data_upload_batches TYPE array<string> DEFAULT [];
DEFINE FIELD document_refs ON manual_data_upload_batches TYPE array<string> DEFAULT [];
DEFINE FIELD uploaded_by_person_id ON manual_data_upload_batches TYPE option<record<identity_persons>>;
DEFINE FIELD intended_workflow_ref ON manual_data_upload_batches TYPE option<string>;
DEFINE FIELD validation_status ON manual_data_upload_batches TYPE string DEFAULT 'pending_validation';
DEFINE FIELD ingestion_status ON manual_data_upload_batches TYPE string DEFAULT 'not_ingested';
DEFINE FIELD correction_status ON manual_data_upload_batches TYPE string DEFAULT 'not_required';
DEFINE FIELD created_at ON manual_data_upload_batches TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON manual_data_upload_batches TYPE datetime DEFAULT time::now();
DEFINE INDEX manual_data_upload_batch_ref_unique ON manual_data_upload_batches FIELDS batch_ref UNIQUE;

DEFINE TABLE data_quality_issues SCHEMAFULL;
DEFINE FIELD tenant_id ON data_quality_issues TYPE record<tenants>;
DEFINE FIELD issue_ref ON data_quality_issues TYPE string;
DEFINE FIELD source_connection_id ON data_quality_issues TYPE option<record<data_source_connections>>;
DEFINE FIELD upload_batch_id ON data_quality_issues TYPE option<record<manual_data_upload_batches>>;
DEFINE FIELD workflow_ref ON data_quality_issues TYPE option<string>;
DEFINE FIELD entity_ref ON data_quality_issues TYPE option<string>;
DEFINE FIELD issue_kind ON data_quality_issues TYPE string;
DEFINE FIELD severity ON data_quality_issues TYPE string DEFAULT 'medium';
DEFINE FIELD detected_value ON data_quality_issues TYPE option<object>;
DEFINE FIELD suggested_correction ON data_quality_issues TYPE option<object>;
DEFINE FIELD status ON data_quality_issues TYPE string DEFAULT 'open';
DEFINE FIELD assigned_role ON data_quality_issues TYPE string DEFAULT 'data_steward';
DEFINE FIELD assigned_person_id ON data_quality_issues TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON data_quality_issues TYPE datetime DEFAULT time::now();
DEFINE FIELD resolved_at ON data_quality_issues TYPE option<datetime>;
DEFINE INDEX data_quality_issue_ref_unique ON data_quality_issues FIELDS issue_ref UNIQUE;

DEFINE TABLE manual_data_interventions SCHEMAFULL;
DEFINE FIELD tenant_id ON manual_data_interventions TYPE record<tenants>;
DEFINE FIELD intervention_ref ON manual_data_interventions TYPE string;
DEFINE FIELD workflow_ref ON manual_data_interventions TYPE string;
DEFINE FIELD intervention_kind ON manual_data_interventions TYPE string;
DEFINE FIELD related_issue_id ON manual_data_interventions TYPE option<record<data_quality_issues>>;
DEFINE FIELD entity_ref ON manual_data_interventions TYPE option<string>;
DEFINE FIELD proposed_change ON manual_data_interventions TYPE object DEFAULT {};
DEFINE FIELD human_corrected_value ON manual_data_interventions TYPE option<object>;
DEFINE FIELD actor_person_id ON manual_data_interventions TYPE option<record<identity_persons>>;
DEFINE FIELD approval_status ON manual_data_interventions TYPE string DEFAULT 'pending_review';
DEFINE FIELD execution_status ON manual_data_interventions TYPE string DEFAULT 'not_applied';
DEFINE FIELD evidence_refs ON manual_data_interventions TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON manual_data_interventions TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON manual_data_interventions TYPE option<datetime>;
DEFINE FIELD applied_at ON manual_data_interventions TYPE option<datetime>;
DEFINE INDEX manual_data_intervention_ref_unique ON manual_data_interventions FIELDS intervention_ref UNIQUE;

DEFINE TABLE unified_customer_profiles SCHEMAFULL;
DEFINE FIELD tenant_id ON unified_customer_profiles TYPE record<tenants>;
DEFINE FIELD unified_profile_ref ON unified_customer_profiles TYPE string;
DEFINE FIELD cdp_profile_id ON unified_customer_profiles TYPE option<string>;
DEFINE FIELD entity_keys ON unified_customer_profiles TYPE array<string> DEFAULT [];
DEFINE FIELD source_refs ON unified_customer_profiles TYPE array<object> DEFAULT [];
DEFINE FIELD profile_attributes ON unified_customer_profiles TYPE object DEFAULT {};
DEFINE FIELD consent_context ON unified_customer_profiles TYPE object DEFAULT {};
DEFINE FIELD confidence_score ON unified_customer_profiles TYPE number DEFAULT 0;
DEFINE FIELD unification_status ON unified_customer_profiles TYPE string DEFAULT 'active';
DEFINE FIELD last_unified_at ON unified_customer_profiles TYPE datetime DEFAULT time::now();
DEFINE INDEX unified_customer_profile_ref_unique ON unified_customer_profiles FIELDS tenant_id, unified_profile_ref UNIQUE;

DEFINE FUNCTION fn::register_cdp_connector($tenant_id: record<tenants>, $connector_key: string, $provider_name: string, $capabilities: array<string>) {
  RETURN UPSERT type::thing('customer_data_platform_connectors', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    provider_name: $provider_name,
    provider_kind: 'cdp',
    capabilities: $capabilities,
    connection_status: 'active',
    sync_status: 'ready',
    source_of_record_policy: 'external_cdp_remains_source_of_record',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::create_data_source_connection($tenant_id: record<tenants>, $source_key: string, $source_name: string, $source_kind: string, $connector_ref: option<string>, $owning_team_role: string, $data_domains: array<string>, $sync_mode: string) {
  RETURN UPSERT type::thing('data_source_connections', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $source_key)) CONTENT {
    tenant_id: $tenant_id,
    source_key: $source_key,
    source_name: $source_name,
    source_kind: $source_kind,
    connector_ref: $connector_ref,
    owning_team_role: $owning_team_role,
    data_domains: $data_domains,
    sync_mode: $sync_mode,
    access_mode: 'read_first_approve_writeback',
    status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::create_manual_data_upload_batch($tenant_id: record<tenants>, $upload_kind: string, $source_name: string, $file_refs: array<string>, $document_refs: array<string>, $uploaded_by_person_id: option<record<identity_persons>>, $intended_workflow_ref: option<string>) {
  RETURN CREATE manual_data_upload_batches CONTENT {
    tenant_id: $tenant_id,
    batch_ref: rand::uuid(),
    upload_kind: $upload_kind,
    source_name: $source_name,
    file_refs: $file_refs,
    document_refs: $document_refs,
    uploaded_by_person_id: $uploaded_by_person_id,
    intended_workflow_ref: $intended_workflow_ref,
    validation_status: 'pending_validation',
    ingestion_status: 'not_ingested',
    correction_status: 'not_required',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::create_data_quality_issue($tenant_id: record<tenants>, $source_connection_id: option<record<data_source_connections>>, $upload_batch_id: option<record<manual_data_upload_batches>>, $workflow_ref: option<string>, $entity_ref: option<string>, $issue_kind: string, $severity: string, $detected_value: option<object>, $suggested_correction: option<object>, $assigned_role: string) {
  RETURN CREATE data_quality_issues CONTENT {
    tenant_id: $tenant_id,
    issue_ref: rand::uuid(),
    source_connection_id: $source_connection_id,
    upload_batch_id: $upload_batch_id,
    workflow_ref: $workflow_ref,
    entity_ref: $entity_ref,
    issue_kind: $issue_kind,
    severity: $severity,
    detected_value: $detected_value,
    suggested_correction: $suggested_correction,
    status: 'open',
    assigned_role: $assigned_role,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::record_manual_data_intervention($tenant_id: record<tenants>, $workflow_ref: string, $intervention_kind: string, $related_issue_id: option<record<data_quality_issues>>, $entity_ref: option<string>, $proposed_change: object, $human_corrected_value: option<object>, $actor_person_id: option<record<identity_persons>>, $evidence_refs: array<string>) {
  RETURN CREATE manual_data_interventions CONTENT {
    tenant_id: $tenant_id,
    intervention_ref: rand::uuid(),
    workflow_ref: $workflow_ref,
    intervention_kind: $intervention_kind,
    related_issue_id: $related_issue_id,
    entity_ref: $entity_ref,
    proposed_change: $proposed_change,
    human_corrected_value: $human_corrected_value,
    actor_person_id: $actor_person_id,
    approval_status: 'pending_review',
    execution_status: 'not_applied',
    evidence_refs: $evidence_refs,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::approve_and_apply_manual_data_intervention($intervention_id: record<manual_data_interventions>, $approver_person_id: option<record<identity_persons>>) {
  LET $intervention = SELECT * FROM ONLY $intervention_id;
  IF $intervention = NONE THEN { THROW 'manual_data_intervention_not_found'; };
  UPDATE $intervention_id SET approval_status = 'approved', execution_status = 'applied', approved_at = time::now(), applied_at = time::now();
  IF $intervention.related_issue_id != NONE THEN {
    UPDATE $intervention.related_issue_id SET status = 'resolved', assigned_person_id = $approver_person_id, resolved_at = time::now();
  };
  RETURN SELECT * FROM ONLY $intervention_id;
};

DEFINE FUNCTION fn::data_unification_context($tenant_id: record<tenants>) {
  RETURN {
    cdp_connectors: SELECT * FROM customer_data_platform_connectors WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    sources: SELECT * FROM data_source_connections WHERE tenant_id = $tenant_id AND status = 'active' ORDER BY source_name,
    sync_flows: SELECT * FROM data_sync_flows WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    unification_workflows: SELECT * FROM data_unification_workflows WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    manual_uploads: SELECT * FROM manual_data_upload_batches WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    quality_issues: SELECT * FROM data_quality_issues WHERE tenant_id = $tenant_id AND status != 'resolved' ORDER BY created_at DESC,
    manual_interventions: SELECT * FROM manual_data_interventions WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    unified_profiles: SELECT * FROM unified_customer_profiles WHERE tenant_id = $tenant_id ORDER BY last_unified_at DESC LIMIT 50
  };
};

-- Built-in CDP connector seed.
CREATE customer_data_platform_connectors:apache_unomi_template CONTENT {
  connector_key: 'apache_unomi',
  provider_name: 'Apache Unomi',
  provider_kind: 'cdp',
  capabilities: ['profile_sync','event_sync','segment_sync','consent_context','identity_resolution','customer_journey_context'],
  connection_status: 'template',
  sync_status: 'not_started',
  source_of_record_policy: 'external_cdp_remains_source_of_record',
  created_at: time::now(),
  updated_at: time::now()
};
