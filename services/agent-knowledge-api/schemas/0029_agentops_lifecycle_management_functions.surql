DEFINE TABLE agentops_lifecycle_guidance SCHEMAFULL;
DEFINE FIELD tenant_id ON agentops_lifecycle_guidance TYPE option<record<tenants>>;
DEFINE FIELD key ON agentops_lifecycle_guidance TYPE string;
DEFINE FIELD name ON agentops_lifecycle_guidance TYPE string;
DEFINE FIELD provider ON agentops_lifecycle_guidance TYPE string DEFAULT 'microsoft';
DEFINE FIELD guidance_uri ON agentops_lifecycle_guidance TYPE string;
DEFINE FIELD guidance_version ON agentops_lifecycle_guidance TYPE string DEFAULT '2025';
DEFINE FIELD guidance_kind ON agentops_lifecycle_guidance TYPE string DEFAULT 'agentops_lifecycle_management';
DEFINE FIELD lifecycle_stages ON agentops_lifecycle_guidance TYPE array<string> DEFAULT ['ideate', 'build', 'evaluate', 'deploy', 'monitor', 'optimize', 'retire'];
DEFINE FIELD source_grounding_refs ON agentops_lifecycle_guidance TYPE array<string> DEFAULT ['microsoft:azure-ai-foundry-agentops-zero-to-hero:2025', 'arxiv:2601.15630v2'];
DEFINE FIELD jsonld_context ON agentops_lifecycle_guidance TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agentops_lifecycle_guidance TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentOpsLifecycleGuidance'];
DEFINE FIELD created_at ON agentops_lifecycle_guidance TYPE datetime DEFAULT time::now();
DEFINE INDEX agentops_lifecycle_guidance_key_unique ON agentops_lifecycle_guidance FIELDS tenant_id, key, guidance_version UNIQUE;

DEFINE TABLE agentops_lifecycle_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON agentops_lifecycle_runs TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON agentops_lifecycle_runs TYPE option<record<agents>>;
DEFINE FIELD application_id ON agentops_lifecycle_runs TYPE option<record<applications>>;
DEFINE FIELD project_id ON agentops_lifecycle_runs TYPE option<record<projects>>;
DEFINE FIELD milestone_id ON agentops_lifecycle_runs TYPE option<record<milestones>>;
DEFINE FIELD task_id ON agentops_lifecycle_runs TYPE option<record<tasks>>;
DEFINE FIELD subject_id ON agentops_lifecycle_runs TYPE string;
DEFINE FIELD lifecycle_stage ON agentops_lifecycle_runs TYPE string;
DEFINE FIELD status ON agentops_lifecycle_runs TYPE string DEFAULT 'running';
DEFINE FIELD required_gate_ids ON agentops_lifecycle_runs TYPE array<record> DEFAULT [];
DEFINE FIELD completed_gate_ids ON agentops_lifecycle_runs TYPE array<record> DEFAULT [];
DEFINE FIELD observation_run_id ON agentops_lifecycle_runs TYPE option<record<observation_runs>>;
DEFINE FIELD decision_log_id ON agentops_lifecycle_runs TYPE option<record<decision_context_logs>>;
DEFINE FIELD source_grounding_refs ON agentops_lifecycle_runs TYPE array<string> DEFAULT ['microsoft:azure-ai-foundry-agentops-zero-to-hero:2025', 'arxiv:2601.15630v2'];
DEFINE FIELD jsonld_context ON agentops_lifecycle_runs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agentops_lifecycle_runs TYPE array<string> DEFAULT ['schema:Action', 'agx:AgentOpsLifecycleRun'];
DEFINE FIELD created_at ON agentops_lifecycle_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON agentops_lifecycle_runs TYPE option<datetime>;

