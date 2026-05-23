-- AGenNext Platform
-- 0072: Employee personal assistant, verified skills registry, IT-approved tools, and prompt gallery
-- Purpose: give each employee a personal assistant on signup, configured with approved skills, tools, and roles. Skills must come from the verified AGenNext/agent-skills GitHub registry. Tools require IT approval to prevent SaaS sprawl. Prompt gallery is governed and role-aware.

DEFINE TABLE verified_skill_registries SCHEMAFULL;
DEFINE FIELD registry_key ON verified_skill_registries TYPE string;
DEFINE FIELD registry_name ON verified_skill_registries TYPE string;
DEFINE FIELD registry_provider ON verified_skill_registries TYPE string DEFAULT 'github';
DEFINE FIELD repository_full_name ON verified_skill_registries TYPE string;
DEFINE FIELD default_branch ON verified_skill_registries TYPE string DEFAULT 'main';
DEFINE FIELD verification_policy ON verified_skill_registries TYPE object DEFAULT {};
DEFINE FIELD sync_status ON verified_skill_registries TYPE string DEFAULT 'pending';
DEFINE FIELD last_synced_at ON verified_skill_registries TYPE option<datetime>;
DEFINE FIELD status ON verified_skill_registries TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON verified_skill_registries TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON verified_skill_registries TYPE datetime DEFAULT time::now();
DEFINE INDEX verified_skill_registry_unique ON verified_skill_registries FIELDS registry_key UNIQUE;

DEFINE TABLE verified_agent_skills SCHEMAFULL;
DEFINE FIELD registry_id ON verified_agent_skills TYPE record<verified_skill_registries>;
DEFINE FIELD skill_key ON verified_agent_skills TYPE string;
DEFINE FIELD skill_name ON verified_agent_skills TYPE string;
DEFINE FIELD skill_domain ON verified_agent_skills TYPE string;
DEFINE FIELD skill_version ON verified_agent_skills TYPE string;
DEFINE FIELD repository_path ON verified_agent_skills TYPE string;
DEFINE FIELD commit_sha ON verified_agent_skills TYPE option<string>;
DEFINE FIELD manifest_hash ON verified_agent_skills TYPE option<string>;
DEFINE FIELD required_tool_keys ON verified_agent_skills TYPE array<string> DEFAULT [];
DEFINE FIELD required_role_keys ON verified_agent_skills TYPE array<string> DEFAULT [];
DEFINE FIELD risk_level ON verified_agent_skills TYPE string DEFAULT 'medium';
DEFINE FIELD verification_status ON verified_agent_skills TYPE string DEFAULT 'verified';
DEFINE FIELD status ON verified_agent_skills TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON verified_agent_skills TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON verified_agent_skills TYPE datetime DEFAULT time::now();
DEFINE INDEX verified_agent_skill_unique ON verified_agent_skills FIELDS skill_key, skill_version UNIQUE;

DEFINE TABLE employee_personal_assistants SCHEMAFULL;
DEFINE FIELD tenant_id ON employee_personal_assistants TYPE record<tenants>;
DEFINE FIELD person_id ON employee_personal_assistants TYPE record<identity_persons>;
DEFINE FIELD assistant_ref ON employee_personal_assistants TYPE string;
DEFINE FIELD assistant_name ON employee_personal_assistants TYPE string;
DEFINE FIELD assistant_status ON employee_personal_assistants TYPE string DEFAULT 'active';
DEFINE FIELD default_workspace_ref ON employee_personal_assistants TYPE option<string>;
DEFINE FIELD configuration_status ON employee_personal_assistants TYPE string DEFAULT 'needs_configuration';
DEFINE FIELD created_at ON employee_personal_assistants TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON employee_personal_assistants TYPE datetime DEFAULT time::now();
DEFINE INDEX employee_personal_assistant_unique ON employee_personal_assistants FIELDS tenant_id, person_id UNIQUE;
DEFINE INDEX employee_personal_assistant_ref_unique ON employee_personal_assistants FIELDS assistant_ref UNIQUE;

DEFINE TABLE personal_assistant_role_bindings SCHEMAFULL;
DEFINE FIELD tenant_id ON personal_assistant_role_bindings TYPE record<tenants>;
DEFINE FIELD assistant_id ON personal_assistant_role_bindings TYPE record<employee_personal_assistants>;
DEFINE FIELD role_key ON personal_assistant_role_bindings TYPE string;
DEFINE FIELD role_source ON personal_assistant_role_bindings TYPE string DEFAULT 'tenant_rbac';
DEFINE FIELD scope ON personal_assistant_role_bindings TYPE object DEFAULT {};
DEFINE FIELD status ON personal_assistant_role_bindings TYPE string DEFAULT 'active';
DEFINE FIELD approved_by_person_id ON personal_assistant_role_bindings TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON personal_assistant_role_bindings TYPE datetime DEFAULT time::now();

