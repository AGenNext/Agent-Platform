-- AGenNext Platform
-- 0058: Enterprise decision log
-- Purpose: record every enterprise buying, evaluation, onboarding, agent/workspace, security, compliance, commercial, go-live, renewal, and future platform decision.

DEFINE TABLE enterprise_decision_logs SCHEMAFULL;
DEFINE FIELD account_id ON enterprise_decision_logs TYPE record<enterprise_accounts>;
DEFINE FIELD deal_id ON enterprise_decision_logs TYPE option<record<enterprise_deals>>;
DEFINE FIELD tenant_id ON enterprise_decision_logs TYPE option<record<tenants>>;
DEFINE FIELD workspace_id ON enterprise_decision_logs TYPE option<record<enterprise_workspaces>>;
DEFINE FIELD decision_ref ON enterprise_decision_logs TYPE string;
DEFINE FIELD decision_title ON enterprise_decision_logs TYPE string;
DEFINE FIELD decision_type ON enterprise_decision_logs TYPE string;
DEFINE FIELD lifecycle_phase ON enterprise_decision_logs TYPE string;
DEFINE FIELD decision_status ON enterprise_decision_logs TYPE string DEFAULT 'proposed';
DEFINE FIELD decision_summary ON enterprise_decision_logs TYPE string;
DEFINE FIELD options_considered ON enterprise_decision_logs TYPE array<object> DEFAULT [];
DEFINE FIELD selected_option ON enterprise_decision_logs TYPE option<object>;
DEFINE FIELD rationale ON enterprise_decision_logs TYPE option<string>;
DEFINE FIELD risks ON enterprise_decision_logs TYPE array<object> DEFAULT [];
DEFINE FIELD mitigations ON enterprise_decision_logs TYPE array<object> DEFAULT [];
DEFINE FIELD decision_owner_role ON enterprise_decision_logs TYPE string;
DEFINE FIELD decision_owner_person_id ON enterprise_decision_logs TYPE option<record<identity_persons>>;
DEFINE FIELD required_approver_roles ON enterprise_decision_logs TYPE array<string> DEFAULT [];
DEFINE FIELD evidence_refs ON enterprise_decision_logs TYPE array<string> DEFAULT [];
DEFINE FIELD related_resource_refs ON enterprise_decision_logs TYPE array<string> DEFAULT [];
DEFINE FIELD effective_at ON enterprise_decision_logs TYPE option<datetime>;
DEFINE FIELD review_at ON enterprise_decision_logs TYPE option<datetime>;
DEFINE FIELD supersedes_decision_id ON enterprise_decision_logs TYPE option<record<enterprise_decision_logs>>;
DEFINE FIELD created_at ON enterprise_decision_logs TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_decision_logs TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_decision_ref_unique ON enterprise_decision_logs FIELDS decision_ref UNIQUE;

