DEFINE TABLE compliance_automation_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_automation_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON compliance_automation_policies TYPE string;
DEFINE FIELD name ON compliance_automation_policies TYPE string;
DEFINE FIELD evidence_collection_mode ON compliance_automation_policies TYPE string DEFAULT 'continuous';
DEFINE FIELD auto_assess_controls ON compliance_automation_policies TYPE bool DEFAULT true;
DEFINE FIELD auto_open_remediation_tasks ON compliance_automation_policies TYPE bool DEFAULT true;
DEFINE FIELD auto_block_execution_on_failed_gate ON compliance_automation_policies TYPE bool DEFAULT true;
DEFINE FIELD require_human_signoff_for_exceptions ON compliance_automation_policies TYPE bool DEFAULT true;
DEFINE FIELD require_evidence_hash ON compliance_automation_policies TYPE bool DEFAULT true;
DEFINE FIELD min_evidence_items_per_mandatory_control ON compliance_automation_policies TYPE int DEFAULT 1;
DEFINE FIELD min_control_score ON compliance_automation_policies TYPE number DEFAULT 0.85 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD enabled ON compliance_automation_policies TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON compliance_automation_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_automation_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ComplianceAutomationPolicy'];
DEFINE FIELD created_at ON compliance_automation_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX compliance_automation_policies_key_unique ON compliance_automation_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE compliance_evidence_artifacts SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_evidence_artifacts TYPE option<record<tenants>>;
DEFINE FIELD compliance_scope_id ON compliance_evidence_artifacts TYPE record<compliance_scopes>;
DEFINE FIELD artifact_kind ON compliance_evidence_artifacts TYPE string;
DEFINE FIELD source_system ON compliance_evidence_artifacts TYPE string;
DEFINE FIELD source_ref ON compliance_evidence_artifacts TYPE option<record>;
DEFINE FIELD uri ON compliance_evidence_artifacts TYPE option<string>;
DEFINE FIELD content_hash ON compliance_evidence_artifacts TYPE string;
DEFINE FIELD hash_algorithm ON compliance_evidence_artifacts TYPE string DEFAULT 'sha256';
DEFINE FIELD summary ON compliance_evidence_artifacts TYPE string;
DEFINE FIELD payload ON compliance_evidence_artifacts TYPE object DEFAULT {};
DEFINE FIELD collected_by ON compliance_evidence_artifacts TYPE string;
DEFINE FIELD observed_at ON compliance_evidence_artifacts TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON compliance_evidence_artifacts TYPE option<datetime>;
DEFINE FIELD jsonld_context ON compliance_evidence_artifacts TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_evidence_artifacts TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ComplianceEvidenceArtifact'];
DEFINE FIELD created_at ON compliance_evidence_artifacts TYPE datetime DEFAULT time::now();

DEFINE TABLE control_evidence_links SCHEMAFULL;
DEFINE FIELD tenant_id ON control_evidence_links TYPE option<record<tenants>>;
DEFINE FIELD compliance_scope_id ON control_evidence_links TYPE record<compliance_scopes>;
DEFINE FIELD control_id ON control_evidence_links TYPE record<governance_controls>;
DEFINE FIELD evidence_artifact_id ON control_evidence_links TYPE record<compliance_evidence_artifacts>;
DEFINE FIELD link_kind ON control_evidence_links TYPE string DEFAULT 'supports';
DEFINE FIELD confidence ON control_evidence_links TYPE number DEFAULT 0.5 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD rationale ON control_evidence_links TYPE string;
DEFINE FIELD created_at ON control_evidence_links TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON control_evidence_links TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON control_evidence_links TYPE array<string> DEFAULT ['schema:Action', 'agx:ControlEvidenceLink'];
DEFINE INDEX control_evidence_links_unique ON control_evidence_links FIELDS compliance_scope_id, control_id, evidence_artifact_id UNIQUE;