DEFINE TABLE personal_assistant_skill_bindings SCHEMAFULL;
DEFINE FIELD tenant_id ON personal_assistant_skill_bindings TYPE record<tenants>;
DEFINE FIELD assistant_id ON personal_assistant_skill_bindings TYPE record<employee_personal_assistants>;
DEFINE FIELD verified_skill_id ON personal_assistant_skill_bindings TYPE record<verified_agent_skills>;
DEFINE FIELD requested_by_person_id ON personal_assistant_skill_bindings TYPE option<record<identity_persons>>;
DEFINE FIELD approval_status ON personal_assistant_skill_bindings TYPE string DEFAULT 'pending_manager_or_it_review';
DEFINE FIELD approved_by_person_id ON personal_assistant_skill_bindings TYPE option<record<identity_persons>>;
DEFINE FIELD status ON personal_assistant_skill_bindings TYPE string DEFAULT 'requested';
DEFINE FIELD created_at ON personal_assistant_skill_bindings TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON personal_assistant_skill_bindings TYPE option<datetime>;
DEFINE INDEX personal_assistant_skill_binding_unique ON personal_assistant_skill_bindings FIELDS tenant_id, assistant_id, verified_skill_id UNIQUE;

DEFINE TABLE personal_assistant_tool_approval_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON personal_assistant_tool_approval_requests TYPE record<tenants>;
DEFINE FIELD request_ref ON personal_assistant_tool_approval_requests TYPE string;
DEFINE FIELD assistant_id ON personal_assistant_tool_approval_requests TYPE record<employee_personal_assistants>;
DEFINE FIELD tool_ref ON personal_assistant_tool_approval_requests TYPE string;
DEFINE FIELD tool_source ON personal_assistant_tool_approval_requests TYPE string DEFAULT 'enterprise_app_tool_catalog';
DEFINE FIELD requested_capabilities ON personal_assistant_tool_approval_requests TYPE array<string> DEFAULT [];
DEFINE FIELD business_justification ON personal_assistant_tool_approval_requests TYPE string;
DEFINE FIELD saas_sprawl_check_status ON personal_assistant_tool_approval_requests TYPE string DEFAULT 'pending';
DEFINE FIELD duplicate_tool_candidates ON personal_assistant_tool_approval_requests TYPE array<string> DEFAULT [];
DEFINE FIELD approval_status ON personal_assistant_tool_approval_requests TYPE string DEFAULT 'pending_it_approval';
DEFINE FIELD approved_by_person_id ON personal_assistant_tool_approval_requests TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON personal_assistant_tool_approval_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON personal_assistant_tool_approval_requests TYPE option<datetime>;
DEFINE INDEX personal_assistant_tool_request_ref_unique ON personal_assistant_tool_approval_requests FIELDS request_ref UNIQUE;

DEFINE TABLE personal_assistant_tool_bindings SCHEMAFULL;
DEFINE FIELD tenant_id ON personal_assistant_tool_bindings TYPE record<tenants>;
DEFINE FIELD assistant_id ON personal_assistant_tool_bindings TYPE record<employee_personal_assistants>;
DEFINE FIELD approval_request_id ON personal_assistant_tool_bindings TYPE record<personal_assistant_tool_approval_requests>;
DEFINE FIELD tool_ref ON personal_assistant_tool_bindings TYPE string;
DEFINE FIELD allowed_capabilities ON personal_assistant_tool_bindings TYPE array<string> DEFAULT [];
DEFINE FIELD usage_scope ON personal_assistant_tool_bindings TYPE object DEFAULT {};
DEFINE FIELD status ON personal_assistant_tool_bindings TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON personal_assistant_tool_bindings TYPE datetime DEFAULT time::now();
DEFINE INDEX personal_assistant_tool_binding_unique ON personal_assistant_tool_bindings FIELDS tenant_id, assistant_id, tool_ref UNIQUE;