DEFINE TABLE enterprise_decision_approvals SCHEMAFULL;
DEFINE FIELD decision_id ON enterprise_decision_approvals TYPE record<enterprise_decision_logs>;
DEFINE FIELD approver_person_id ON enterprise_decision_approvals TYPE option<record<identity_persons>>;
DEFINE FIELD approver_role ON enterprise_decision_approvals TYPE string;
DEFINE FIELD approval_status ON enterprise_decision_approvals TYPE string DEFAULT 'pending';
DEFINE FIELD approval_notes ON enterprise_decision_approvals TYPE option<string>;
DEFINE FIELD acknowledgement_text ON enterprise_decision_approvals TYPE option<string>;
DEFINE FIELD evidence_refs ON enterprise_decision_approvals TYPE array<string> DEFAULT [];
DEFINE FIELD decided_at ON enterprise_decision_approvals TYPE option<datetime>;
DEFINE FIELD created_at ON enterprise_decision_approvals TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_decision_comments SCHEMAFULL;
DEFINE FIELD decision_id ON enterprise_decision_comments TYPE record<enterprise_decision_logs>;
DEFINE FIELD author_person_id ON enterprise_decision_comments TYPE option<record<identity_persons>>;
DEFINE FIELD author_role ON enterprise_decision_comments TYPE string;
DEFINE FIELD comment_body ON enterprise_decision_comments TYPE string;
DEFINE FIELD created_at ON enterprise_decision_comments TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::record_enterprise_decision(
  $account_id: record<enterprise_accounts>,
  $deal_id: option<record<enterprise_deals>>,
  $tenant_id: option<record<tenants>>,
  $workspace_id: option<record<enterprise_workspaces>>,
  $decision_title: string,
  $decision_type: string,
  $lifecycle_phase: string,
  $decision_summary: string,
  $options_considered: array<object>,
  $selected_option: option<object>,
  $rationale: option<string>,
  $decision_owner_role: string,
  $decision_owner_person_id: option<record<identity_persons>>,
  $required_approver_roles: array<string>,
  $evidence_refs: array<string>,
  $related_resource_refs: array<string>,
  $review_at: option<datetime>
) {
  LET $decision = CREATE enterprise_decision_logs CONTENT {
    account_id: $account_id,
    deal_id: $deal_id,
    tenant_id: $tenant_id,
    workspace_id: $workspace_id,
    decision_ref: rand::uuid(),
    decision_title: $decision_title,
    decision_type: $decision_type,
    lifecycle_phase: $lifecycle_phase,
    decision_status: IF count($required_approver_roles) > 0 THEN 'pending_approval' ELSE 'accepted' END,
    decision_summary: $decision_summary,
    options_considered: $options_considered,
    selected_option: $selected_option,
    rationale: $rationale,
    decision_owner_role: $decision_owner_role,
    decision_owner_person_id: $decision_owner_person_id,
    required_approver_roles: $required_approver_roles,
    evidence_refs: $evidence_refs,
    related_resource_refs: $related_resource_refs,
    review_at: $review_at,
    created_at: time::now(),
    updated_at: time::now()
  };

  FOR $role IN $required_approver_roles {
    CREATE enterprise_decision_approvals CONTENT {
      decision_id: $decision.id,
      approver_role: $role,
      approval_status: 'pending',
      created_at: time::now()
    };
  };

  RETURN $decision;
};

DEFINE FUNCTION fn::approve_enterprise_decision(
  $decision_id: record<enterprise_decision_logs>,
  $approver_role: string,
  $approver_person_id: option<record<identity_persons>>,
  $approval_notes: option<string>,
  $acknowledgement_text: option<string>,
  $evidence_refs: array<string>
) {
  LET $decision = SELECT * FROM ONLY $decision_id;
  IF $decision = NONE THEN { THROW 'enterprise_decision_not_found'; };

  UPDATE enterprise_decision_approvals SET
    approver_person_id = $approver_person_id,
    approval_status = 'approved',
    approval_notes = $approval_notes,
    acknowledgement_text = $acknowledgement_text,
    evidence_refs = $evidence_refs,
    decided_at = time::now()
  WHERE decision_id = $decision_id AND approver_role = $approver_role;

  LET $pending = SELECT * FROM enterprise_decision_approvals WHERE decision_id = $decision_id AND approval_status != 'approved';
  IF count($pending) = 0 THEN {
    UPDATE $decision_id SET decision_status = 'accepted', effective_at = time::now(), updated_at = time::now();
  };

  RETURN SELECT * FROM ONLY $decision_id;
};

DEFINE FUNCTION fn::enterprise_decision_log_for_deal($deal_id: record<enterprise_deals>) {
  RETURN SELECT * FROM enterprise_decision_logs WHERE deal_id = $deal_id ORDER BY created_at DESC;
};

DEFINE FUNCTION fn::enterprise_decision_log_for_account($account_id: record<enterprise_accounts>) {
  RETURN SELECT * FROM enterprise_decision_logs WHERE account_id = $account_id ORDER BY created_at DESC;
};
