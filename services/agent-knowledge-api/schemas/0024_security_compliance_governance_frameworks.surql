DEFINE TABLE governance_frameworks SCHEMAFULL;
DEFINE FIELD tenant_id ON governance_frameworks TYPE option<record<tenants>>;
DEFINE FIELD key ON governance_frameworks TYPE string;
DEFINE FIELD name ON governance_frameworks TYPE string;
DEFINE FIELD framework_kind ON governance_frameworks TYPE string;
DEFINE FIELD version ON governance_frameworks TYPE string;
DEFINE FIELD authority_uri ON governance_frameworks TYPE option<string>;
DEFINE FIELD scope ON governance_frameworks TYPE object DEFAULT {};
DEFINE FIELD status ON governance_frameworks TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON governance_frameworks TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON governance_frameworks TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:GovernanceFramework'];
DEFINE FIELD source_grounding_refs ON governance_frameworks TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON governance_frameworks TYPE datetime DEFAULT time::now();
DEFINE INDEX governance_frameworks_key_unique ON governance_frameworks FIELDS tenant_id, key, version UNIQUE;

DEFINE TABLE governance_controls SCHEMAFULL;
DEFINE FIELD tenant_id ON governance_controls TYPE option<record<tenants>>;
DEFINE FIELD framework_id ON governance_controls TYPE record<governance_frameworks>;
DEFINE FIELD key ON governance_controls TYPE string;
DEFINE FIELD name ON governance_controls TYPE string;
DEFINE FIELD control_family ON governance_controls TYPE string;
DEFINE FIELD control_text ON governance_controls TYPE string;
DEFINE FIELD severity ON governance_controls TYPE string DEFAULT 'medium';
DEFINE FIELD mandatory ON governance_controls TYPE bool DEFAULT true;
DEFINE FIELD evidence_requirements ON governance_controls TYPE array<object> DEFAULT [];
DEFINE FIELD automation_level ON governance_controls TYPE string DEFAULT 'semi_automated';
DEFINE FIELD jsonld_context ON governance_controls TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON governance_controls TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:GovernanceControl'];
DEFINE FIELD created_at ON governance_controls TYPE datetime DEFAULT time::now();
DEFINE INDEX governance_controls_key_unique ON governance_controls FIELDS framework_id, key UNIQUE;

DEFINE TABLE control_mappings SCHEMAFULL;
DEFINE FIELD tenant_id ON control_mappings TYPE option<record<tenants>>;
DEFINE FIELD source_control_id ON control_mappings TYPE record<governance_controls>;
DEFINE FIELD target_control_id ON control_mappings TYPE record<governance_controls>;
DEFINE FIELD mapping_kind ON control_mappings TYPE string DEFAULT 'related';
DEFINE FIELD confidence ON control_mappings TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD rationale ON control_mappings TYPE string;
DEFINE FIELD jsonld_context ON control_mappings TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON control_mappings TYPE array<string> DEFAULT ['schema:Action', 'agx:ControlMapping'];
DEFINE FIELD created_at ON control_mappings TYPE datetime DEFAULT time::now();

DEFINE TABLE compliance_scopes SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_scopes TYPE option<record<tenants>>;
DEFINE FIELD key ON compliance_scopes TYPE string;
DEFINE FIELD name ON compliance_scopes TYPE string;
DEFINE FIELD application_id ON compliance_scopes TYPE option<record<applications>>;
DEFINE FIELD project_id ON compliance_scopes TYPE option<record<projects>>;
DEFINE FIELD milestone_id ON compliance_scopes TYPE option<record<milestones>>;
DEFINE FIELD task_id ON compliance_scopes TYPE option<record<tasks>>;
DEFINE FIELD risk_level ON compliance_scopes TYPE string DEFAULT 'medium';
DEFINE FIELD data_classification ON compliance_scopes TYPE string DEFAULT 'internal';
DEFINE FIELD applicable_framework_ids ON compliance_scopes TYPE array<record<governance_frameworks>> DEFAULT [];
DEFINE FIELD status ON compliance_scopes TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON compliance_scopes TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_scopes TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ComplianceScope'];
DEFINE FIELD created_at ON compliance_scopes TYPE datetime DEFAULT time::now();
DEFINE INDEX compliance_scopes_key_unique ON compliance_scopes FIELDS tenant_id, key UNIQUE;

