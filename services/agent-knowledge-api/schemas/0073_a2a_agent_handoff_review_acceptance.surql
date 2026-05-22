-- AGenNext Platform
-- 0073: A2A agent handoff with review-before-acceptance
-- Purpose: support agent-to-agent handoff where the receiving agent must review the previous agent's work, intermediate outputs, evidence, risks, and acceptance criteria before accepting ownership.

DEFINE TABLE a2a_agent_handoffs SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_agent_handoffs TYPE record<tenants>;
DEFINE FIELD handoff_ref ON a2a_agent_handoffs TYPE string;
DEFINE FIELD source_agent_ref ON a2a_agent_handoffs TYPE string;
DEFINE FIELD target_agent_ref ON a2a_agent_handoffs TYPE string;
DEFINE FIELD workflow_ref ON a2a_agent_handoffs TYPE option<string>;
DEFINE FIELD task_ref ON a2a_agent_handoffs TYPE option<string>;
DEFINE FIELD handoff_reason ON a2a_agent_handoffs TYPE string;
DEFINE FIELD handoff_summary ON a2a_agent_handoffs TYPE string;
DEFINE FIELD previous_work_summary ON a2a_agent_handoffs TYPE string;
DEFINE FIELD intermediate_output_refs ON a2a_agent_handoffs TYPE array<string> DEFAULT [];
DEFINE FIELD evidence_refs ON a2a_agent_handoffs TYPE array<string> DEFAULT [];
DEFINE FIELD known_risks ON a2a_agent_handoffs TYPE array<object> DEFAULT [];
DEFINE FIELD open_questions ON a2a_agent_handoffs TYPE array<object> DEFAULT [];
DEFINE FIELD acceptance_criteria ON a2a_agent_handoffs TYPE array<object> DEFAULT [];
DEFINE FIELD handoff_status ON a2a_agent_handoffs TYPE string DEFAULT 'pending_target_review';
DEFINE FIELD created_by_person_id ON a2a_agent_handoffs TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON a2a_agent_handoffs TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON a2a_agent_handoffs TYPE datetime DEFAULT time::now();
DEFINE FIELD accepted_at ON a2a_agent_handoffs TYPE option<datetime>;
DEFINE FIELD rejected_at ON a2a_agent_handoffs TYPE option<datetime>;
DEFINE INDEX a2a_agent_handoff_ref_unique ON a2a_agent_handoffs FIELDS handoff_ref UNIQUE;

DEFINE TABLE a2a_handoff_reviews SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_handoff_reviews TYPE record<tenants>;
DEFINE FIELD handoff_id ON a2a_handoff_reviews TYPE record<a2a_agent_handoffs>;
DEFINE FIELD reviewer_agent_ref ON a2a_handoff_reviews TYPE string;
DEFINE FIELD reviewer_person_id ON a2a_handoff_reviews TYPE option<record<identity_persons>>;
DEFINE FIELD review_status ON a2a_handoff_reviews TYPE string DEFAULT 'in_review';
DEFINE FIELD review_summary ON a2a_handoff_reviews TYPE option<string>;
DEFINE FIELD accepted_outputs ON a2a_handoff_reviews TYPE array<string> DEFAULT [];
DEFINE FIELD rejected_outputs ON a2a_handoff_reviews TYPE array<object> DEFAULT [];
DEFINE FIELD missing_context ON a2a_handoff_reviews TYPE array<object> DEFAULT [];
DEFINE FIELD required_corrections ON a2a_handoff_reviews TYPE array<object> DEFAULT [];
DEFINE FIELD confidence_score ON a2a_handoff_reviews TYPE number DEFAULT 0;
DEFINE FIELD decision ON a2a_handoff_reviews TYPE string DEFAULT 'undecided';
DEFINE FIELD created_at ON a2a_handoff_reviews TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON a2a_handoff_reviews TYPE option<datetime>;

