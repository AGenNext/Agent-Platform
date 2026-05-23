-- AGenNext Platform
-- 0074: Multimodal A2A handoff with mandatory capability checks
-- Purpose: extend A2A handoffs with multimodal context transfer, mandatory skill/tool/role checks before handoff, and governed remediation when the target agent is not capable.

DEFINE TABLE a2a_multimodal_context_packages SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_multimodal_context_packages TYPE record<tenants>;
DEFINE FIELD package_ref ON a2a_multimodal_context_packages TYPE string;
DEFINE FIELD workflow_ref ON a2a_multimodal_context_packages TYPE option<string>;
DEFINE FIELD task_ref ON a2a_multimodal_context_packages TYPE option<string>;
DEFINE FIELD package_summary ON a2a_multimodal_context_packages TYPE string;
DEFINE FIELD text_context_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD document_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD image_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD audio_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD video_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD tabular_data_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD graph_context_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD tool_trace_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD intermediate_output_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD evidence_refs ON a2a_multimodal_context_packages TYPE array<string> DEFAULT [];
DEFINE FIELD redaction_policy ON a2a_multimodal_context_packages TYPE object DEFAULT {};
DEFINE FIELD access_scope ON a2a_multimodal_context_packages TYPE object DEFAULT {};
DEFINE FIELD retention_policy_ref ON a2a_multimodal_context_packages TYPE option<string>;
DEFINE FIELD created_at ON a2a_multimodal_context_packages TYPE datetime DEFAULT time::now();
DEFINE INDEX a2a_multimodal_context_package_ref_unique ON a2a_multimodal_context_packages FIELDS package_ref UNIQUE;

DEFINE TABLE a2a_target_capability_checks SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_target_capability_checks TYPE record<tenants>;
DEFINE FIELD check_ref ON a2a_target_capability_checks TYPE string;
DEFINE FIELD source_agent_ref ON a2a_target_capability_checks TYPE string;
DEFINE FIELD target_agent_ref ON a2a_target_capability_checks TYPE string;
DEFINE FIELD context_package_id ON a2a_target_capability_checks TYPE option<record<a2a_multimodal_context_packages>>;
DEFINE FIELD required_skill_keys ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD required_tool_refs ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD required_role_keys ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD required_modalities ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD available_skill_keys ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD available_tool_refs ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD available_role_keys ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD available_modalities ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD missing_skills ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD missing_tools ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD missing_roles ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD missing_modalities ON a2a_target_capability_checks TYPE array<string> DEFAULT [];
DEFINE FIELD capability_status ON a2a_target_capability_checks TYPE string DEFAULT 'pending';
DEFINE FIELD remediation_strategy ON a2a_target_capability_checks TYPE string DEFAULT 'not_selected';
DEFINE FIELD created_at ON a2a_target_capability_checks TYPE datetime DEFAULT time::now();
DEFINE INDEX a2a_target_capability_check_ref_unique ON a2a_target_capability_checks FIELDS check_ref UNIQUE;

DEFINE TABLE a2a_capability_remediation_plans SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_capability_remediation_plans TYPE record<tenants>;
DEFINE FIELD check_id ON a2a_capability_remediation_plans TYPE record<a2a_target_capability_checks>;
DEFINE FIELD plan_ref ON a2a_capability_remediation_plans TYPE string;
DEFINE FIELD target_agent_ref ON a2a_capability_remediation_plans TYPE string;
DEFINE FIELD remediation_kind ON a2a_capability_remediation_plans TYPE string;
DEFINE FIELD skill_upgrade_requests ON a2a_capability_remediation_plans TYPE array<object> DEFAULT [];
DEFINE FIELD tool_approval_requests ON a2a_capability_remediation_plans TYPE array<object> DEFAULT [];
DEFINE FIELD role_assignment_requests ON a2a_capability_remediation_plans TYPE array<object> DEFAULT [];
DEFINE FIELD human_escalation_role ON a2a_capability_remediation_plans TYPE option<string>;
DEFINE FIELD human_escalation_reason ON a2a_capability_remediation_plans TYPE option<string>;
DEFINE FIELD approval_status ON a2a_capability_remediation_plans TYPE string DEFAULT 'pending_review';
DEFINE FIELD execution_status ON a2a_capability_remediation_plans TYPE string DEFAULT 'not_started';
DEFINE FIELD created_at ON a2a_capability_remediation_plans TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON a2a_capability_remediation_plans TYPE option<datetime>;
DEFINE INDEX a2a_capability_remediation_plan_ref_unique ON a2a_capability_remediation_plans FIELDS plan_ref UNIQUE;

