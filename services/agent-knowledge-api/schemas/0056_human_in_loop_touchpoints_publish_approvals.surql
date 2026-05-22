-- AGenNext Platform
-- 0056: Human-in-the-loop touchpoint planner and production publishing approvals
-- Purpose: platform suggests where humans should review/approve, users can accept or modify, and production publishing always requires explicit documented acknowledgement.

DEFINE TABLE human_touchpoint_policies SCHEMAFULL;
DEFINE FIELD policy_key ON human_touchpoint_policies TYPE string;
DEFINE FIELD audience_kind ON human_touchpoint_policies TYPE string;
DEFINE FIELD flow_kind ON human_touchpoint_policies TYPE string;
DEFINE FIELD risk_thresholds ON human_touchpoint_policies TYPE object DEFAULT {};
DEFINE FIELD default_touchpoints ON human_touchpoint_policies TYPE array<object> DEFAULT [];
DEFINE FIELD mandatory_touchpoints ON human_touchpoint_policies TYPE array<string> DEFAULT [];
DEFINE FIELD editable_touchpoints ON human_touchpoint_policies TYPE array<string> DEFAULT [];
DEFINE FIELD active ON human_touchpoint_policies TYPE bool DEFAULT true;
DEFINE FIELD created_at ON human_touchpoint_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX human_touchpoint_policy_unique ON human_touchpoint_policies FIELDS policy_key UNIQUE;

DEFINE TABLE human_touchpoint_plans SCHEMAFULL;
DEFINE FIELD plan_ref ON human_touchpoint_plans TYPE string;
DEFINE FIELD person_id ON human_touchpoint_plans TYPE record<identity_persons>;
DEFINE FIELD tenant_id ON human_touchpoint_plans TYPE option<record<tenants>>;
DEFINE FIELD flow_ref ON human_touchpoint_plans TYPE string;
DEFINE FIELD flow_kind ON human_touchpoint_plans TYPE string;
DEFINE FIELD audience_kind ON human_touchpoint_plans TYPE string;
DEFINE FIELD suggested_touchpoints ON human_touchpoint_plans TYPE array<object> DEFAULT [];
DEFINE FIELD accepted_touchpoints ON human_touchpoint_plans TYPE array<object> DEFAULT [];
DEFINE FIELD user_modifications ON human_touchpoint_plans TYPE array<object> DEFAULT [];
DEFINE FIELD status ON human_touchpoint_plans TYPE string DEFAULT 'suggested';
DEFINE FIELD created_at ON human_touchpoint_plans TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON human_touchpoint_plans TYPE datetime DEFAULT time::now();
DEFINE INDEX human_touchpoint_plan_ref_unique ON human_touchpoint_plans FIELDS plan_ref UNIQUE;

DEFINE TABLE human_touchpoint_decisions SCHEMAFULL;
DEFINE FIELD plan_id ON human_touchpoint_decisions TYPE record<human_touchpoint_plans>;
DEFINE FIELD touchpoint_key ON human_touchpoint_decisions TYPE string;
DEFINE FIELD actor_person_id ON human_touchpoint_decisions TYPE record<identity_persons>;
DEFINE FIELD decision ON human_touchpoint_decisions TYPE string;
DEFINE FIELD notes ON human_touchpoint_decisions TYPE option<string>;
DEFINE FIELD evidence_refs ON human_touchpoint_decisions TYPE array<string> DEFAULT [];
DEFINE FIELD decided_at ON human_touchpoint_decisions TYPE datetime DEFAULT time::now();

DEFINE TABLE production_publish_approval_requests SCHEMAFULL;
DEFINE FIELD request_ref ON production_publish_approval_requests TYPE string;
DEFINE FIELD person_id ON production_publish_approval_requests TYPE record<identity_persons>;
DEFINE FIELD tenant_id ON production_publish_approval_requests TYPE option<record<tenants>>;
DEFINE FIELD resource_ref ON production_publish_approval_requests TYPE string;
DEFINE FIELD publish_target ON production_publish_approval_requests TYPE string;
DEFINE FIELD risk_summary ON production_publish_approval_requests TYPE object DEFAULT {};
DEFINE FIELD approval_status ON production_publish_approval_requests TYPE string DEFAULT 'pending';
DEFINE FIELD required_acknowledgement_text ON production_publish_approval_requests TYPE string;
DEFINE FIELD created_at ON production_publish_approval_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD decided_at ON production_publish_approval_requests TYPE option<datetime>;
DEFINE INDEX production_publish_approval_ref_unique ON production_publish_approval_requests FIELDS request_ref UNIQUE;