DEFINE TABLE a2a_handoff_acceptance_logs SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_handoff_acceptance_logs TYPE record<tenants>;
DEFINE FIELD handoff_id ON a2a_handoff_acceptance_logs TYPE record<a2a_agent_handoffs>;
DEFINE FIELD review_id ON a2a_handoff_acceptance_logs TYPE record<a2a_handoff_reviews>;
DEFINE FIELD accepted_by_agent_ref ON a2a_handoff_acceptance_logs TYPE string;
DEFINE FIELD accepted_by_person_id ON a2a_handoff_acceptance_logs TYPE option<record<identity_persons>>;
DEFINE FIELD acceptance_statement ON a2a_handoff_acceptance_logs TYPE string;
DEFINE FIELD responsibility_scope ON a2a_handoff_acceptance_logs TYPE object DEFAULT {};
DEFINE FIELD inherited_context_refs ON a2a_handoff_acceptance_logs TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON a2a_handoff_acceptance_logs TYPE datetime DEFAULT time::now();

DEFINE TABLE a2a_handoff_rework_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_handoff_rework_requests TYPE record<tenants>;
DEFINE FIELD handoff_id ON a2a_handoff_rework_requests TYPE record<a2a_agent_handoffs>;
DEFINE FIELD review_id ON a2a_handoff_rework_requests TYPE record<a2a_handoff_reviews>;
DEFINE FIELD requested_by_agent_ref ON a2a_handoff_rework_requests TYPE string;
DEFINE FIELD target_agent_ref ON a2a_handoff_rework_requests TYPE string;
DEFINE FIELD rework_reason ON a2a_handoff_rework_requests TYPE string;
DEFINE FIELD required_changes ON a2a_handoff_rework_requests TYPE array<object> DEFAULT [];
DEFINE FIELD status ON a2a_handoff_rework_requests TYPE string DEFAULT 'open';
DEFINE FIELD created_at ON a2a_handoff_rework_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD resolved_at ON a2a_handoff_rework_requests TYPE option<datetime>;