DEFINE TABLE control_assessments SCHEMAFULL;
DEFINE FIELD tenant_id ON control_assessments TYPE option<record<tenants>>;
DEFINE FIELD compliance_scope_id ON control_assessments TYPE record<compliance_scopes>;
DEFINE FIELD control_id ON control_assessments TYPE record<governance_controls>;
DEFINE FIELD assessor_id ON control_assessments TYPE string;
DEFINE FIELD assessment_kind ON control_assessments TYPE string DEFAULT 'automated';
DEFINE FIELD status ON control_assessments TYPE string DEFAULT 'not_assessed';
DEFINE FIELD score ON control_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD findings ON control_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD evidence_ids ON control_assessments TYPE array<record> DEFAULT [];
DEFINE FIELD remediation_required ON control_assessments TYPE bool DEFAULT false;
DEFINE FIELD remediation_plan ON control_assessments TYPE option<object>;
DEFINE FIELD assessed_at ON control_assessments TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON control_assessments TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON control_assessments TYPE array<string> DEFAULT ['schema:ReviewAction', 'agx:ControlAssessment'];

DEFINE TABLE compliance_audit_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_audit_runs TYPE option<record<tenants>>;
DEFINE FIELD compliance_scope_id ON compliance_audit_runs TYPE record<compliance_scopes>;
DEFINE FIELD framework_ids ON compliance_audit_runs TYPE array<record<governance_frameworks>> DEFAULT [];
DEFINE FIELD auditor_id ON compliance_audit_runs TYPE string;
DEFINE FIELD status ON compliance_audit_runs TYPE string DEFAULT 'running';
DEFINE FIELD aggregate_score ON compliance_audit_runs TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD passed ON compliance_audit_runs TYPE option<bool>;
DEFINE FIELD blocker_count ON compliance_audit_runs TYPE int DEFAULT 0;
DEFINE FIELD observation_run_id ON compliance_audit_runs TYPE option<record<observation_runs>>;
DEFINE FIELD decision_log_id ON compliance_audit_runs TYPE option<record<decision_context_logs>>;
DEFINE FIELD started_at ON compliance_audit_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON compliance_audit_runs TYPE option<datetime>;
DEFINE FIELD jsonld_context ON compliance_audit_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_audit_runs TYPE array<string> DEFAULT ['schema:Action', 'agx:ComplianceAuditRun'];

DEFINE TABLE compliance_gates SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_gates TYPE option<record<tenants>>;
DEFINE FIELD key ON compliance_gates TYPE string;
DEFINE FIELD name ON compliance_gates TYPE string;
DEFINE FIELD min_aggregate_score ON compliance_gates TYPE number DEFAULT 0.85 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD block_on_critical_failure ON compliance_gates TYPE bool DEFAULT true;
DEFINE FIELD require_human_approval ON compliance_gates TYPE bool DEFAULT true;
DEFINE FIELD required_framework_ids ON compliance_gates TYPE array<record<governance_frameworks>> DEFAULT [];
DEFINE FIELD enabled ON compliance_gates TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON compliance_gates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_gates TYPE array<string> DEFAULT ['schema:Action', 'agx:ComplianceGate'];
DEFINE FIELD created_at ON compliance_gates TYPE datetime DEFAULT time::now();
DEFINE INDEX compliance_gates_key_unique ON compliance_gates FIELDS tenant_id, key UNIQUE;