DEFINE TABLE a2a_handoff_block_events SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_handoff_block_events TYPE record<tenants>;
DEFINE FIELD block_ref ON a2a_handoff_block_events TYPE string;
DEFINE FIELD check_id ON a2a_handoff_block_events TYPE record<a2a_target_capability_checks>;
DEFINE FIELD attempted_source_agent_ref ON a2a_handoff_block_events TYPE string;
DEFINE FIELD attempted_target_agent_ref ON a2a_handoff_block_events TYPE string;
DEFINE FIELD block_reason ON a2a_handoff_block_events TYPE string;
DEFINE FIELD missing_capabilities_summary ON a2a_handoff_block_events TYPE object DEFAULT {};
DEFINE FIELD recommended_next_action ON a2a_handoff_block_events TYPE string;
DEFINE FIELD created_at ON a2a_handoff_block_events TYPE datetime DEFAULT time::now();
DEFINE INDEX a2a_handoff_block_event_ref_unique ON a2a_handoff_block_events FIELDS block_ref UNIQUE;

DEFINE FUNCTION fn::create_a2a_multimodal_context_package(
  $tenant_id: record<tenants>,
  $workflow_ref: option<string>,
  $task_ref: option<string>,
  $package_summary: string,
  $text_context_refs: array<string>,
  $document_refs: array<string>,
  $image_refs: array<string>,
  $audio_refs: array<string>,
  $video_refs: array<string>,
  $tabular_data_refs: array<string>,
  $graph_context_refs: array<string>,
  $tool_trace_refs: array<string>,
  $intermediate_output_refs: array<string>,
  $evidence_refs: array<string>,
  $redaction_policy: object,
  $access_scope: object
) {
  RETURN CREATE a2a_multimodal_context_packages CONTENT {
    tenant_id: $tenant_id,
    package_ref: rand::uuid(),
    workflow_ref: $workflow_ref,
    task_ref: $task_ref,
    package_summary: $package_summary,
    text_context_refs: $text_context_refs,
    document_refs: $document_refs,
    image_refs: $image_refs,
    audio_refs: $audio_refs,
    video_refs: $video_refs,
    tabular_data_refs: $tabular_data_refs,
    graph_context_refs: $graph_context_refs,
    tool_trace_refs: $tool_trace_refs,
    intermediate_output_refs: $intermediate_output_refs,
    evidence_refs: $evidence_refs,
    redaction_policy: $redaction_policy,
    access_scope: $access_scope,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::check_a2a_target_capability(
  $tenant_id: record<tenants>,
  $source_agent_ref: string,
  $target_agent_ref: string,
  $context_package_id: option<record<a2a_multimodal_context_packages>>,
  $required_skill_keys: array<string>,
  $required_tool_refs: array<string>,
  $required_role_keys: array<string>,
  $required_modalities: array<string>,
  $available_skill_keys: array<string>,
  $available_tool_refs: array<string>,
  $available_role_keys: array<string>,
  $available_modalities: array<string>
) {
  LET $missing_skills = array::filter($required_skill_keys, |$skill| $skill NOTINSIDE $available_skill_keys);
  LET $missing_tools = array::filter($required_tool_refs, |$tool| $tool NOTINSIDE $available_tool_refs);
  LET $missing_roles = array::filter($required_role_keys, |$role| $role NOTINSIDE $available_role_keys);
  LET $missing_modalities = array::filter($required_modalities, |$modality| $modality NOTINSIDE $available_modalities);
  LET $capable = count($missing_skills) = 0 AND count($missing_tools) = 0 AND count($missing_roles) = 0 AND count($missing_modalities) = 0;

  RETURN CREATE a2a_target_capability_checks CONTENT {
    tenant_id: $tenant_id,
    check_ref: rand::uuid(),
    source_agent_ref: $source_agent_ref,
    target_agent_ref: $target_agent_ref,
    context_package_id: $context_package_id,
    required_skill_keys: $required_skill_keys,
    required_tool_refs: $required_tool_refs,
    required_role_keys: $required_role_keys,
    required_modalities: $required_modalities,
    available_skill_keys: $available_skill_keys,
    available_tool_refs: $available_tool_refs,
    available_role_keys: $available_role_keys,
    available_modalities: $available_modalities,
    missing_skills: $missing_skills,
    missing_tools: $missing_tools,
    missing_roles: $missing_roles,
    missing_modalities: $missing_modalities,
    capability_status: IF $capable THEN 'capable' ELSE 'not_capable' END,
    remediation_strategy: IF $capable THEN 'handoff_allowed' ELSE 'upgrade_or_human_required' END,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::create_a2a_remediation_plan(
  $tenant_id: record<tenants>,
  $check_id: record<a2a_target_capability_checks>,
  $remediation_kind: string,
  $skill_upgrade_requests: array<object>,
  $tool_approval_requests: array<object>,
  $role_assignment_requests: array<object>,
  $human_escalation_role: option<string>,
  $human_escalation_reason: option<string>
) {
  LET $check = SELECT * FROM ONLY $check_id;
  IF $check = NONE THEN { THROW 'a2a_capability_check_not_found'; };
  IF $check.capability_status = 'capable' THEN { THROW 'remediation_not_required_for_capable_agent'; };

  RETURN CREATE a2a_capability_remediation_plans CONTENT {
    tenant_id: $tenant_id,
    check_id: $check_id,
    plan_ref: rand::uuid(),
    target_agent_ref: $check.target_agent_ref,
    remediation_kind: $remediation_kind,
    skill_upgrade_requests: $skill_upgrade_requests,
    tool_approval_requests: $tool_approval_requests,
    role_assignment_requests: $role_assignment_requests,
    human_escalation_role: $human_escalation_role,
    human_escalation_reason: $human_escalation_reason,
    approval_status: 'pending_review',
    execution_status: 'not_started',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::create_capability_checked_a2a_handoff(
  $tenant_id: record<tenants>,
  $capability_check_id: record<a2a_target_capability_checks>,
  $handoff_reason: string,
  $handoff_summary: string,
  $previous_work_summary: string,
  $known_risks: array<object>,
  $open_questions: array<object>,
  $acceptance_criteria: array<object>,
  $created_by_person_id: option<record<identity_persons>>
) {
  LET $check = SELECT * FROM ONLY $capability_check_id;
  IF $check = NONE THEN { THROW 'a2a_capability_check_not_found'; };

  IF $check.capability_status != 'capable' THEN {
    CREATE a2a_handoff_block_events CONTENT {
      tenant_id: $tenant_id,
      block_ref: rand::uuid(),
      check_id: $capability_check_id,
      attempted_source_agent_ref: $check.source_agent_ref,
      attempted_target_agent_ref: $check.target_agent_ref,
      block_reason: 'target_agent_missing_required_capabilities',
      missing_capabilities_summary: {
        skills: $check.missing_skills,
        tools: $check.missing_tools,
        roles: $check.missing_roles,
        modalities: $check.missing_modalities
      },
      recommended_next_action: 'upgrade_target_agent_or_loop_in_human',
      created_at: time::now()
    };
    THROW 'target_agent_not_capable_upgrade_or_human_required_before_handoff';
  };

  LET $context = IF $check.context_package_id != NONE THEN SELECT * FROM ONLY $check.context_package_id ELSE NONE END;

  RETURN fn::create_a2a_agent_handoff(
    $tenant_id,
    $check.source_agent_ref,
    $check.target_agent_ref,
    IF $context != NONE THEN $context.workflow_ref ELSE NONE END,
    IF $context != NONE THEN $context.task_ref ELSE NONE END,
    $handoff_reason,
    $handoff_summary,
    $previous_work_summary,
    IF $context != NONE THEN $context.intermediate_output_refs ELSE [] END,
    IF $context != NONE THEN $context.evidence_refs ELSE [] END,
    $known_risks,
    $open_questions,
    $acceptance_criteria,
    $created_by_person_id
  );
};

DEFINE FUNCTION fn::multimodal_a2a_handoff_context($tenant_id: record<tenants>) {
  RETURN {
    context_packages: SELECT * FROM a2a_multimodal_context_packages WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    capability_checks: SELECT * FROM a2a_target_capability_checks WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    remediation_plans: SELECT * FROM a2a_capability_remediation_plans WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    blocked_handoffs: SELECT * FROM a2a_handoff_block_events WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    handoffs: SELECT * FROM a2a_agent_handoffs WHERE tenant_id = $tenant_id ORDER BY updated_at DESC
  };
};
