-- AGenNext Platform
-- 0071: SFIA as default customizable skills framework
-- Purpose: make SFIA the default skills framework for workforce intelligence, while allowing each organization to customize, extend, map, version, and override the framework without losing auditability.

DEFINE TABLE skills_frameworks SCHEMAFULL;
DEFINE FIELD tenant_id ON skills_frameworks TYPE option<record<tenants>>;
DEFINE FIELD framework_key ON skills_frameworks TYPE string;
DEFINE FIELD framework_name ON skills_frameworks TYPE string;
DEFINE FIELD framework_kind ON skills_frameworks TYPE string DEFAULT 'skills_framework';
DEFINE FIELD source_framework_key ON skills_frameworks TYPE option<string>;
DEFINE FIELD is_default ON skills_frameworks TYPE bool DEFAULT false;
DEFINE FIELD customization_mode ON skills_frameworks TYPE string DEFAULT 'extend_and_override';
DEFINE FIELD status ON skills_frameworks TYPE string DEFAULT 'active';
DEFINE FIELD owner_role ON skills_frameworks TYPE string DEFAULT 'hr_skills_admin';
DEFINE FIELD created_at ON skills_frameworks TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON skills_frameworks TYPE datetime DEFAULT time::now();
DEFINE INDEX skills_framework_unique ON skills_frameworks FIELDS tenant_id, framework_key UNIQUE;

DEFINE TABLE skills_framework_versions SCHEMAFULL;
DEFINE FIELD framework_id ON skills_framework_versions TYPE record<skills_frameworks>;
DEFINE FIELD version_ref ON skills_framework_versions TYPE string;
DEFINE FIELD version_label ON skills_framework_versions TYPE string;
DEFINE FIELD change_summary ON skills_framework_versions TYPE option<string>;
DEFINE FIELD approval_status ON skills_framework_versions TYPE string DEFAULT 'draft';
DEFINE FIELD created_by_person_id ON skills_framework_versions TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON skills_framework_versions TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON skills_framework_versions TYPE option<datetime>;
DEFINE INDEX skills_framework_version_unique ON skills_framework_versions FIELDS framework_id, version_ref UNIQUE;

DEFINE TABLE sfia_skill_levels SCHEMAFULL;
DEFINE FIELD tenant_id ON sfia_skill_levels TYPE option<record<tenants>>;
DEFINE FIELD framework_id ON sfia_skill_levels TYPE record<skills_frameworks>;
DEFINE FIELD level_key ON sfia_skill_levels TYPE string;
DEFINE FIELD level_number ON sfia_skill_levels TYPE int;
DEFINE FIELD level_name ON sfia_skill_levels TYPE string;
DEFINE FIELD autonomy_description ON sfia_skill_levels TYPE option<string>;
DEFINE FIELD influence_description ON sfia_skill_levels TYPE option<string>;
DEFINE FIELD complexity_description ON sfia_skill_levels TYPE option<string>;
DEFINE FIELD business_skills_description ON sfia_skill_levels TYPE option<string>;
DEFINE FIELD status ON sfia_skill_levels TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON sfia_skill_levels TYPE datetime DEFAULT time::now();
DEFINE INDEX sfia_skill_level_unique ON sfia_skill_levels FIELDS framework_id, level_key UNIQUE;

DEFINE TABLE organization_skill_framework_overrides SCHEMAFULL;
DEFINE FIELD tenant_id ON organization_skill_framework_overrides TYPE record<tenants>;
DEFINE FIELD base_framework_key ON organization_skill_framework_overrides TYPE string DEFAULT 'sfia';
DEFINE FIELD override_ref ON organization_skill_framework_overrides TYPE string;
DEFINE FIELD override_kind ON organization_skill_framework_overrides TYPE string;
DEFINE FIELD target_skill_key ON organization_skill_framework_overrides TYPE option<string>;
DEFINE FIELD target_level_key ON organization_skill_framework_overrides TYPE option<string>;
DEFINE FIELD override_payload ON organization_skill_framework_overrides TYPE object DEFAULT {};
DEFINE FIELD reason ON organization_skill_framework_overrides TYPE option<string>;
DEFINE FIELD approval_status ON organization_skill_framework_overrides TYPE string DEFAULT 'pending_review';
DEFINE FIELD created_by_person_id ON organization_skill_framework_overrides TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON organization_skill_framework_overrides TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON organization_skill_framework_overrides TYPE option<datetime>;
DEFINE INDEX organization_skill_framework_override_unique ON organization_skill_framework_overrides FIELDS tenant_id, override_ref UNIQUE;