DEFINE TABLE compliance_exceptions SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_exceptions TYPE option<record<tenants>>;
DEFINE FIELD compliance_scope_id ON compliance_exceptions TYPE record<compliance_scopes>;
DEFINE FIELD control_id ON compliance_exceptions TYPE record<governance_controls>;
DEFINE FIELD reason ON compliance_exceptions TYPE string;
DEFINE FIELD risk_acceptance ON compliance_exceptions TYPE object DEFAULT {};
DEFINE FIELD compensating_controls ON compliance_exceptions TYPE array<object> DEFAULT [];
DEFINE FIELD status ON compliance_exceptions TYPE string DEFAULT 'pending_approval';
DEFINE FIELD decision_log_id ON compliance_exceptions TYPE option<record<decision_context_logs>>;
DEFINE FIELD approved_by ON compliance_exceptions TYPE option<string>;
DEFINE FIELD approved_at ON compliance_exceptions TYPE option<datetime>;
DEFINE FIELD expires_at ON compliance_exceptions TYPE option<datetime>;
DEFINE FIELD jsonld_context ON compliance_exceptions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_exceptions TYPE array<string> DEFAULT ['schema:Permit', 'agx:ComplianceException'];
DEFINE FIELD created_at ON compliance_exceptions TYPE datetime DEFAULT time::now();

DEFINE TABLE compliance_remediation_tasks SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_remediation_tasks TYPE option<record<tenants>>;
DEFINE FIELD compliance_scope_id ON compliance_remediation_tasks TYPE record<compliance_scopes>;
DEFINE FIELD control_id ON compliance_remediation_tasks TYPE record<governance_controls>;
DEFINE FIELD assessment_id ON compliance_remediation_tasks TYPE option<record<control_assessments>>;
DEFINE FIELD title ON compliance_remediation_tasks TYPE string;
DEFINE FIELD description ON compliance_remediation_tasks TYPE string;
DEFINE FIELD severity ON compliance_remediation_tasks TYPE string DEFAULT 'medium';
DEFINE FIELD owner_id ON compliance_remediation_tasks TYPE string;
DEFINE FIELD due_at ON compliance_remediation_tasks TYPE option<datetime>;
DEFINE FIELD status ON compliance_remediation_tasks TYPE string DEFAULT 'open';
DEFINE FIELD verification_evidence_ids ON compliance_remediation_tasks TYPE array<record<compliance_evidence_artifacts>> DEFAULT [];
DEFINE FIELD jsonld_context ON compliance_remediation_tasks TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_remediation_tasks TYPE array<string> DEFAULT ['schema:Action', 'agx:ComplianceRemediationTask'];
DEFINE FIELD created_at ON compliance_remediation_tasks TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON compliance_remediation_tasks TYPE datetime DEFAULT time::now();

DEFINE TABLE compliance_proof_snapshots SCHEMAFULL;
DEFINE FIELD tenant_id ON compliance_proof_snapshots TYPE option<record<tenants>>;
DEFINE FIELD compliance_scope_id ON compliance_proof_snapshots TYPE record<compliance_scopes>;
DEFINE FIELD audit_run_id ON compliance_proof_snapshots TYPE option<record<compliance_audit_runs>>;
DEFINE FIELD snapshot_kind ON compliance_proof_snapshots TYPE string DEFAULT 'audit_proof';
DEFINE FIELD framework_ids ON compliance_proof_snapshots TYPE array<record<governance_frameworks>> DEFAULT [];
DEFINE FIELD control_count ON compliance_proof_snapshots TYPE int DEFAULT 0;
DEFINE FIELD assessed_control_count ON compliance_proof_snapshots TYPE int DEFAULT 0;
DEFINE FIELD evidence_count ON compliance_proof_snapshots TYPE int DEFAULT 0;
DEFINE FIELD exception_count ON compliance_proof_snapshots TYPE int DEFAULT 0;
DEFINE FIELD remediation_count ON compliance_proof_snapshots TYPE int DEFAULT 0;
DEFINE FIELD aggregate_score ON compliance_proof_snapshots TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD proof_payload ON compliance_proof_snapshots TYPE object DEFAULT {};
DEFINE FIELD proof_hash ON compliance_proof_snapshots TYPE string;
DEFINE FIELD hash_algorithm ON compliance_proof_snapshots TYPE string DEFAULT 'sha256';
DEFINE FIELD signed_by ON compliance_proof_snapshots TYPE option<string>;
DEFINE FIELD signature_payload ON compliance_proof_snapshots TYPE option<object>;
DEFINE FIELD created_at ON compliance_proof_snapshots TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON compliance_proof_snapshots TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON compliance_proof_snapshots TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ComplianceProofSnapshot'];

