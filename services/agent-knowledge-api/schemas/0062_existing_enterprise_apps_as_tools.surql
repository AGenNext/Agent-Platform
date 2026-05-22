-- AGenNext Platform
-- 0062: Existing enterprise apps as governed tools
-- Purpose: use the customer's current enterprise apps as tools. Do not replace their systems, processes, records, approval chains, or ownership model. AI supports and orchestrates existing systems through governed tool actions.

DEFINE TABLE enterprise_app_tool_catalog SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_app_tool_catalog TYPE record<tenants>;
DEFINE FIELD app_id ON enterprise_app_tool_catalog TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD tool_key ON enterprise_app_tool_catalog TYPE string;
DEFINE FIELD tool_name ON enterprise_app_tool_catalog TYPE string;
DEFINE FIELD tool_category ON enterprise_app_tool_catalog TYPE string;
DEFINE FIELD source_system ON enterprise_app_tool_catalog TYPE string;
DEFINE FIELD supported_actions ON enterprise_app_tool_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD read_actions ON enterprise_app_tool_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD write_actions ON enterprise_app_tool_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD requires_app_owner_approval ON enterprise_app_tool_catalog TYPE bool DEFAULT true;
DEFINE FIELD requires_human_confirmation ON enterprise_app_tool_catalog TYPE bool DEFAULT true;
DEFINE FIELD respects_source_of_record ON enterprise_app_tool_catalog TYPE bool DEFAULT true;
DEFINE FIELD execution_mode ON enterprise_app_tool_catalog TYPE string DEFAULT 'recommend_then_execute_after_approval';
DEFINE FIELD status ON enterprise_app_tool_catalog TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_app_tool_catalog TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_app_tool_catalog TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_app_tool_unique ON enterprise_app_tool_catalog FIELDS tenant_id, app_id, tool_key UNIQUE;

DEFINE TABLE enterprise_app_tool_action_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_app_tool_action_requests TYPE record<tenants>;
DEFINE FIELD tool_id ON enterprise_app_tool_action_requests TYPE record<enterprise_app_tool_catalog>;
DEFINE FIELD app_id ON enterprise_app_tool_action_requests TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD requested_by_person_id ON enterprise_app_tool_action_requests TYPE option<record<identity_persons>>;
DEFINE FIELD action_key ON enterprise_app_tool_action_requests TYPE string;
DEFINE FIELD action_intent ON enterprise_app_tool_action_requests TYPE string;
DEFINE FIELD proposed_payload ON enterprise_app_tool_action_requests TYPE object DEFAULT {};
DEFINE FIELD source_record_refs ON enterprise_app_tool_action_requests TYPE array<string> DEFAULT [];
DEFINE FIELD approval_status ON enterprise_app_tool_action_requests TYPE string DEFAULT 'pending_app_owner_review';
DEFINE FIELD execution_status ON enterprise_app_tool_action_requests TYPE string DEFAULT 'not_executed';
DEFINE FIELD decision_id ON enterprise_app_tool_action_requests TYPE option<record<enterprise_decision_logs>>;
DEFINE FIELD created_at ON enterprise_app_tool_action_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON enterprise_app_tool_action_requests TYPE option<datetime>;
DEFINE FIELD executed_at ON enterprise_app_tool_action_requests TYPE option<datetime>;