DEFINE TABLE compliance_gate_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_gate_decisions TYPE option<record<tenants>>;
DEFINE FIELD compliance_gate_id ON compliance_gate_decisions TYPE record<compliance_gates>;
DEFINE FIELD audit_run_id ON compliance_gate_decisions TYPE record<compliance_audit_runs>;
DEFINE FIELD decision ON compliance_gate_decisions TYPE string;
DEFINE FIELD reason ON compliance_gate_decisions TYPE string;
DEFINE FIELD human_approval_required ON compliance_gate_decisions TYPE bool DEFAULT false;
DEFINE FIELD human_response_status ON compliance_gate_decisions TYPE string DEFAULT 'not_required';
DEFINE FIELD decision_log_id ON compliance_gate_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON compliance_gate_decisions TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON compliance_gate_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_gate_decisions TYPE array<string> DEFAULT ['schema:Action', 'agx:ComplianceGateDecision'];

UPSERT governance_frameworks:iso_27001_2022 CONTENT { tenant_id: NONE, key: 'iso_27001', name: 'ISO/IEC 27001', framework_kind: 'security', version: '2022', authority_uri: 'https://www.iso.org/standard/27001', scope: { domain: 'information_security_management' }, status: 'active', source_grounding_refs: ['iso:27001:2022'] };
UPSERT governance_frameworks:soc2_2022 CONTENT { tenant_id: NONE, key: 'soc2', name: 'SOC 2 Trust Services Criteria', framework_kind: 'security_compliance', version: '2022', authority_uri: 'https://www.aicpa-cima.com/resources/landing/system-and-organization-controls-soc-suite-of-services', scope: { domain: 'trust_services' }, status: 'active', source_grounding_refs: ['aicpa:soc2'] };
UPSERT governance_frameworks:nist_ai_rmf_1_0 CONTENT { tenant_id: NONE, key: 'nist_ai_rmf', name: 'NIST AI Risk Management Framework', framework_kind: 'ai_governance', version: '1.0', authority_uri: 'https://www.nist.gov/itl/ai-risk-management-framework', scope: { domain: 'ai_risk_management' }, status: 'active', source_grounding_refs: ['nist:ai-rmf:1.0'] };
UPSERT governance_frameworks:owasp_llm_2025 CONTENT { tenant_id: NONE, key: 'owasp_llm', name: 'OWASP Top 10 for LLM Applications', framework_kind: 'application_security', version: '2025', authority_uri: 'https://owasp.org/www-project-top-10-for-large-language-model-applications/', scope: { domain: 'llm_application_security' }, status: 'active', source_grounding_refs: ['owasp:llm-top-10'] };
UPSERT governance_frameworks:gdpr_2016 CONTENT { tenant_id: NONE, key: 'gdpr', name: 'General Data Protection Regulation', framework_kind: 'privacy', version: '2016', authority_uri: 'https://gdpr.eu/', scope: { domain: 'privacy_data_protection' }, status: 'active', source_grounding_refs: ['gdpr:2016'] };

UPSERT compliance_gates:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default Compliance Gate', min_aggregate_score: 0.85, block_on_critical_failure: true, require_human_approval: true, required_framework_ids: [], enabled: true };

DEFINE FUNCTION fn::create_governance_framework($tenant_id, $key, $name, $framework_kind, $version, $authority_uri, $scope, $source_grounding_refs) {
  RETURN CREATE governance_frameworks CONTENT { tenant_id: $tenant_id, key: $key, name: $name, framework_kind: $framework_kind, version: $version, authority_uri: $authority_uri, scope: $scope, status: 'active', source_grounding_refs: $source_grounding_refs, created_at: time::now() };
};

DEFINE FUNCTION fn::add_governance_control($tenant_id, $framework_id, $key, $name, $control_family, $control_text, $severity, $mandatory, $evidence_requirements, $automation_level) {
  LET $framework = SELECT * FROM $framework_id;
  IF count($framework) = 0 THEN { THROW 'governance_framework_not_found'; };
  RETURN CREATE governance_controls CONTENT { tenant_id: $tenant_id, framework_id: $framework_id, key: $key, name: $name, control_family: $control_family, control_text: $control_text, severity: $severity, mandatory: $mandatory, evidence_requirements: $evidence_requirements, automation_level: $automation_level, created_at: time::now() };
};