UPSERT compliance_automation_policies:default CONTENT {
  tenant_id: NONE,
  key: 'default',
  name: 'Default Continuous Compliance Automation Policy',
  evidence_collection_mode: 'continuous',
  auto_assess_controls: true,
  auto_open_remediation_tasks: true,
  auto_block_execution_on_failed_gate: true,
  require_human_signoff_for_exceptions: true,
  require_evidence_hash: true,
  min_evidence_items_per_mandatory_control: 1,
  min_control_score: 0.85,
  enabled: true
};

DEFINE FUNCTION fn::select_compliance_automation_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM compliance_automation_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM compliance_automation_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN compliance_automation_policies:default;
};

DEFINE FUNCTION fn::collect_compliance_evidence($tenant_id, $compliance_scope_id, $artifact_kind, $source_system, $source_ref, $uri, $content_hash, $summary, $payload, $collected_by, $expires_at) {
  LET $scope = SELECT * FROM $compliance_scope_id;
  IF count($scope) = 0 THEN { THROW 'compliance_scope_not_found'; };
  IF $content_hash = NONE OR string::len($content_hash) = 0 THEN { THROW 'compliance_evidence_hash_required'; };
  RETURN CREATE compliance_evidence_artifacts CONTENT { tenant_id: $tenant_id, compliance_scope_id: $compliance_scope_id, artifact_kind: $artifact_kind, source_system: $source_system, source_ref: $source_ref, uri: $uri, content_hash: $content_hash, hash_algorithm: 'sha256', summary: $summary, payload: $payload, collected_by: $collected_by, observed_at: time::now(), expires_at: $expires_at, created_at: time::now() };
};

DEFINE FUNCTION fn::link_evidence_to_control($tenant_id, $compliance_scope_id, $control_id, $evidence_artifact_id, $link_kind, $confidence, $rationale) {
  LET $control = SELECT * FROM $control_id;
  LET $evidence = SELECT * FROM $evidence_artifact_id;
  IF count($control) = 0 THEN { THROW 'governance_control_not_found'; };
  IF count($evidence) = 0 THEN { THROW 'compliance_evidence_not_found'; };
  IF $evidence[0].compliance_scope_id != $compliance_scope_id THEN { THROW 'evidence_scope_mismatch'; };
  RETURN CREATE control_evidence_links CONTENT { tenant_id: $tenant_id, compliance_scope_id: $compliance_scope_id, control_id: $control_id, evidence_artifact_id: $evidence_artifact_id, link_kind: $link_kind, confidence: fn::clamp01($confidence), rationale: $rationale, created_at: time::now() };
};

DEFINE FUNCTION fn::auto_assess_control($tenant_id, $compliance_scope_id, $control_id, $assessor_id, $policy_key) {
  LET $policy = fn::select_compliance_automation_policy($tenant_id, $policy_key);
  LET $control = SELECT * FROM $control_id;
  IF count($control) = 0 THEN { THROW 'governance_control_not_found'; };
  LET $links = SELECT * FROM control_evidence_links WHERE compliance_scope_id = $compliance_scope_id AND control_id = $control_id;
  LET $valid_links = SELECT * FROM $links WHERE confidence >= 0.5;
  LET $evidence_score = fn::clamp01(count($valid_links) / math::max([$policy.min_evidence_items_per_mandatory_control, 1]));
  LET $confidence_score = IF count($valid_links) = 0 THEN 0 ELSE fn::clamp01(math::mean($valid_links[*].confidence)) END;
  LET $score = fn::clamp01((0.65 * $evidence_score) + (0.35 * $confidence_score));
  LET $status = IF $score >= $policy.min_control_score THEN 'compliant' ELSE 'non_compliant' END;
  LET $assessment = fn::record_control_assessment($tenant_id, $compliance_scope_id, $control_id, $assessor_id, 'automated', $status, $score, [{ kind: 'automated_evidence_check', evidence_count: count($valid_links), required_evidence_count: $policy.min_evidence_items_per_mandatory_control }], $valid_links[*].evidence_artifact_id, $status != 'compliant', IF $status = 'compliant' THEN NONE ELSE { action: 'collect_more_evidence_or_remediate_control', required_evidence_count: $policy.min_evidence_items_per_mandatory_control } END);
  IF $policy.auto_open_remediation_tasks AND $status != 'compliant' THEN { fn::open_compliance_remediation_task($tenant_id, $compliance_scope_id, $control_id, $assessment.id, string::concat('Remediate control ', $control[0].key), string::concat('Automated compliance assessment failed for ', $control[0].name), $control[0].severity, $assessor_id, NONE); };
  RETURN $assessment;
};