DEFINE TABLE skill_framework_mappings SCHEMAFULL;
DEFINE FIELD tenant_id ON skill_framework_mappings TYPE option<record<tenants>>;
DEFINE FIELD mapping_ref ON skill_framework_mappings TYPE string;
DEFINE FIELD source_framework_key ON skill_framework_mappings TYPE string;
DEFINE FIELD source_skill_key ON skill_framework_mappings TYPE string;
DEFINE FIELD target_framework_key ON skill_framework_mappings TYPE string;
DEFINE FIELD target_skill_key ON skill_framework_mappings TYPE string;
DEFINE FIELD mapping_confidence ON skill_framework_mappings TYPE number DEFAULT 1;
DEFINE FIELD mapping_rationale ON skill_framework_mappings TYPE option<string>;
DEFINE FIELD status ON skill_framework_mappings TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON skill_framework_mappings TYPE datetime DEFAULT time::now();
DEFINE INDEX skill_framework_mapping_unique ON skill_framework_mappings FIELDS tenant_id, source_framework_key, source_skill_key, target_framework_key, target_skill_key UNIQUE;

DEFINE FUNCTION fn::install_sfia_for_tenant($tenant_id: record<tenants>, $created_by_person_id: option<record<identity_persons>>) {
  LET $framework = UPSERT type::thing('skills_frameworks', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_sfia')) CONTENT {
    tenant_id: $tenant_id,
    framework_key: 'sfia',
    framework_name: 'SFIA - Skills Framework for the Information Age',
    framework_kind: 'skills_framework',
    source_framework_key: 'sfia_global_default',
    is_default: true,
    customization_mode: 'extend_and_override',
    status: 'active',
    owner_role: 'hr_skills_admin',
    created_at: time::now(),
    updated_at: time::now()
  };

  CREATE skills_framework_versions CONTENT {
    framework_id: $framework.id,
    version_ref: rand::uuid(),
    version_label: 'Tenant SFIA baseline',
    change_summary: 'Initialized tenant skills framework from SFIA default baseline.',
    approval_status: 'approved',
    created_by_person_id: $created_by_person_id,
    created_at: time::now(),
    approved_at: time::now()
  };

  RETURN $framework;
};

