-- AGenNext Platform
-- 0076: Default enterprise graph with tenant extensions and external data model upload
-- Purpose: load a default enterprise knowledge/operational graph, allow organizations to extend graph entities/relations, and upload/import data models from current apps and tools.

DEFINE TABLE default_graph_entity_types SCHEMAFULL;
DEFINE FIELD entity_type_key ON default_graph_entity_types TYPE string;
DEFINE FIELD entity_type_name ON default_graph_entity_types TYPE string;
DEFINE FIELD entity_domain ON default_graph_entity_types TYPE string;
DEFINE FIELD schema_org_type ON default_graph_entity_types TYPE option<string>;
DEFINE FIELD default_attributes_schema ON default_graph_entity_types TYPE object DEFAULT {};
DEFINE FIELD allowed_relation_keys ON default_graph_entity_types TYPE array<string> DEFAULT [];
DEFINE FIELD extensible ON default_graph_entity_types TYPE bool DEFAULT true;
DEFINE FIELD active ON default_graph_entity_types TYPE bool DEFAULT true;
DEFINE FIELD created_at ON default_graph_entity_types TYPE datetime DEFAULT time::now();
DEFINE INDEX default_graph_entity_type_unique ON default_graph_entity_types FIELDS entity_type_key UNIQUE;

DEFINE TABLE default_graph_relation_types SCHEMAFULL;
DEFINE FIELD relation_key ON default_graph_relation_types TYPE string;
DEFINE FIELD relation_name ON default_graph_relation_types TYPE string;
DEFINE FIELD source_entity_types ON default_graph_relation_types TYPE array<string> DEFAULT [];
DEFINE FIELD target_entity_types ON default_graph_relation_types TYPE array<string> DEFAULT [];
DEFINE FIELD relation_domain ON default_graph_relation_types TYPE string;
DEFINE FIELD attributes_schema ON default_graph_relation_types TYPE object DEFAULT {};
DEFINE FIELD active ON default_graph_relation_types TYPE bool DEFAULT true;
DEFINE FIELD created_at ON default_graph_relation_types TYPE datetime DEFAULT time::now();
DEFINE INDEX default_graph_relation_type_unique ON default_graph_relation_types FIELDS relation_key UNIQUE;

DEFINE TABLE tenant_graph_extensions SCHEMAFULL;
DEFINE FIELD tenant_id ON tenant_graph_extensions TYPE record<tenants>;
DEFINE FIELD extension_ref ON tenant_graph_extensions TYPE string;
DEFINE FIELD extension_kind ON tenant_graph_extensions TYPE string;
DEFINE FIELD base_type_key ON tenant_graph_extensions TYPE option<string>;
DEFINE FIELD custom_type_key ON tenant_graph_extensions TYPE string;
DEFINE FIELD custom_type_name ON tenant_graph_extensions TYPE string;
DEFINE FIELD extension_schema ON tenant_graph_extensions TYPE object DEFAULT {};
DEFINE FIELD mapping_rules ON tenant_graph_extensions TYPE array<object> DEFAULT [];
DEFINE FIELD approval_status ON tenant_graph_extensions TYPE string DEFAULT 'pending_review';
DEFINE FIELD created_by_person_id ON tenant_graph_extensions TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON tenant_graph_extensions TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON tenant_graph_extensions TYPE option<datetime>;
DEFINE INDEX tenant_graph_extension_ref_unique ON tenant_graph_extensions FIELDS extension_ref UNIQUE;

DEFINE TABLE external_data_model_uploads SCHEMAFULL;
DEFINE FIELD tenant_id ON external_data_model_uploads TYPE record<tenants>;
DEFINE FIELD upload_ref ON external_data_model_uploads TYPE string;
DEFINE FIELD source_app_name ON external_data_model_uploads TYPE string;
DEFINE FIELD source_app_kind ON external_data_model_uploads TYPE string;
DEFINE FIELD model_format ON external_data_model_uploads TYPE string;
DEFINE FIELD file_refs ON external_data_model_uploads TYPE array<string> DEFAULT [];
DEFINE FIELD raw_model_summary ON external_data_model_uploads TYPE option<string>;
DEFINE FIELD parsing_status ON external_data_model_uploads TYPE string DEFAULT 'pending';
DEFINE FIELD uploaded_by_person_id ON external_data_model_uploads TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON external_data_model_uploads TYPE datetime DEFAULT time::now();
DEFINE INDEX external_data_model_upload_ref_unique ON external_data_model_uploads FIELDS upload_ref UNIQUE;