DEFINE TABLE prompt_gallery_items SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_gallery_items TYPE option<record<tenants>>;
DEFINE FIELD prompt_key ON prompt_gallery_items TYPE string;
DEFINE FIELD prompt_title ON prompt_gallery_items TYPE string;
DEFINE FIELD prompt_domain ON prompt_gallery_items TYPE string;
DEFINE FIELD prompt_kind ON prompt_gallery_items TYPE string DEFAULT 'task_prompt';
DEFINE FIELD prompt_body ON prompt_gallery_items TYPE string;
DEFINE FIELD variables_schema ON prompt_gallery_items TYPE object DEFAULT {};
DEFINE FIELD required_skill_keys ON prompt_gallery_items TYPE array<string> DEFAULT [];
DEFINE FIELD required_tool_keys ON prompt_gallery_items TYPE array<string> DEFAULT [];
DEFINE FIELD target_roles ON prompt_gallery_items TYPE array<string> DEFAULT [];
DEFINE FIELD governance_status ON prompt_gallery_items TYPE string DEFAULT 'approved';
DEFINE FIELD version_label ON prompt_gallery_items TYPE string DEFAULT '1.0.0';
DEFINE FIELD created_by_person_id ON prompt_gallery_items TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON prompt_gallery_items TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON prompt_gallery_items TYPE datetime DEFAULT time::now();
DEFINE INDEX prompt_gallery_item_unique ON prompt_gallery_items FIELDS tenant_id, prompt_key UNIQUE;