DEFINE FUNCTION fn::create_skill_framework_override($tenant_id: record<tenants>, $override_kind: string, $target_skill_key: option<string>, $target_level_key: option<string>, $override_payload: object, $reason: option<string>, $created_by_person_id: option<record<identity_persons>>) {
  RETURN CREATE organization_skill_framework_overrides CONTENT {
    tenant_id: $tenant_id,
    base_framework_key: 'sfia',
    override_ref: rand::uuid(),
    override_kind: $override_kind,
    target_skill_key: $target_skill_key,
    target_level_key: $target_level_key,
    override_payload: $override_payload,
    reason: $reason,
    approval_status: 'pending_review',
    created_by_person_id: $created_by_person_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::approve_skill_framework_override($override_id: record<organization_skill_framework_overrides>, $approver_person_id: option<record<identity_persons>>) {
  RETURN UPDATE $override_id SET approval_status = 'approved', approved_at = time::now();
};

DEFINE FUNCTION fn::skills_framework_context($tenant_id: record<tenants>) {
  RETURN {
    frameworks: SELECT * FROM skills_frameworks WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY is_default DESC, framework_name,
    versions: SELECT * FROM skills_framework_versions WHERE framework_id IN (SELECT id FROM skills_frameworks WHERE tenant_id = $tenant_id OR tenant_id = NONE) ORDER BY created_at DESC,
    sfia_levels: SELECT * FROM sfia_skill_levels WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY level_number,
    overrides: SELECT * FROM organization_skill_framework_overrides WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    mappings: SELECT * FROM skill_framework_mappings WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY created_at DESC,
    skills: SELECT * FROM skill_taxonomy_items WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY skill_domain, skill_name
  };
};

-- Global SFIA default framework seed. Detailed SFIA skill catalogs can be imported by tenant from licensed/current SFIA reference data.
CREATE skills_frameworks:sfia_global_default CONTENT {
  framework_key: 'sfia',
  framework_name: 'SFIA - Skills Framework for the Information Age',
  framework_kind: 'skills_framework',
  source_framework_key: NONE,
  is_default: true,
  customization_mode: 'extend_and_override',
  status: 'active',
  owner_role: 'platform_skills_admin',
  created_at: time::now(),
  updated_at: time::now()
};

CREATE sfia_skill_levels:sfia_level_1 CONTENT { framework_id: skills_frameworks:sfia_global_default, level_key: 'sfia_level_1', level_number: 1, level_name: 'Follow', status: 'active', created_at: time::now() };
CREATE sfia_skill_levels:sfia_level_2 CONTENT { framework_id: skills_frameworks:sfia_global_default, level_key: 'sfia_level_2', level_number: 2, level_name: 'Assist', status: 'active', created_at: time::now() };
CREATE sfia_skill_levels:sfia_level_3 CONTENT { framework_id: skills_frameworks:sfia_global_default, level_key: 'sfia_level_3', level_number: 3, level_name: 'Apply', status: 'active', created_at: time::now() };
CREATE sfia_skill_levels:sfia_level_4 CONTENT { framework_id: skills_frameworks:sfia_global_default, level_key: 'sfia_level_4', level_number: 4, level_name: 'Enable', status: 'active', created_at: time::now() };
CREATE sfia_skill_levels:sfia_level_5 CONTENT { framework_id: skills_frameworks:sfia_global_default, level_key: 'sfia_level_5', level_number: 5, level_name: 'Ensure / Advise', status: 'active', created_at: time::now() };
CREATE sfia_skill_levels:sfia_level_6 CONTENT { framework_id: skills_frameworks:sfia_global_default, level_key: 'sfia_level_6', level_number: 6, level_name: 'Initiate / Influence', status: 'active', created_at: time::now() };
CREATE sfia_skill_levels:sfia_level_7 CONTENT { framework_id: skills_frameworks:sfia_global_default, level_key: 'sfia_level_7', level_number: 7, level_name: 'Set Strategy / Inspire / Mobilise', status: 'active', created_at: time::now() };

CREATE skill_taxonomy_items:sfia_default_strategy_architecture CONTENT { skill_key: 'sfia_strategy_architecture', skill_name: 'Strategy and architecture', skill_domain: 'sfia', skill_category: 'category', proficiency_scale: ['sfia_level_1','sfia_level_2','sfia_level_3','sfia_level_4','sfia_level_5','sfia_level_6','sfia_level_7'], related_skill_keys: [], source_refs: ['sfia_global_default'], status: 'active', created_at: time::now(), updated_at: time::now() };
CREATE skill_taxonomy_items:sfia_default_change_transformation CONTENT { skill_key: 'sfia_change_transformation', skill_name: 'Change and transformation', skill_domain: 'sfia', skill_category: 'category', proficiency_scale: ['sfia_level_1','sfia_level_2','sfia_level_3','sfia_level_4','sfia_level_5','sfia_level_6','sfia_level_7'], related_skill_keys: [], source_refs: ['sfia_global_default'], status: 'active', created_at: time::now(), updated_at: time::now() };
CREATE skill_taxonomy_items:sfia_default_development_implementation CONTENT { skill_key: 'sfia_development_implementation', skill_name: 'Development and implementation', skill_domain: 'sfia', skill_category: 'category', proficiency_scale: ['sfia_level_1','sfia_level_2','sfia_level_3','sfia_level_4','sfia_level_5','sfia_level_6','sfia_level_7'], related_skill_keys: [], source_refs: ['sfia_global_default'], status: 'active', created_at: time::now(), updated_at: time::now() };
CREATE skill_taxonomy_items:sfia_default_delivery_operation CONTENT { skill_key: 'sfia_delivery_operation', skill_name: 'Delivery and operation', skill_domain: 'sfia', skill_category: 'category', proficiency_scale: ['sfia_level_1','sfia_level_2','sfia_level_3','sfia_level_4','sfia_level_5','sfia_level_6','sfia_level_7'], related_skill_keys: [], source_refs: ['sfia_global_default'], status: 'active', created_at: time::now(), updated_at: time::now() };
CREATE skill_taxonomy_items:sfia_default_people_skills CONTENT { skill_key: 'sfia_people_skills', skill_name: 'People and skills', skill_domain: 'sfia', skill_category: 'category', proficiency_scale: ['sfia_level_1','sfia_level_2','sfia_level_3','sfia_level_4','sfia_level_5','sfia_level_6','sfia_level_7'], related_skill_keys: [], source_refs: ['sfia_global_default'], status: 'active', created_at: time::now(), updated_at: time::now() };
CREATE skill_taxonomy_items:sfia_default_relationships_engagement CONTENT { skill_key: 'sfia_relationships_engagement', skill_name: 'Relationships and engagement', skill_domain: 'sfia', skill_category: 'category', proficiency_scale: ['sfia_level_1','sfia_level_2','sfia_level_3','sfia_level_4','sfia_level_5','sfia_level_6','sfia_level_7'], related_skill_keys: [], source_refs: ['sfia_global_default'], status: 'active', created_at: time::now(), updated_at: time::now() };