DEFINE TABLE agentops_stage_gates SCHEMAFULL;
DEFINE FIELD tenant_id ON agentops_stage_gates TYPE option<record<tenants>>;
DEFINE FIELD key ON agentops_stage_gates TYPE string;
DEFINE FIELD name ON agentops_stage_gates TYPE string;
DEFINE FIELD lifecycle_stage ON agentops_stage_gates TYPE string;
DEFINE FIELD required_evaluation_gate ON agentops_stage_gates TYPE bool DEFAULT true;
DEFINE FIELD required_compliance_gate ON agentops_stage_gates TYPE bool DEFAULT true;
DEFINE FIELD required_identity_gate ON agentops_stage_gates TYPE bool DEFAULT true;
DEFINE FIELD required_context_gate ON agentops_stage_gates TYPE bool DEFAULT true;
DEFINE FIELD required_observability_gate ON agentops_stage_gates TYPE bool DEFAULT true;
DEFINE FIELD required_human_approval ON agentops_stage_gates TYPE bool DEFAULT false;
DEFINE FIELD min_reliability_score ON agentops_stage_gates TYPE number DEFAULT 0.80 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_trust_score ON agentops_stage_gates TYPE number DEFAULT 0.80 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD enabled ON agentops_stage_gates TYPE bool DEFAULT true;
DEFINE FIELD source_grounding_refs ON agentops_stage_gates TYPE array<string> DEFAULT ['microsoft:azure-ai-foundry-agentops-zero-to-hero:2025', 'arxiv:2601.15630v2'];
DEFINE FIELD jsonld_context ON agentops_stage_gates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agentops_stage_gates TYPE array<string> DEFAULT ['schema:Action', 'agx:AgentOpsStageGate'];
DEFINE FIELD created_at ON agentops_stage_gates TYPE datetime DEFAULT time::now();
DEFINE INDEX agentops_stage_gates_key_unique ON agentops_stage_gates FIELDS tenant_id, key UNIQUE;

DEFINE TABLE agentops_gate_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON agentops_gate_decisions TYPE option<record<tenants>>;
DEFINE FIELD lifecycle_run_id ON agentops_gate_decisions TYPE record<agentops_lifecycle_runs>;
DEFINE FIELD stage_gate_id ON agentops_gate_decisions TYPE record<agentops_stage_gates>;
DEFINE FIELD decision ON agentops_gate_decisions TYPE string;
DEFINE FIELD reason ON agentops_gate_decisions TYPE string;
DEFINE FIELD trust_score_id ON agentops_gate_decisions TYPE option<record<trust_scores>>;
DEFINE FIELD reliability_profile_id ON agentops_gate_decisions TYPE option<record<reliability_profiles>>;
DEFINE FIELD evaluation_run_id ON agentops_gate_decisions TYPE option<record<evaluation_runs>>;
DEFINE FIELD compliance_gate_decision_id ON agentops_gate_decisions TYPE option<record<compliance_gate_decisions>>;
DEFINE FIELD identity_access_decision_id ON agentops_gate_decisions TYPE option<record<agent_identity_access_decisions>>;
DEFINE FIELD decision_log_id ON agentops_gate_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD human_approval_required ON agentops_gate_decisions TYPE bool DEFAULT false;
DEFINE FIELD human_response_status ON agentops_gate_decisions TYPE string DEFAULT 'not_required';
DEFINE FIELD created_at ON agentops_gate_decisions TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON agentops_gate_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agentops_gate_decisions TYPE array<string> DEFAULT ['schema:Action', 'agx:AgentOpsGateDecision'];

DEFINE TABLE agentops_kpi_snapshots SCHEMAFULL;
DEFINE FIELD tenant_id ON agentops_kpi_snapshots TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON agentops_kpi_snapshots TYPE string;
DEFINE FIELD scope_kind ON agentops_kpi_snapshots TYPE string;
DEFINE FIELD scope_ref ON agentops_kpi_snapshots TYPE option<record>;
DEFINE FIELD agents_with_named_owner_rate ON agentops_kpi_snapshots TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD median_credential_revocation_days ON agentops_kpi_snapshots TYPE number DEFAULT 999;
DEFINE FIELD tool_calls_logged_rate ON agentops_kpi_snapshots TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD orphan_agent_ratio ON agentops_kpi_snapshots TYPE number DEFAULT 1 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD phi_minimization_rate ON agentops_kpi_snapshots TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD control_drift_rate ON agentops_kpi_snapshots TYPE number DEFAULT 1 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD incident_rate_per_agent_month ON agentops_kpi_snapshots TYPE number DEFAULT 1;
DEFINE FIELD maturity_level ON agentops_kpi_snapshots TYPE int DEFAULT 1;
DEFINE FIELD source_grounding_refs ON agentops_kpi_snapshots TYPE array<string> DEFAULT ['arxiv:2601.15630v2'];
DEFINE FIELD jsonld_context ON agentops_kpi_snapshots TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agentops_kpi_snapshots TYPE array<string> DEFAULT ['schema:PropertyValue', 'agx:AgentOpsKPISnapshot'];
DEFINE FIELD measured_at ON agentops_kpi_snapshots TYPE datetime DEFAULT time::now();