DEFINE TABLE prompt_gallery_usage_logs SCHEMAFULL;
DEFINE FIELD tenant_id ON prompt_gallery_usage_logs TYPE record<tenants>;
DEFINE FIELD prompt_id ON prompt_gallery_usage_logs TYPE record<prompt_gallery_items>;
DEFINE FIELD assistant_id ON prompt_gallery_usage_logs TYPE record<employee_personal_assistants>;
DEFINE FIELD person_id ON prompt_gallery_usage_logs TYPE record<identity_persons>;
DEFINE FIELD usage_context ON prompt_gallery_usage_logs TYPE object DEFAULT {};
DEFINE FIELD execution_status ON prompt_gallery_usage_logs TYPE string DEFAULT 'started';
DEFINE FIELD created_at ON prompt_gallery_usage_logs TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::create_personal_assistant_on_signup($tenant_id: record<tenants>, $person_id: record<identity_persons>, $assistant_name: option<string>) {
  RETURN UPSERT type::thing('employee_personal_assistants', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', string::replace(string::from($person_id), ':', '_'))) CONTENT {
    tenant_id: $tenant_id,
    person_id: $person_id,
    assistant_ref: rand::uuid(),
    assistant_name: IF $assistant_name != NONE THEN $assistant_name ELSE 'Personal Assistant' END,
    assistant_status: 'active',
    configuration_status: 'needs_configuration',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::request_personal_assistant_skill($tenant_id: record<tenants>, $assistant_id: record<employee_personal_assistants>, $skill_key: string, $skill_version: string, $requested_by_person_id: option<record<identity_persons>>) {
  LET $skill = SELECT * FROM ONLY verified_agent_skills WHERE skill_key = $skill_key AND skill_version = $skill_version AND verification_status = 'verified' AND status = 'active' LIMIT 1;
  IF $skill = NONE THEN { THROW 'skill_must_come_from_verified_agennext_agent_skills_registry'; };
  RETURN CREATE personal_assistant_skill_bindings CONTENT {
    tenant_id: $tenant_id,
    assistant_id: $assistant_id,
    verified_skill_id: $skill.id,
    requested_by_person_id: $requested_by_person_id,
    approval_status: IF $skill.risk_level IN ['high','critical'] THEN 'pending_it_review' ELSE 'approved' END,
    approved_by_person_id: NONE,
    status: IF $skill.risk_level IN ['high','critical'] THEN 'requested' ELSE 'active' END,
    created_at: time::now(),
    approved_at: IF $skill.risk_level IN ['high','critical'] THEN NONE ELSE time::now() END
  };
};

DEFINE FUNCTION fn::request_personal_assistant_tool_approval($tenant_id: record<tenants>, $assistant_id: record<employee_personal_assistants>, $tool_ref: string, $requested_capabilities: array<string>, $business_justification: string, $duplicate_tool_candidates: array<string>) {
  RETURN CREATE personal_assistant_tool_approval_requests CONTENT {
    tenant_id: $tenant_id,
    request_ref: rand::uuid(),
    assistant_id: $assistant_id,
    tool_ref: $tool_ref,
    tool_source: 'enterprise_app_tool_catalog',
    requested_capabilities: $requested_capabilities,
    business_justification: $business_justification,
    saas_sprawl_check_status: IF count($duplicate_tool_candidates) > 0 THEN 'duplicates_found_review_required' ELSE 'passed' END,
    duplicate_tool_candidates: $duplicate_tool_candidates,
    approval_status: 'pending_it_approval',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::approve_personal_assistant_tool($request_id: record<personal_assistant_tool_approval_requests>, $approved_by_person_id: record<identity_persons>, $allowed_capabilities: array<string>, $usage_scope: object) {
  LET $request = SELECT * FROM ONLY $request_id;
  IF $request = NONE THEN { THROW 'tool_approval_request_not_found'; };
  UPDATE $request_id SET approval_status = 'approved', approved_by_person_id = $approved_by_person_id, approved_at = time::now();
  RETURN CREATE personal_assistant_tool_bindings CONTENT {
    tenant_id: $request.tenant_id,
    assistant_id: $request.assistant_id,
    approval_request_id: $request_id,
    tool_ref: $request.tool_ref,
    allowed_capabilities: $allowed_capabilities,
    usage_scope: $usage_scope,
    status: 'active',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::personal_assistant_context($tenant_id: record<tenants>, $person_id: record<identity_persons>) {
  LET $assistant = SELECT * FROM ONLY employee_personal_assistants WHERE tenant_id = $tenant_id AND person_id = $person_id LIMIT 1;
  RETURN {
    assistant: $assistant,
    roles: SELECT * FROM personal_assistant_role_bindings WHERE assistant_id = $assistant.id AND status = 'active',
    skills: SELECT * FROM personal_assistant_skill_bindings WHERE assistant_id = $assistant.id AND status = 'active',
    tool_requests: SELECT * FROM personal_assistant_tool_approval_requests WHERE assistant_id = $assistant.id ORDER BY created_at DESC,
    tools: SELECT * FROM personal_assistant_tool_bindings WHERE assistant_id = $assistant.id AND status = 'active',
    prompt_gallery: SELECT * FROM prompt_gallery_items WHERE (tenant_id = $tenant_id OR tenant_id = NONE) AND governance_status = 'approved' ORDER BY prompt_domain, prompt_title
  };
};

CREATE verified_skill_registries:agennext_agent_skills CONTENT {
  registry_key: 'agennext_agent_skills',
  registry_name: 'AGenNext Verified Agent Skills',
  registry_provider: 'github',
  repository_full_name: 'AGenNext/agent-skills',
  default_branch: 'main',
  verification_policy: { required_review: true, signed_manifest_preferred: true, immutable_commit_pin_required: true },
  sync_status: 'pending_initial_sync',
  status: 'active',
  created_at: time::now(),
  updated_at: time::now()
};

CREATE prompt_gallery_items:meeting_summary CONTENT { prompt_key: 'meeting_summary', prompt_title: 'Summarize a meeting with decisions and actions', prompt_domain: 'productivity', prompt_kind: 'task_prompt', prompt_body: 'Summarize the meeting notes into decisions, action items, owners, risks, and follow-ups. Preserve uncertainty and cite source notes where available.', variables_schema: { meeting_notes: 'string' }, required_skill_keys: [], required_tool_keys: [], target_roles: ['employee','manager','sales','implementation'], governance_status: 'approved', version_label: '1.0.0', created_at: time::now(), updated_at: time::now() };
CREATE prompt_gallery_items:decision_brief CONTENT { prompt_key: 'decision_brief', prompt_title: 'Create an enterprise decision brief', prompt_domain: 'decision_intelligence', prompt_kind: 'task_prompt', prompt_body: 'Prepare a decision brief with context, options considered, recommendation, risks, mitigations, approvers, evidence, and review date.', variables_schema: { decision_context: 'string' }, required_skill_keys: [], required_tool_keys: [], target_roles: ['manager','it_admin','security','procurement'], governance_status: 'approved', version_label: '1.0.0', created_at: time::now(), updated_at: time::now() };
CREATE prompt_gallery_items:tool_access_request CONTENT { prompt_key: 'tool_access_request', prompt_title: 'Draft a tool access request for IT approval', prompt_domain: 'it_governance', prompt_kind: 'task_prompt', prompt_body: 'Draft a concise tool access request explaining business justification, required capabilities, data scope, alternatives, and SaaS sprawl considerations.', variables_schema: { tool_name: 'string', business_need: 'string' }, required_skill_keys: [], required_tool_keys: [], target_roles: ['employee','manager','it_admin'], governance_status: 'approved', version_label: '1.0.0', created_at: time::now(), updated_at: time::now() };