DEFINE FUNCTION fn::create_compliance_scope($tenant_id, $key, $name, $application_id, $project_id, $milestone_id, $task_id, $risk_level, $data_classification, $applicable_framework_ids) {
  RETURN CREATE compliance_scopes CONTENT { tenant_id: $tenant_id, key: $key, name: $name, application_id: $application_id, project_id: $project_id, milestone_id: $milestone_id, task_id: $task_id, risk_level: $risk_level, data_classification: $data_classification, applicable_framework_ids: $applicable_framework_ids, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::map_governance_controls($tenant_id, $source_control_id, $target_control_id, $mapping_kind, $confidence, $rationale) {
  LET $source = SELECT * FROM $source_control_id;
  LET $target = SELECT * FROM $target_control_id;
  IF count($source) = 0 OR count($target) = 0 THEN { THROW 'governance_control_not_found'; };
  RETURN CREATE control_mappings CONTENT { tenant_id: $tenant_id, source_control_id: $source_control_id, target_control_id: $target_control_id, mapping_kind: $mapping_kind, confidence: fn::clamp01($confidence), rationale: $rationale, created_at: time::now() };
};

DEFINE FUNCTION fn::start_compliance_audit($tenant_id, $compliance_scope_id, $auditor_id) {
  LET $scope = SELECT * FROM $compliance_scope_id;
  IF count($scope) = 0 THEN { THROW 'compliance_scope_not_found'; };
  LET $obs = fn::create_observation_run($tenant_id, NONE, 'compliance_audit', 'agx:compliance-governance-v1');
  LET $run = CREATE compliance_audit_runs CONTENT { tenant_id: $tenant_id, compliance_scope_id: $compliance_scope_id, framework_ids: $scope[0].applicable_framework_ids, auditor_id: $auditor_id, status: 'running', observation_run_id: $obs.id, started_at: time::now() };
  fn::add_observation_step($obs.id, 1, 'start_compliance_audit', { compliance_scope_id: $compliance_scope_id, framework_ids: $scope[0].applicable_framework_ids }, { audit_run_id: $run.id }, 'completed', 'agx:compliance-governance-v1');
  RETURN $run;
};

DEFINE FUNCTION fn::record_control_assessment($tenant_id, $compliance_scope_id, $control_id, $assessor_id, $assessment_kind, $status, $score, $findings, $evidence_ids, $remediation_required, $remediation_plan) {
  LET $scope = SELECT * FROM $compliance_scope_id;
  LET $control = SELECT * FROM $control_id;
  IF count($scope) = 0 THEN { THROW 'compliance_scope_not_found'; };
  IF count($control) = 0 THEN { THROW 'governance_control_not_found'; };
  RETURN CREATE control_assessments CONTENT { tenant_id: $tenant_id, compliance_scope_id: $compliance_scope_id, control_id: $control_id, assessor_id: $assessor_id, assessment_kind: $assessment_kind, status: $status, score: fn::clamp01($score), findings: $findings, evidence_ids: $evidence_ids, remediation_required: $remediation_required, remediation_plan: $remediation_plan, assessed_at: time::now() };
};

DEFINE FUNCTION fn::finalize_compliance_audit($audit_run_id) {
  LET $run = SELECT * FROM $audit_run_id;
  IF count($run) = 0 THEN { THROW 'compliance_audit_run_not_found'; };
  LET $assessments = SELECT * FROM control_assessments WHERE compliance_scope_id = $run[0].compliance_scope_id;
  IF count($assessments) = 0 THEN { THROW 'control_assessments_required'; };
  LET $aggregate = fn::clamp01(math::mean($assessments[*].score));
  LET $blockers = count(SELECT * FROM $assessments WHERE status IN ['failed', 'non_compliant'] AND remediation_required = true);
  LET $passed = $aggregate >= 0.85 AND $blockers = 0;
  UPDATE $audit_run_id SET status = 'completed', aggregate_score = $aggregate, passed = $passed, blocker_count = $blockers, completed_at = time::now();
  fn::add_observation_step($run[0].observation_run_id, 999, 'finalize_compliance_audit', { assessment_count: count($assessments) }, { aggregate_score: $aggregate, blocker_count: $blockers, passed: $passed }, 'completed', 'agx:compliance-governance-v1');
  fn::finish_observation_run($run[0].observation_run_id, 'completed', { aggregate_score: $aggregate, passed: $passed, blocker_count: $blockers });
  RETURN SELECT * FROM $audit_run_id;
};

DEFINE FUNCTION fn::evaluate_compliance_gate($tenant_id, $audit_run_id, $compliance_gate_id, $actor_id) {
  LET $run = SELECT * FROM $audit_run_id;
  LET $gate = SELECT * FROM $compliance_gate_id;
  IF count($run) = 0 THEN { THROW 'compliance_audit_run_not_found'; };
  IF count($gate) = 0 THEN { THROW 'compliance_gate_not_found'; };
  IF $run[0].status != 'completed' THEN { THROW 'compliance_audit_not_completed'; };
  LET $score_pass = $run[0].aggregate_score >= $gate[0].min_aggregate_score;
  LET $blocker_pass = IF $gate[0].block_on_critical_failure THEN $run[0].blocker_count = 0 ELSE true END;
  LET $decision = IF $score_pass AND $blocker_pass THEN 'approved_pending_human_if_required' ELSE 'blocked' END;
  LET $human_required = $gate[0].require_human_approval AND $decision != 'blocked';
  LET $decision_log = fn::log_decision_context($tenant_id, 'compliance_gate_decision', string::concat($run[0].compliance_scope_id), $actor_id, NONE, NONE, { audit_run_id: $audit_run_id, compliance_gate_id: $compliance_gate_id }, {}, {}, {}, {}, {}, {}, { gate: $gate[0] }, [{ kind: 'compliance_gate', min_aggregate_score: $gate[0].min_aggregate_score, block_on_critical_failure: $gate[0].block_on_critical_failure, require_human_approval: $gate[0].require_human_approval }], { aggregate_score: $run[0].aggregate_score, blocker_count: $run[0].blocker_count }, [{ decision: 'approve' }, { decision: 'block' }], { decision: $decision }, [], 'compliance_gate_evaluated', { score_pass: $score_pass, blocker_pass: $blocker_pass, human_required: $human_required }, [$audit_run_id], $run[0].observation_run_id, [], $human_required);
  RETURN CREATE compliance_gate_decisions CONTENT { tenant_id: $tenant_id, compliance_gate_id: $compliance_gate_id, audit_run_id: $audit_run_id, decision: IF $human_required THEN 'pending_human_approval' ELSE IF $decision = 'blocked' THEN 'blocked' ELSE 'approved' END END, reason: IF $score_pass AND $blocker_pass THEN 'compliance_gate_passed' ELSE 'compliance_gate_failed' END, human_approval_required: $human_required, human_response_status: IF $human_required THEN 'pending' ELSE 'not_required' END, decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::approve_compliance_gate_decision($decision_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $decision = SELECT * FROM $decision_id;
  IF count($decision) = 0 THEN { THROW 'compliance_gate_decision_not_found'; };
  IF !$decision[0].human_approval_required THEN { THROW 'human_approval_not_required'; };
  LET $response = fn::record_human_decision_response($decision[0].tenant_id, $decision[0].decision_log_id, NONE, NONE, $human_actor_id, 'compliance_gate_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $decision_id SET decision = IF $approval_status = 'approved' THEN 'approved' ELSE 'blocked' END, human_response_status = $approval_status;
  RETURN SELECT * FROM $decision_id;
};

DEFINE FUNCTION fn::require_compliance_gate_passed($decision_id) {
  LET $decision = SELECT * FROM $decision_id;
  IF count($decision) = 0 THEN { THROW 'compliance_gate_decision_required'; };
  IF $decision[0].decision != 'approved' THEN { THROW 'compliance_gate_not_approved'; };
  RETURN true;
};