UPSERT agentops_lifecycle_guidance:microsoft_agentops_2025 CONTENT {
  tenant_id: NONE,
  key: 'microsoft_agentops_zero_to_hero',
  name: 'Microsoft Azure AI Foundry AgentOps End-to-End Lifecycle Management',
  provider: 'microsoft',
  guidance_uri: 'https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/from-zero-to-hero-agentops---end-to-end-lifecycle-management-for-production-ai-a/4484922',
  guidance_version: '2025',
  guidance_kind: 'agentops_lifecycle_management',
  lifecycle_stages: ['ideate', 'build', 'evaluate', 'deploy', 'monitor', 'optimize', 'retire'],
  source_grounding_refs: ['microsoft:azure-ai-foundry-agentops-zero-to-hero:2025', 'arxiv:2601.15630v2']
};

UPSERT agentops_stage_gates:default_deploy CONTENT { tenant_id: NONE, key: 'default_deploy', name: 'Default AgentOps Deploy Gate', lifecycle_stage: 'deploy', required_evaluation_gate: true, required_compliance_gate: true, required_identity_gate: true, required_context_gate: true, required_observability_gate: true, required_human_approval: true, min_reliability_score: 0.80, min_trust_score: 0.80, enabled: true };
UPSERT agentops_stage_gates:default_monitor CONTENT { tenant_id: NONE, key: 'default_monitor', name: 'Default AgentOps Monitor Gate', lifecycle_stage: 'monitor', required_evaluation_gate: false, required_compliance_gate: true, required_identity_gate: true, required_context_gate: false, required_observability_gate: true, required_human_approval: false, min_reliability_score: 0.75, min_trust_score: 0.75, enabled: true };
UPSERT agentops_stage_gates:default_retire CONTENT { tenant_id: NONE, key: 'default_retire', name: 'Default AgentOps Retire Gate', lifecycle_stage: 'retire', required_evaluation_gate: false, required_compliance_gate: true, required_identity_gate: true, required_context_gate: false, required_observability_gate: true, required_human_approval: true, min_reliability_score: 0.00, min_trust_score: 0.00, enabled: true };

DEFINE FUNCTION fn::start_agentops_lifecycle_run($tenant_id, $agent_id, $application_id, $project_id, $milestone_id, $task_id, $subject_id, $lifecycle_stage) {
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'agentops_lifecycle_run', 'agx:agentops-lifecycle-v1');
  LET $run = CREATE agentops_lifecycle_runs CONTENT { tenant_id: $tenant_id, agent_id: $agent_id, application_id: $application_id, project_id: $project_id, milestone_id: $milestone_id, task_id: $task_id, subject_id: $subject_id, lifecycle_stage: $lifecycle_stage, status: 'running', observation_run_id: $obs.id, source_grounding_refs: ['microsoft:azure-ai-foundry-agentops-zero-to-hero:2025', 'arxiv:2601.15630v2'], created_at: time::now() };
  fn::add_observation_step($obs.id, 1, 'start_agentops_lifecycle_run', { lifecycle_stage: $lifecycle_stage, subject_id: $subject_id }, { lifecycle_run_id: $run.id }, 'completed', 'agx:agentops-lifecycle-v1');
  RETURN $run;
};