DEFINE FUNCTION fn::run_compliance_automation($tenant_id, $compliance_scope_id, $auditor_id, $policy_key) {
  LET $scope = SELECT * FROM $compliance_scope_id;
  IF count($scope) = 0 THEN { THROW 'compliance_scope_not_found'; };
  LET $audit = fn::start_compliance_audit($tenant_id, $compliance_scope_id, $auditor_id);
  LET $controls = SELECT * FROM governance_controls WHERE framework_id INSIDE $scope[0].applicable_framework_ids AND mandatory = true;
  FOR $control IN $controls { fn::auto_assess_control($tenant_id, $compliance_scope_id, $control.id, $auditor_id, $policy_key); };
  LET $final = fn::finalize_compliance_audit($audit.id);
  RETURN $final;
};

DEFINE FUNCTION fn::open_compliance_remediation_task($tenant_id, $compliance_scope_id, $control_id, $assessment_id, $title, $description, $severity, $owner_id, $due_at) {
  RETURN CREATE compliance_remediation_tasks CONTENT { tenant_id: $tenant_id, compliance_scope_id: $compliance_scope_id, control_id: $control_id, assessment_id: $assessment_id, title: $title, description: $description, severity: $severity, owner_id: $owner_id, due_at: $due_at, status: 'open', verification_evidence_ids: [], created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::close_compliance_remediation_task($task_id, $verification_evidence_ids) {
  LET $task = SELECT * FROM $task_id;
  IF count($task) = 0 THEN { THROW 'compliance_remediation_task_not_found'; };
  IF count($verification_evidence_ids) = 0 THEN { THROW 'remediation_verification_evidence_required'; };
  UPDATE $task_id SET status = 'closed', verification_evidence_ids = $verification_evidence_ids, updated_at = time::now();
  RETURN SELECT * FROM $task_id;
};

DEFINE FUNCTION fn::request_compliance_exception($tenant_id, $compliance_scope_id, $control_id, $actor_id, $reason, $risk_acceptance, $compensating_controls, $expires_at) {
  LET $decision_log = fn::log_decision_context($tenant_id, 'compliance_exception_request', string::concat($compliance_scope_id), $actor_id, NONE, NONE, { compliance_scope_id: $compliance_scope_id, control_id: $control_id }, {}, {}, {}, {}, {}, {}, { risk_acceptance: $risk_acceptance, compensating_controls: $compensating_controls }, [{ kind: 'exception_requires_human_signoff' }], { reason: $reason, expires_at: $expires_at }, [{ decision: 'approve_exception' }, { decision: 'reject_exception' }], { requested_exception: true }, [], 'compliance_exception_requested', { reason: $reason }, [$control_id], NONE, [], true);
  RETURN CREATE compliance_exceptions CONTENT { tenant_id: $tenant_id, compliance_scope_id: $compliance_scope_id, control_id: $control_id, reason: $reason, risk_acceptance: $risk_acceptance, compensating_controls: $compensating_controls, status: 'pending_approval', decision_log_id: $decision_log.id, expires_at: $expires_at, created_at: time::now() };
};

DEFINE FUNCTION fn::approve_compliance_exception($exception_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $exception = SELECT * FROM $exception_id;
  IF count($exception) = 0 THEN { THROW 'compliance_exception_not_found'; };
  LET $response = fn::record_human_decision_response($exception[0].tenant_id, $exception[0].decision_log_id, NONE, NONE, $human_actor_id, 'compliance_exception_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $exception_id SET status = IF $approval_status = 'approved' THEN 'approved' ELSE 'rejected' END, approved_by = IF $approval_status = 'approved' THEN $human_actor_id ELSE NONE END, approved_at = IF $approval_status = 'approved' THEN time::now() ELSE NONE END;
  RETURN SELECT * FROM $exception_id;
};

DEFINE FUNCTION fn::create_compliance_proof_snapshot($tenant_id, $compliance_scope_id, $audit_run_id, $proof_hash, $signed_by, $signature_payload) {
  LET $scope = SELECT * FROM $compliance_scope_id;
  IF count($scope) = 0 THEN { THROW 'compliance_scope_not_found'; };
  IF $proof_hash = NONE OR string::len($proof_hash) = 0 THEN { THROW 'proof_hash_required'; };
  LET $controls = SELECT * FROM governance_controls WHERE framework_id INSIDE $scope[0].applicable_framework_ids;
  LET $assessments = SELECT * FROM control_assessments WHERE compliance_scope_id = $compliance_scope_id;
  LET $evidence = SELECT * FROM compliance_evidence_artifacts WHERE compliance_scope_id = $compliance_scope_id;
  LET $exceptions = SELECT * FROM compliance_exceptions WHERE compliance_scope_id = $compliance_scope_id AND status = 'approved';
  LET $remediations = SELECT * FROM compliance_remediation_tasks WHERE compliance_scope_id = $compliance_scope_id;
  LET $aggregate = IF count($assessments) = 0 THEN 0 ELSE fn::clamp01(math::mean($assessments[*].score)) END;
  LET $payload = { compliance_scope_id: $compliance_scope_id, framework_ids: $scope[0].applicable_framework_ids, controls: $controls[*].id, assessments: $assessments[*].id, evidence: $evidence[*].id, exceptions: $exceptions[*].id, remediations: $remediations[*].id, aggregate_score: $aggregate };
  RETURN CREATE compliance_proof_snapshots CONTENT { tenant_id: $tenant_id, compliance_scope_id: $compliance_scope_id, audit_run_id: $audit_run_id, snapshot_kind: 'audit_proof', framework_ids: $scope[0].applicable_framework_ids, control_count: count($controls), assessed_control_count: count($assessments), evidence_count: count($evidence), exception_count: count($exceptions), remediation_count: count($remediations), aggregate_score: $aggregate, proof_payload: $payload, proof_hash: $proof_hash, hash_algorithm: 'sha256', signed_by: $signed_by, signature_payload: $signature_payload, created_at: time::now() };
};

DEFINE FUNCTION fn::require_automated_compliance_proof($tenant_id, $compliance_scope_id, $policy_key) {
  LET $policy = fn::select_compliance_automation_policy($tenant_id, $policy_key);
  LET $scope = SELECT * FROM $compliance_scope_id;
  IF count($scope) = 0 THEN { THROW 'compliance_scope_not_found'; };
  LET $controls = SELECT * FROM governance_controls WHERE framework_id INSIDE $scope[0].applicable_framework_ids AND mandatory = true;
  LET $assessments = SELECT * FROM control_assessments WHERE compliance_scope_id = $compliance_scope_id;
  LET $noncompliant = SELECT * FROM $assessments WHERE status != 'compliant' AND score < $policy.min_control_score;
  LET $missing_assessments = count($controls) - count($assessments);
  LET $evidence_links = SELECT * FROM control_evidence_links WHERE compliance_scope_id = $compliance_scope_id;
  LET $proofs = SELECT * FROM compliance_proof_snapshots WHERE compliance_scope_id = $compliance_scope_id ORDER BY created_at DESC LIMIT 1;
  IF $missing_assessments > 0 THEN { THROW 'mandatory_control_assessments_missing'; };
  IF count($noncompliant) > 0 THEN { THROW 'noncompliant_controls_present'; };
  IF count($evidence_links) < count($controls) * $policy.min_evidence_items_per_mandatory_control THEN { THROW 'mandatory_control_evidence_missing'; };
  IF count($proofs) = 0 THEN { THROW 'compliance_proof_snapshot_required'; };
  RETURN true;
};