DEFINE TABLE external_data_model_mappings SCHEMAFULL;
DEFINE FIELD tenant_id ON external_data_model_mappings TYPE record<tenants>;
DEFINE FIELD upload_id ON external_data_model_mappings TYPE record<external_data_model_uploads>;
DEFINE FIELD mapping_ref ON external_data_model_mappings TYPE string;
DEFINE FIELD source_entity_name ON external_data_model_mappings TYPE string;
DEFINE FIELD source_entity_kind ON external_data_model_mappings TYPE option<string>;
DEFINE FIELD target_graph_entity_type_key ON external_data_model_mappings TYPE string;
DEFINE FIELD field_mappings ON external_data_model_mappings TYPE array<object> DEFAULT [];
DEFINE FIELD relation_mappings ON external_data_model_mappings TYPE array<object> DEFAULT [];
DEFINE FIELD confidence_score ON external_data_model_mappings TYPE number DEFAULT 0;
DEFINE FIELD review_status ON external_data_model_mappings TYPE string DEFAULT 'needs_review';
DEFINE FIELD created_at ON external_data_model_mappings TYPE datetime DEFAULT time::now();
DEFINE INDEX external_data_model_mapping_ref_unique ON external_data_model_mappings FIELDS mapping_ref UNIQUE;

DEFINE FUNCTION fn::create_tenant_graph_extension($tenant_id: record<tenants>, $extension_kind: string, $base_type_key: option<string>, $custom_type_key: string, $custom_type_name: string, $extension_schema: object, $mapping_rules: array<object>, $created_by_person_id: option<record<identity_persons>>) {
  RETURN CREATE tenant_graph_extensions CONTENT {
    tenant_id: $tenant_id,
    extension_ref: rand::uuid(),
    extension_kind: $extension_kind,
    base_type_key: $base_type_key,
    custom_type_key: $custom_type_key,
    custom_type_name: $custom_type_name,
    extension_schema: $extension_schema,
    mapping_rules: $mapping_rules,
    approval_status: 'pending_review',
    created_by_person_id: $created_by_person_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::record_external_data_model_upload($tenant_id: record<tenants>, $source_app_name: string, $source_app_kind: string, $model_format: string, $file_refs: array<string>, $raw_model_summary: option<string>, $uploaded_by_person_id: option<record<identity_persons>>) {
  RETURN CREATE external_data_model_uploads CONTENT {
    tenant_id: $tenant_id,
    upload_ref: rand::uuid(),
    source_app_name: $source_app_name,
    source_app_kind: $source_app_kind,
    model_format: $model_format,
    file_refs: $file_refs,
    raw_model_summary: $raw_model_summary,
    parsing_status: 'pending',
    uploaded_by_person_id: $uploaded_by_person_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::default_graph_context($tenant_id: record<tenants>) {
  RETURN {
    default_entity_types: SELECT * FROM default_graph_entity_types WHERE active = true ORDER BY entity_domain, entity_type_name,
    default_relation_types: SELECT * FROM default_graph_relation_types WHERE active = true ORDER BY relation_domain, relation_name,
    tenant_extensions: SELECT * FROM tenant_graph_extensions WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    model_uploads: SELECT * FROM external_data_model_uploads WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    model_mappings: SELECT * FROM external_data_model_mappings WHERE tenant_id = $tenant_id ORDER BY created_at DESC
  };
};

CREATE default_graph_entity_types:organization CONTENT { entity_type_key: 'organization', entity_type_name: 'Organization', entity_domain: 'core', schema_org_type: 'Organization', default_attributes_schema: { name: 'string', domain: 'string', industry: 'string' }, allowed_relation_keys: ['owns','employs','uses','governs'], extensible: true, active: true, created_at: time::now() };
CREATE default_graph_entity_types:person CONTENT { entity_type_key: 'person', entity_type_name: 'Person', entity_domain: 'identity', schema_org_type: 'Person', default_attributes_schema: { name: 'string', email_hash: 'string', role: 'string' }, allowed_relation_keys: ['member_of','owns','approves','uses'], extensible: true, active: true, created_at: time::now() };
CREATE default_graph_entity_types:application CONTENT { entity_type_key: 'application', entity_type_name: 'Application', entity_domain: 'apps', schema_org_type: 'SoftwareApplication', default_attributes_schema: { name: 'string', category: 'string', owner: 'string' }, allowed_relation_keys: ['owned_by','integrates_with','stores','processes'], extensible: true, active: true, created_at: time::now() };
CREATE default_graph_entity_types:agent CONTENT { entity_type_key: 'agent', entity_type_name: 'Agent', entity_domain: 'ai', schema_org_type: 'SoftwareApplication', default_attributes_schema: { name: 'string', status: 'string', risk_level: 'string' }, allowed_relation_keys: ['uses_tool','has_skill','hands_off_to','executes'], extensible: true, active: true, created_at: time::now() };
CREATE default_graph_entity_types:skill CONTENT { entity_type_key: 'skill', entity_type_name: 'Skill', entity_domain: 'workforce', schema_org_type: 'DefinedTerm', default_attributes_schema: { name: 'string', framework: 'string', level: 'string' }, allowed_relation_keys: ['required_by','held_by','enables'], extensible: true, active: true, created_at: time::now() };
CREATE default_graph_entity_types:dataset CONTENT { entity_type_key: 'dataset', entity_type_name: 'Dataset', entity_domain: 'data', schema_org_type: 'Dataset', default_attributes_schema: { name: 'string', sensitivity: 'string', owner: 'string' }, allowed_relation_keys: ['stored_in','derived_from','used_by'], extensible: true, active: true, created_at: time::now() };
CREATE default_graph_entity_types:process CONTENT { entity_type_key: 'process', entity_type_name: 'Process', entity_domain: 'operations', schema_org_type: 'HowTo', default_attributes_schema: { name: 'string', owner: 'string', stage: 'string' }, allowed_relation_keys: ['executes','requires_approval','produces'], extensible: true, active: true, created_at: time::now() };
CREATE default_graph_entity_types:document CONTENT { entity_type_key: 'document', entity_type_name: 'Document', entity_domain: 'content', schema_org_type: 'CreativeWork', default_attributes_schema: { title: 'string', kind: 'string', version: 'string' }, allowed_relation_keys: ['references','evidence_for','published_to'], extensible: true, active: true, created_at: time::now() };

CREATE default_graph_relation_types:owns CONTENT { relation_key: 'owns', relation_name: 'Owns', source_entity_types: ['person','organization'], target_entity_types: ['application','dataset','process','document','agent'], relation_domain: 'governance', attributes_schema: { ownership_type: 'string' }, active: true, created_at: time::now() };
CREATE default_graph_relation_types:uses CONTENT { relation_key: 'uses', relation_name: 'Uses', source_entity_types: ['person','agent','process'], target_entity_types: ['application','tool','dataset'], relation_domain: 'operations', attributes_schema: { usage_scope: 'object' }, active: true, created_at: time::now() };
CREATE default_graph_relation_types:integrates_with CONTENT { relation_key: 'integrates_with', relation_name: 'Integrates With', source_entity_types: ['application'], target_entity_types: ['application','dataset','process'], relation_domain: 'integration', attributes_schema: { integration_kind: 'string' }, active: true, created_at: time::now() };
CREATE default_graph_relation_types:requires_approval CONTENT { relation_key: 'requires_approval', relation_name: 'Requires Approval', source_entity_types: ['process','agent','document'], target_entity_types: ['person','organization'], relation_domain: 'governance', attributes_schema: { approval_role: 'string' }, active: true, created_at: time::now() };
CREATE default_graph_relation_types:hands_off_to CONTENT { relation_key: 'hands_off_to', relation_name: 'Hands Off To', source_entity_types: ['agent'], target_entity_types: ['agent','person'], relation_domain: 'ai_orchestration', attributes_schema: { handoff_policy: 'string' }, active: true, created_at: time::now() };