DEFINE FUNCTION fn::compute_agentops_maturity_level($agents_with_named_owner_rate, $median_credential_revocation_days, $tool_calls_logged_rate, $orphan_agent_ratio, $phi_minimization_rate, $control_drift_rate, $incident_rate_per_agent_month) {
  LET $level4 = $agents_with_named_owner_rate >= 0.99 AND $median_credential_revocation_days <= 2 AND $tool_calls_logged_rate >= 0.95 AND $orphan_agent_ratio <= 0.02 AND $phi_minimization_rate >= 0.95 AND $control_drift_rate <= 0.03 AND $incident_rate_per_agent_month <= 0.02;
  LET $level3 = $agents_with_named_owner_rate >= 0.95 AND $median_credential_revocation_days <= 7 AND $tool_calls_logged_rate >= 0.85 AND $orphan_agent_ratio <= 0.05 AND $phi_minimization_rate >= 0.80 AND $control_drift_rate <= 0.08 AND $incident_rate_per_agent_month <= 0.05;
  LET $level2 = $agents_with_named_owner_rate >= 0.80 AND $median_credential_revocation_days <= 14 AND $tool_calls_logged_rate >= 0.60 AND $orphan_agent_ratio <= 0.10 AND $phi_minimization_rate >= 0.60 AND $control_drift_rate <= 0.15 AND $incident_rate_per_agent_month <= 0.10;
  RETURN IF $level4 THEN 4 ELSE IF $level3 THEN 3 ELSE IF $level2 THEN 2 ELSE 1 END END END;
};

DEFINE FUNCTION fn::record_agentops_kpi_snapshot($tenant_id, $subject_id, $scope_kind, $scope_ref, $agents_with_named_owner_rate, $median_credential_revocation_days, $tool_calls_logged_rate, $orphan_agent_ratio, $phi_minimization_rate, $control_drift_rate, $incident_rate_per_agent_month) {
  LET $level = fn::compute_agentops_maturity_level($agents_with_named_owner_rate, $median_credential_revocation_days, $tool_calls_logged_rate, $orphan_agent_ratio, $phi_minimization_rate, $control_drift_rate, $incident_rate_per_agent_month);
  RETURN CREATE agentops_kpi_snapshots CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, scope_kind: $scope_kind, scope_ref: $scope_ref, agents_with_named_owner_rate: $agents_with_named_owner_rate, median_credential_revocation_days: $median_credential_revocation_days, tool_calls_logged_rate: $tool_calls_logged_rate, orphan_agent_ratio: $orphan_agent_ratio, phi_minimization_rate: $phi_minimization_rate, control_drift_rate: $control_drift_rate, incident_rate_per_agent_month: $incident_rate_per_agent_month, maturity_level: $level, measured_at: time::now(), source_grounding_refs: ['arxiv:2601.15630v2'] };
};