DEFINE FUNCTION fn::create_a2a_agent_handoff(
  $tenant_id: record<tenants>,
  $source_agent_ref: string,
  $target_agent_ref: string,
  $workflow_ref: option<string>,
  $task_ref: option<string>,
  $handoff_reason: string,
  $handoff_summary: string,
  $previous_work_summary: string,
  $intermediate_output_refs: array<string>,
  $evidence_refs: array<string>,
  $known_risks: array<object>,
  $open_questions: array<object>,
  $acceptance_criteria: array<object>,
  $created_by_person_id: option<record<identity_persons>>
) {
  RETURN CREATE a2a_agent_handoffs CONTENT {
    tenant_id: $tenant_id,
    handoff_ref: rand::uuid(),
    source_agent_ref: $source_agent_ref,
    target_agent_ref: $target_agent_ref,
    workflow_ref: $workflow_ref,
    task_ref: $task_ref,
    handoff_reason: $handoff_reason,
    handoff_summary: $handoff_summary,
    previous_work_summary: $previous_work_summary,
    intermediate_output_refs: $intermediate_output_refs,
    evidence_refs: $evidence_refs,
    known_risks: $known_risks,
    open_questions: $open_questions,
    acceptance_criteria: $acceptance_criteria,
    handoff_status: 'pending_target_review',
    created_by_person_id: $created_by_person_id,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::review_a2a_agent_handoff(
  $tenant_id: record<tenants>,
  $handoff_id: record<a2a_agent_handoffs>,
  $reviewer_agent_ref: string,
  $reviewer_person_id: option<record<identity_persons>>,
  $review_summary: option<string>,
  $accepted_outputs: array<string>,
  $rejected_outputs: array<object>,
  $missing_context: array<object>,
  $required_corrections: array<object>,
  $confidence_score: number,
  $decision: string
) {
  LET $handoff = SELECT * FROM ONLY $handoff_id;
  IF $handoff = NONE THEN { THROW 'a2a_handoff_not_found'; };
  IF $handoff.handoff_status != 'pending_target_review' THEN { THROW 'a2a_handoff_not_pending_review'; };
  IF $reviewer_agent_ref != $handoff.target_agent_ref THEN { THROW 'only_target_agent_can_review_handoff'; };

  LET $review = CREATE a2a_handoff_reviews CONTENT {
    tenant_id: $tenant_id,
    handoff_id: $handoff_id,
    reviewer_agent_ref: $reviewer_agent_ref,
    reviewer_person_id: $reviewer_person_id,
    review_status: 'completed',
    review_summary: $review_summary,
    accepted_outputs: $accepted_outputs,
    rejected_outputs: $rejected_outputs,
    missing_context: $missing_context,
    required_corrections: $required_corrections,
    confidence_score: $confidence_score,
    decision: $decision,
    created_at: time::now(),
    completed_at: time::now()
  };

  IF $decision = 'accept' THEN {
    UPDATE $handoff_id SET handoff_status = 'reviewed_ready_for_acceptance', updated_at = time::now();
  } ELSE {
    UPDATE $handoff_id SET handoff_status = 'rework_requested', updated_at = time::now();
  };

  RETURN $review;
};

DEFINE FUNCTION fn::accept_a2a_agent_handoff(
  $handoff_id: record<a2a_agent_handoffs>,
  $review_id: record<a2a_handoff_reviews>,
  $accepted_by_agent_ref: string,
  $accepted_by_person_id: option<record<identity_persons>>,
  $acceptance_statement: string,
  $responsibility_scope: object,
  $inherited_context_refs: array<string>
) {
  LET $handoff = SELECT * FROM ONLY $handoff_id;
  LET $review = SELECT * FROM ONLY $review_id;
  IF $handoff = NONE THEN { THROW 'a2a_handoff_not_found'; };
  IF $review = NONE THEN { THROW 'a2a_handoff_review_not_found'; };
  IF $handoff.handoff_status != 'reviewed_ready_for_acceptance' THEN { THROW 'handoff_must_be_reviewed_before_acceptance'; };
  IF $accepted_by_agent_ref != $handoff.target_agent_ref THEN { THROW 'only_target_agent_can_accept_handoff'; };
  IF $review.decision != 'accept' THEN { THROW 'review_decision_must_be_accept'; };

  UPDATE $handoff_id SET handoff_status = 'accepted', accepted_at = time::now(), updated_at = time::now();

  RETURN CREATE a2a_handoff_acceptance_logs CONTENT {
    tenant_id: $handoff.tenant_id,
    handoff_id: $handoff_id,
    review_id: $review_id,
    accepted_by_agent_ref: $accepted_by_agent_ref,
    accepted_by_person_id: $accepted_by_person_id,
    acceptance_statement: $acceptance_statement,
    responsibility_scope: $responsibility_scope,
    inherited_context_refs: $inherited_context_refs,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::request_a2a_handoff_rework(
  $handoff_id: record<a2a_agent_handoffs>,
  $review_id: record<a2a_handoff_reviews>,
  $requested_by_agent_ref: string,
  $rework_reason: string,
  $required_changes: array<object>
) {
  LET $handoff = SELECT * FROM ONLY $handoff_id;
  IF $handoff = NONE THEN { THROW 'a2a_handoff_not_found'; };
  UPDATE $handoff_id SET handoff_status = 'rework_requested', updated_at = time::now();

  RETURN CREATE a2a_handoff_rework_requests CONTENT {
    tenant_id: $handoff.tenant_id,
    handoff_id: $handoff_id,
    review_id: $review_id,
    requested_by_agent_ref: $requested_by_agent_ref,
    target_agent_ref: $handoff.source_agent_ref,
    rework_reason: $rework_reason,
    required_changes: $required_changes,
    status: 'open',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::a2a_handoff_context($tenant_id: record<tenants>) {
  RETURN {
    handoffs: SELECT * FROM a2a_agent_handoffs WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    reviews: SELECT * FROM a2a_handoff_reviews WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    acceptance_logs: SELECT * FROM a2a_handoff_acceptance_logs WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    rework_requests: SELECT * FROM a2a_handoff_rework_requests WHERE tenant_id = $tenant_id AND status != 'resolved' ORDER BY created_at DESC
  };
};