DEFINE TABLE enterprise_system_of_record_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_system_of_record_policies TYPE record<tenants>;
DEFINE FIELD app_id ON enterprise_system_of_record_policies TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD domain_key ON enterprise_system_of_record_policies TYPE string;
DEFINE FIELD source_of_record_app_id ON enterprise_system_of_record_policies TYPE record<enterprise_discovered_business_apps>;
DEFINE FIELD allowed_write_modes ON enterprise_system_of_record_policies TYPE array<string> DEFAULT ['none'];
DEFINE FIELD sync_direction ON enterprise_system_of_record_policies TYPE string DEFAULT 'read_only';
DEFINE FIELD conflict_policy ON enterprise_system_of_record_policies TYPE string DEFAULT 'defer_to_source_system';
DEFINE FIELD status ON enterprise_system_of_record_policies TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_system_of_record_policies TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_process_support_mappings SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_process_support_mappings TYPE record<tenants>;
DEFINE FIELD process_ref ON enterprise_process_support_mappings TYPE string;
DEFINE FIELD process_name ON enterprise_process_support_mappings TYPE string;
DEFINE FIELD bpmn_model_id ON enterprise_process_support_mappings TYPE option<record<bpmn_models>>;
DEFINE FIELD supporting_app_tool_ids ON enterprise_process_support_mappings TYPE array<record<enterprise_app_tool_catalog>> DEFAULT [];
DEFINE FIELD ai_role ON enterprise_process_support_mappings TYPE string DEFAULT 'assist_recommend_prepare';
DEFINE FIELD non_replacement_commitment ON enterprise_process_support_mappings TYPE bool DEFAULT true;
DEFINE FIELD status ON enterprise_process_support_mappings TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_process_support_mappings TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::register_enterprise_app_as_tool(
  $tenant_id: record<tenants>,
  $app_id: record<enterprise_discovered_business_apps>,
  $tool_key: string,
  $tool_name: string,
  $tool_category: string,
  $source_system: string,
  $supported_actions: array<string>,
  $read_actions: array<string>,
  $write_actions: array<string>,
  $execution_mode: string
) {
  RETURN CREATE enterprise_app_tool_catalog CONTENT {
    tenant_id: $tenant_id,
    app_id: $app_id,
    tool_key: $tool_key,
    tool_name: $tool_name,
    tool_category: $tool_category,
    source_system: $source_system,
    supported_actions: $supported_actions,
    read_actions: $read_actions,
    write_actions: $write_actions,
    requires_app_owner_approval: true,
    requires_human_confirmation: true,
    respects_source_of_record: true,
    execution_mode: $execution_mode,
    status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::request_enterprise_app_tool_action(
  $tenant_id: record<tenants>,
  $tool_id: record<enterprise_app_tool_catalog>,
  $requested_by_person_id: option<record<identity_persons>>,
  $action_key: string,
  $action_intent: string,
  $proposed_payload: object,
  $source_record_refs: array<string>,
  $decision_id: option<record<enterprise_decision_logs>>
) {
  LET $tool = SELECT * FROM ONLY $tool_id;
  IF $tool = NONE THEN { THROW 'enterprise_app_tool_not_found'; };
  IF $tool.respects_source_of_record != true THEN { THROW 'source_of_record_policy_required'; };

  RETURN CREATE enterprise_app_tool_action_requests CONTENT {
    tenant_id: $tenant_id,
    tool_id: $tool_id,
    app_id: $tool.app_id,
    requested_by_person_id: $requested_by_person_id,
    action_key: $action_key,
    action_intent: $action_intent,
    proposed_payload: $proposed_payload,
    source_record_refs: $source_record_refs,
    approval_status: 'pending_app_owner_review',
    execution_status: 'not_executed',
    decision_id: $decision_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::approve_enterprise_app_tool_action(
  $request_id: record<enterprise_app_tool_action_requests>,
  $approver_person_id: record<identity_persons>,
  $approval_notes: option<string>
) {
  LET $request = SELECT * FROM ONLY $request_id;
  IF $request = NONE THEN { THROW 'enterprise_app_tool_action_request_not_found'; };
  RETURN UPDATE $request_id SET approval_status = 'approved', approved_at = time::now();
};

DEFINE FUNCTION fn::mark_enterprise_app_tool_action_executed(
  $request_id: record<enterprise_app_tool_action_requests>,
  $execution_status: string
) {
  LET $request = SELECT * FROM ONLY $request_id;
  IF $request.approval_status != 'approved' THEN { THROW 'app_tool_action_requires_approval_before_execution'; };
  RETURN UPDATE $request_id SET execution_status = $execution_status, executed_at = time::now();
};

DEFINE FUNCTION fn::enterprise_app_tools_context($tenant_id: record<tenants>) {
  RETURN {
    tools: SELECT * FROM enterprise_app_tool_catalog WHERE tenant_id = $tenant_id AND status = 'active' ORDER BY tool_category, tool_name,
    action_requests: SELECT * FROM enterprise_app_tool_action_requests WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    source_of_record_policies: SELECT * FROM enterprise_system_of_record_policies WHERE tenant_id = $tenant_id AND status = 'active',
    process_support_mappings: SELECT * FROM enterprise_process_support_mappings WHERE tenant_id = $tenant_id AND status = 'active'
  };
};