DEFINE FUNCTION fn::evaluate_agentops_stage_gate($tenant_id, $lifecycle_run_id, $stage_gate_id, $evaluation_run_id, $compliance_gate_decision_id, $identity_access_decision_id, $execution_context_id, $actor_id) {
  LET $run = SELECT * FROM $lifecycle_run_id;
  LET $gate = SELECT * FROM $stage_gate_id;
  IF count($run) = 0 THEN { THROW 'agentops_lifecycle_run_not_found'; };
  IF count($gate) = 0 THEN { THROW 'agentops_stage_gate_not_found'; };
  LET $trust = fn::compute_trust_v1($tenant_id, $run[0].subject_id, $actor_id, { type: 'agentops_stage_gate', lifecycle_stage: $run[0].lifecycle_stage });
  LET $reliability = fn::compute_reliability($tenant_id, $run[0].subject_id, { type: 'agentops_stage_gate', lifecycle_stage: $run[0].lifecycle_stage }, NONE);
  IF $gate[0].required_evaluation_gate AND $evaluation_run_id = NONE THEN { THROW 'agentops_evaluation_gate_required'; };
  IF $gate[0].required_compliance_gate AND $compliance_gate_decision_id = NONE THEN { THROW 'agentops_compliance_gate_required'; };
  IF $gate[0].required_identity_gate AND $identity_access_decision_id = NONE THEN { THROW 'agentops_identity_gate_required'; };
  IF $gate[0].required_context_gate AND $execution_context_id = NONE THEN { THROW 'agentops_context_gate_required'; };
  IF $gate[0].required_compliance_gate THEN { fn::require_compliance_gate_passed($compliance_gate_decision_id); };
  IF $gate[0].required_identity_gate THEN { fn::require_agent_identity_access_allowed($identity_access_decision_id); };
  IF $gate[0].required_context_gate THEN { fn::require_complete_execution_context($execution_context_id); };
  IF $gate[0].required_observability_gate THEN { fn::require_observable_steps($run[0].observation_run_id, 1); };
  LET $passed = $trust.score >= $gate[0].min_trust_score AND $reliability.reliability_score >= $gate[0].min_reliability_score;
  LET $human_required = $gate[0].required_human_approval AND $passed;
  LET $decision = IF $passed THEN IF $human_required THEN 'pending_human_approval' ELSE 'approved' END ELSE 'blocked' END;
  LET $decision_log = fn::log_decision_context($tenant_id, 'agentops_stage_gate', $run[0].subject_id, $actor_id, NONE, NONE, { lifecycle_run_id: $lifecycle_run_id, stage_gate_id: $stage_gate_id, lifecycle_stage: $run[0].lifecycle_stage }, {}, {}, {}, { trust_score: $trust.score }, { reliability_score: $reliability.reliability_score }, { evaluation_run_id: $evaluation_run_id }, { compliance_gate_decision_id: $compliance_gate_decision_id, identity_access_decision_id: $identity_access_decision_id }, [{ kind: 'min_trust_score', value: $gate[0].min_trust_score }, { kind: 'min_reliability_score', value: $gate[0].min_reliability_score }, { kind: 'required_gates', value: $gate[0] }], { source_guidance: ['microsoft:azure-ai-foundry-agentops-zero-to-hero:2025', 'arxiv:2601.15630v2'] }, [{ decision: 'approved' }, { decision: 'blocked' }, { decision: 'pending_human_approval' }], { decision: $decision }, [], 'agentops_stage_gate_evaluated', { passed: $passed, trust_score: $trust.score, reliability_score: $reliability.reliability_score }, [$trust.id, $reliability.id], $run[0].observation_run_id, [], $human_required);
  LET $gate_decision = CREATE agentops_gate_decisions CONTENT { tenant_id: $tenant_id, lifecycle_run_id: $lifecycle_run_id, stage_gate_id: $stage_gate_id, decision: $decision, reason: IF $passed THEN 'agentops_stage_gate_passed' ELSE 'agentops_stage_gate_failed' END, trust_score_id: $trust.id, reliability_profile_id: $reliability.id, evaluation_run_id: $evaluation_run_id, compliance_gate_decision_id: $compliance_gate_decision_id, identity_access_decision_id: $identity_access_decision_id, decision_log_id: $decision_log.id, human_approval_required: $human_required, human_response_status: IF $human_required THEN 'pending' ELSE 'not_required' END, created_at: time::now() };
  UPDATE $lifecycle_run_id SET completed_gate_ids += $gate_decision.id;
  fn::add_observation_step($run[0].observation_run_id, 900, 'evaluate_agentops_stage_gate', { stage_gate_id: $stage_gate_id }, { gate_decision_id: $gate_decision.id, decision: $decision }, 'completed', 'agx:agentops-lifecycle-v1');
  RETURN $gate_decision;
};

DEFINE FUNCTION fn::approve_agentops_gate_decision($gate_decision_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $decision = SELECT * FROM $gate_decision_id;
  IF count($decision) = 0 THEN { THROW 'agentops_gate_decision_not_found'; };
  IF !$decision[0].human_approval_required THEN { THROW 'human_approval_not_required'; };
  LET $response = fn::record_human_decision_response($decision[0].tenant_id, $decision[0].decision_log_id, NONE, NONE, $human_actor_id, 'agentops_gate_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $gate_decision_id SET decision = IF $approval_status = 'approved' THEN 'approved' ELSE 'blocked' END, human_response_status = $approval_status;
  RETURN SELECT * FROM $gate_decision_id;
};

DEFINE FUNCTION fn::complete_agentops_lifecycle_run($lifecycle_run_id) {
  LET $run = SELECT * FROM $lifecycle_run_id;
  IF count($run) = 0 THEN { THROW 'agentops_lifecycle_run_not_found'; };
  LET $blocked = SELECT * FROM agentops_gate_decisions WHERE lifecycle_run_id = $lifecycle_run_id AND decision != 'approved';
  IF count($blocked) > 0 THEN { THROW 'agentops_lifecycle_run_has_unapproved_gates'; };
  UPDATE $lifecycle_run_id SET status = 'completed', completed_at = time::now();
  fn::finish_observation_run($run[0].observation_run_id, 'completed', { lifecycle_stage: $run[0].lifecycle_stage });
  RETURN SELECT * FROM $lifecycle_run_id;
};