DEFINE TABLE production_publish_acknowledgements SCHEMAFULL;
DEFINE FIELD approval_request_id ON production_publish_acknowledgements TYPE record<production_publish_approval_requests>;
DEFINE FIELD actor_person_id ON production_publish_acknowledgements TYPE record<identity_persons>;
DEFINE FIELD acknowledgement_text ON production_publish_acknowledgements TYPE string;
DEFINE FIELD explicit_acceptance ON production_publish_acknowledgements TYPE bool DEFAULT false;
DEFINE FIELD ip_context ON production_publish_acknowledgements TYPE object DEFAULT {};
DEFINE FIELD evidence_refs ON production_publish_acknowledgements TYPE array<string> DEFAULT [];
DEFINE FIELD acknowledged_at ON production_publish_acknowledgements TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::suggest_human_touchpoints(
  $person_id: record<identity_persons>,
  $tenant_id: option<record<tenants>>,
  $flow_ref: string,
  $flow_kind: string,
  $audience_kind: string,
  $risk_context: object
) {
  LET $policy = SELECT * FROM ONLY human_touchpoint_policies WHERE flow_kind = $flow_kind AND audience_kind = $audience_kind AND active = true LIMIT 1;
  LET $default_touchpoints = IF $policy != NONE THEN $policy.default_touchpoints ELSE [
    { key: 'review_generated_output', label: 'Review generated output', required: true, editable: false },
    { key: 'confirm_external_action', label: 'Confirm external action', required: true, editable: false }
  ] END;

  RETURN CREATE human_touchpoint_plans CONTENT {
    plan_ref: rand::uuid(),
    person_id: $person_id,
    tenant_id: $tenant_id,
    flow_ref: $flow_ref,
    flow_kind: $flow_kind,
    audience_kind: $audience_kind,
    suggested_touchpoints: $default_touchpoints,
    accepted_touchpoints: [],
    user_modifications: [],
    status: 'suggested',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::accept_or_modify_human_touchpoints(
  $plan_id: record<human_touchpoint_plans>,
  $accepted_touchpoints: array<object>,
  $user_modifications: array<object>
) {
  LET $plan = SELECT * FROM ONLY $plan_id;
  IF $plan = NONE THEN { THROW 'human_touchpoint_plan_not_found'; };

  RETURN UPDATE $plan_id SET
    accepted_touchpoints = $accepted_touchpoints,
    user_modifications = $user_modifications,
    status = 'accepted_or_modified',
    updated_at = time::now();
};

DEFINE FUNCTION fn::record_human_touchpoint_decision(
  $plan_id: record<human_touchpoint_plans>,
  $touchpoint_key: string,
  $actor_person_id: record<identity_persons>,
  $decision: string,
  $notes: option<string>,
  $evidence_refs: array<string>
) {
  RETURN CREATE human_touchpoint_decisions CONTENT {
    plan_id: $plan_id,
    touchpoint_key: $touchpoint_key,
    actor_person_id: $actor_person_id,
    decision: $decision,
    notes: $notes,
    evidence_refs: $evidence_refs,
    decided_at: time::now()
  };
};

DEFINE FUNCTION fn::create_production_publish_approval_request(
  $person_id: record<identity_persons>,
  $tenant_id: option<record<tenants>>,
  $resource_ref: string,
  $publish_target: string,
  $risk_summary: object
) {
  IF $publish_target = 'sandbox' THEN { THROW 'production_publish_approval_not_required_for_sandbox'; };

  RETURN CREATE production_publish_approval_requests CONTENT {
    request_ref: rand::uuid(),
    person_id: $person_id,
    tenant_id: $tenant_id,
    resource_ref: $resource_ref,
    publish_target: $publish_target,
    risk_summary: $risk_summary,
    approval_status: 'pending',
    required_acknowledgement_text: 'I understand this action will publish to a production or public target. I confirm I have reviewed the content, risks, data exposure, permissions, and external actions, and I approve publishing.',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::acknowledge_production_publish_approval(
  $approval_request_id: record<production_publish_approval_requests>,
  $actor_person_id: record<identity_persons>,
  $acknowledgement_text: string,
  $explicit_acceptance: bool,
  $ip_context: object,
  $evidence_refs: array<string>
) {
  LET $request = SELECT * FROM ONLY $approval_request_id;
  IF $request = NONE THEN { THROW 'production_publish_approval_request_not_found'; };
  IF $explicit_acceptance != true THEN { THROW 'explicit_acknowledgement_required'; };
  IF $acknowledgement_text != $request.required_acknowledgement_text THEN { THROW 'acknowledgement_text_mismatch'; };

  CREATE production_publish_acknowledgements CONTENT {
    approval_request_id: $approval_request_id,
    actor_person_id: $actor_person_id,
    acknowledgement_text: $acknowledgement_text,
    explicit_acceptance: true,
    ip_context: $ip_context,
    evidence_refs: $evidence_refs,
    acknowledged_at: time::now()
  };

  RETURN UPDATE $approval_request_id SET approval_status = 'approved', decided_at = time::now();
};

DEFINE FUNCTION fn::require_production_publish_approval(
  $person_id: record<identity_persons>,
  $tenant_id: option<record<tenants>>,
  $resource_ref: string,
  $publish_target: string
) {
  IF $publish_target = 'sandbox' THEN { RETURN { decision: 'allow', reason: 'sandbox_does_not_require_production_approval' }; };

  LET $approved = SELECT * FROM production_publish_approval_requests
    WHERE person_id = $person_id
      AND resource_ref = $resource_ref
      AND publish_target = $publish_target
      AND approval_status = 'approved'
      AND (tenant_id = $tenant_id OR tenant_id = NONE)
    ORDER BY decided_at DESC LIMIT 1;

  IF count($approved) = 0 THEN { THROW 'explicit_human_approval_and_acknowledgement_required_for_production_publish'; };

  RETURN { decision: 'allow', reason: 'explicit_human_approval_documented', approval: $approved[0] };
};

CREATE human_touchpoint_policies:small_business_simple_flow CONTENT {
  policy_key: 'small_business_simple_flow',
  audience_kind: 'non_technical_small_business_owner',
  flow_kind: 'small_business_marketplace_app',
  risk_thresholds: { external_action: true, paid_spend: true, public_publish: true },
  default_touchpoints: [
    { key: 'review_draft', label: 'Review draft before use', required: true, editable: false },
    { key: 'confirm_external_action', label: 'Confirm before any external account action', required: true, editable: false },
    { key: 'approve_paid_spend', label: 'Approve any paid advertising spend', required: true, editable: false },
    { key: 'approve_public_publish', label: 'Approve public or production publishing', required: true, editable: false }
  ],
  mandatory_touchpoints: ['review_draft', 'confirm_external_action', 'approve_public_publish'],
  editable_touchpoints: [],
  active: true,
  created_at: time::now()
};
