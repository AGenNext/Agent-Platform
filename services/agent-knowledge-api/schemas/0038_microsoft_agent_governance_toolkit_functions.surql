DEFINE TABLE agent_governance_toolkit_standards SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_governance_toolkit_standards TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_governance_toolkit_standards TYPE string;
DEFINE FIELD name ON agent_governance_toolkit_standards TYPE string;
DEFINE FIELD standard_uri ON agent_governance_toolkit_standards TYPE string;
DEFINE FIELD provider ON agent_governance_toolkit_standards TYPE string DEFAULT 'microsoft';
DEFINE FIELD standard_version ON agent_governance_toolkit_standards TYPE string DEFAULT 'latest';
DEFINE FIELD status ON agent_governance_toolkit_standards TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON agent_governance_toolkit_standards TYPE array<string> DEFAULT ['github:microsoft/agent-governance-toolkit'];
DEFINE FIELD jsonld_context ON agent_governance_toolkit_standards TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_governance_toolkit_standards TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentGovernanceToolkitStandard'];
DEFINE FIELD created_at ON agent_governance_toolkit_standards TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_governance_toolkit_standards_key_unique ON agent_governance_toolkit_standards FIELDS tenant_id, key, standard_version UNIQUE;

DEFINE TABLE agent_governance_inventory_snapshots SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_governance_inventory_snapshots TYPE option<record<tenants>>;
DEFINE FIELD snapshot_ref ON agent_governance_inventory_snapshots TYPE string;
DEFINE FIELD scope_kind ON agent_governance_inventory_snapshots TYPE string;
DEFINE FIELD scope_ref ON agent_governance_inventory_snapshots TYPE option<record>;
DEFINE FIELD discovered_agent_ids ON agent_governance_inventory_snapshots TYPE array<record<agents>> DEFAULT [];
DEFINE FIELD discovered_identity_subject_ids ON agent_governance_inventory_snapshots TYPE array<record<agent_identity_subjects>> DEFAULT [];
DEFINE FIELD discovered_application_ids ON agent_governance_inventory_snapshots TYPE array<record<applications>> DEFAULT [];
DEFINE FIELD orphan_agent_ids ON agent_governance_inventory_snapshots TYPE array<record<agents>> DEFAULT [];
DEFINE FIELD unowned_identity_subject_ids ON agent_governance_inventory_snapshots TYPE array<record<agent_identity_subjects>> DEFAULT [];
DEFINE FIELD tool_exposure_summary ON agent_governance_inventory_snapshots TYPE object DEFAULT {};
DEFINE FIELD data_access_summary ON agent_governance_inventory_snapshots TYPE object DEFAULT {};
DEFINE FIELD snapshot_hash ON agent_governance_inventory_snapshots TYPE string;
DEFINE FIELD source_grounding_refs ON agent_governance_inventory_snapshots TYPE array<string> DEFAULT ['github:microsoft/agent-governance-toolkit'];
DEFINE FIELD jsonld_context ON agent_governance_inventory_snapshots TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_governance_inventory_snapshots TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentGovernanceInventorySnapshot'];
DEFINE FIELD created_at ON agent_governance_inventory_snapshots TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_governance_inventory_snapshots_ref_unique ON agent_governance_inventory_snapshots FIELDS tenant_id, snapshot_ref UNIQUE;

DEFINE TABLE agent_governance_risk_assessments SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_governance_risk_assessments TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON agent_governance_risk_assessments TYPE string;
DEFINE FIELD scope_kind ON agent_governance_risk_assessments TYPE string;
DEFINE FIELD scope_ref ON agent_governance_risk_assessments TYPE option<record>;
DEFINE FIELD inventory_snapshot_id ON agent_governance_risk_assessments TYPE option<record<agent_governance_inventory_snapshots>>;
DEFINE FIELD identity_risk_score ON agent_governance_risk_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD tool_risk_score ON agent_governance_risk_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD data_risk_score ON agent_governance_risk_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD autonomy_risk_score ON agent_governance_risk_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD compliance_risk_score ON agent_governance_risk_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD aggregate_risk_score ON agent_governance_risk_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD risk_level ON agent_governance_risk_assessments TYPE string DEFAULT 'medium';
DEFINE FIELD findings ON agent_governance_risk_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD remediation_task_ids ON agent_governance_risk_assessments TYPE array<record<compliance_remediation_tasks>> DEFAULT [];
DEFINE FIELD decision_log_id ON agent_governance_risk_assessments TYPE option<record<decision_context_logs>>;
DEFINE FIELD source_grounding_refs ON agent_governance_risk_assessments TYPE array<string> DEFAULT ['github:microsoft/agent-governance-toolkit'];
DEFINE FIELD jsonld_context ON agent_governance_risk_assessments TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_governance_risk_assessments TYPE array<string> DEFAULT ['schema:ReviewAction', 'agx:AgentGovernanceRiskAssessment'];
DEFINE FIELD created_at ON agent_governance_risk_assessments TYPE datetime DEFAULT time::now();

DEFINE TABLE agent_governance_control_recommendations SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_governance_control_recommendations TYPE option<record<tenants>>;
DEFINE FIELD risk_assessment_id ON agent_governance_control_recommendations TYPE record<agent_governance_risk_assessments>;
DEFINE FIELD recommendation_kind ON agent_governance_control_recommendations TYPE string;
DEFINE FIELD title ON agent_governance_control_recommendations TYPE string;
DEFINE FIELD description ON agent_governance_control_recommendations TYPE string;
DEFINE FIELD mapped_control_ids ON agent_governance_control_recommendations TYPE array<record<governance_controls>> DEFAULT [];
DEFINE FIELD priority ON agent_governance_control_recommendations TYPE string DEFAULT 'medium';
DEFINE FIELD status ON agent_governance_control_recommendations TYPE string DEFAULT 'open';
DEFINE FIELD source_grounding_refs ON agent_governance_control_recommendations TYPE array<string> DEFAULT ['github:microsoft/agent-governance-toolkit'];
DEFINE FIELD jsonld_context ON agent_governance_control_recommendations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_governance_control_recommendations TYPE array<string> DEFAULT ['schema:Action', 'agx:AgentGovernanceControlRecommendation'];
DEFINE FIELD created_at ON agent_governance_control_recommendations TYPE datetime DEFAULT time::now();

DEFINE TABLE agent_governance_posture_reports SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_governance_posture_reports TYPE option<record<tenants>>;
DEFINE FIELD report_ref ON agent_governance_posture_reports TYPE string;
DEFINE FIELD scope_kind ON agent_governance_posture_reports TYPE string;
DEFINE FIELD scope_ref ON agent_governance_posture_reports TYPE option<record>;
DEFINE FIELD inventory_snapshot_id ON agent_governance_posture_reports TYPE option<record<agent_governance_inventory_snapshots>>;
DEFINE FIELD risk_assessment_ids ON agent_governance_posture_reports TYPE array<record<agent_governance_risk_assessments>> DEFAULT [];
DEFINE FIELD compliance_proof_snapshot_ids ON agent_governance_posture_reports TYPE array<record<compliance_proof_snapshots>> DEFAULT [];
DEFINE FIELD posture_score ON agent_governance_posture_reports TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD posture_level ON agent_governance_posture_reports TYPE string DEFAULT 'unknown';
DEFINE FIELD report_hash ON agent_governance_posture_reports TYPE string;
DEFINE FIELD decision_log_id ON agent_governance_posture_reports TYPE option<record<decision_context_logs>>;
DEFINE FIELD source_grounding_refs ON agent_governance_posture_reports TYPE array<string> DEFAULT ['github:microsoft/agent-governance-toolkit'];
DEFINE FIELD jsonld_context ON agent_governance_posture_reports TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_governance_posture_reports TYPE array<string> DEFAULT ['schema:Report', 'agx:AgentGovernancePostureReport'];
DEFINE FIELD created_at ON agent_governance_posture_reports TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_governance_posture_reports_ref_unique ON agent_governance_posture_reports FIELDS tenant_id, report_ref UNIQUE;

UPSERT agent_governance_toolkit_standards:microsoft_agent_governance_toolkit_latest CONTENT { tenant_id: NONE, key: 'microsoft_agent_governance_toolkit', name: 'Microsoft Agent Governance Toolkit', standard_uri: 'https://github.com/microsoft/agent-governance-toolkit', provider: 'microsoft', standard_version: 'latest', status: 'active', source_grounding_refs: ['github:microsoft/agent-governance-toolkit'] };

DEFINE FUNCTION fn::create_agent_governance_inventory_snapshot($tenant_id, $snapshot_ref, $scope_kind, $scope_ref, $snapshot_hash, $actor_id) {
  IF $snapshot_hash = NONE OR string::len($snapshot_hash) = 0 THEN { THROW 'agent_governance_inventory_snapshot_hash_required'; };
  LET $agents = SELECT * FROM agents WHERE tenant_id = $tenant_id;
  LET $identities = SELECT * FROM agent_identity_subjects WHERE tenant_id = $tenant_id;
  LET $applications = SELECT * FROM applications WHERE tenant_id = $tenant_id;
  LET $orphan_agents = SELECT * FROM $agents WHERE owner_id = NONE;
  LET $unowned_identities = SELECT * FROM $identities WHERE human_owner_id = NONE;
  LET $snapshot = CREATE agent_governance_inventory_snapshots CONTENT { tenant_id: $tenant_id, snapshot_ref: $snapshot_ref, scope_kind: $scope_kind, scope_ref: $scope_ref, discovered_agent_ids: $agents[*].id, discovered_identity_subject_ids: $identities[*].id, discovered_application_ids: $applications[*].id, orphan_agent_ids: $orphan_agents[*].id, unowned_identity_subject_ids: $unowned_identities[*].id, tool_exposure_summary: { tool_configurations: count(SELECT * FROM tool_configurations WHERE tenant_id = $tenant_id), relationship_tuples: count(SELECT * FROM relationship_tuples WHERE tenant_id = $tenant_id) }, data_access_summary: { compliance_scopes: count(SELECT * FROM compliance_scopes WHERE tenant_id = $tenant_id), authorization_decisions: count(SELECT * FROM authorization_access_evaluation_decisions WHERE tenant_id = $tenant_id) }, snapshot_hash: $snapshot_hash, source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() };
  CREATE audit_logs CONTENT { tenant_id: $tenant_id, actor_id: $actor_id, action: 'agent_governance_inventory_snapshot_created', resource_type: 'agent_governance_inventory_snapshots', resource_id: string::concat($snapshot.id), metadata: { snapshot_ref: $snapshot_ref, agent_count: count($agents), identity_count: count($identities), orphan_agent_count: count($orphan_agents) }, semantic_id: rand::uuid(), jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:Action', 'agx:AuditEvent'], time: { observed_at: time::now() }, created_at: time::now() };
  RETURN $snapshot;
};

DEFINE FUNCTION fn::compute_agent_governance_risk_level($aggregate_risk_score) {
  RETURN IF $aggregate_risk_score >= 0.80 THEN 'critical' ELSE IF $aggregate_risk_score >= 0.60 THEN 'high' ELSE IF $aggregate_risk_score >= 0.35 THEN 'medium' ELSE 'low' END END END;
};

DEFINE FUNCTION fn::create_agent_governance_risk_assessment($tenant_id, $subject_id, $scope_kind, $scope_ref, $inventory_snapshot_id, $identity_risk_score, $tool_risk_score, $data_risk_score, $autonomy_risk_score, $compliance_risk_score, $findings, $actor_id) {
  LET $aggregate = fn::clamp01((0.22 * $identity_risk_score) + (0.22 * $tool_risk_score) + (0.22 * $data_risk_score) + (0.18 * $autonomy_risk_score) + (0.16 * $compliance_risk_score));
  LET $risk_level = fn::compute_agent_governance_risk_level($aggregate);
  LET $decision_log = fn::log_decision_context($tenant_id, 'agent_governance_risk_assessment', $subject_id, $actor_id, NONE, NONE, { scope_kind: $scope_kind, scope_ref: $scope_ref, inventory_snapshot_id: $inventory_snapshot_id }, {}, {}, {}, {}, {}, {}, { standard_ref: 'github:microsoft/agent-governance-toolkit' }, [{ kind: 'identity_tool_data_autonomy_compliance_risk_scoring' }], { identity_risk_score: $identity_risk_score, tool_risk_score: $tool_risk_score, data_risk_score: $data_risk_score, autonomy_risk_score: $autonomy_risk_score, compliance_risk_score: $compliance_risk_score, aggregate_risk_score: $aggregate, risk_level: $risk_level }, [{ decision: 'accept_current_risk' }, { decision: 'recommend_controls' }], { decision: IF $aggregate >= 0.35 THEN 'recommend_controls' ELSE 'accept_current_risk' END }, [], 'agent_governance_risk_assessed', { findings: $findings }, IF $inventory_snapshot_id = NONE THEN [] ELSE [$inventory_snapshot_id] END, NONE, [], false);
  RETURN CREATE agent_governance_risk_assessments CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, scope_kind: $scope_kind, scope_ref: $scope_ref, inventory_snapshot_id: $inventory_snapshot_id, identity_risk_score: fn::clamp01($identity_risk_score), tool_risk_score: fn::clamp01($tool_risk_score), data_risk_score: fn::clamp01($data_risk_score), autonomy_risk_score: fn::clamp01($autonomy_risk_score), compliance_risk_score: fn::clamp01($compliance_risk_score), aggregate_risk_score: $aggregate, risk_level: $risk_level, findings: $findings, remediation_task_ids: [], decision_log_id: $decision_log.id, source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() };
};

DEFINE FUNCTION fn::recommend_agent_governance_controls($tenant_id, $risk_assessment_id, $actor_id) {
  LET $risk = SELECT * FROM $risk_assessment_id;
  IF count($risk) = 0 THEN { THROW 'agent_governance_risk_assessment_not_found'; };
  LET $recommendations = [];
  IF $risk[0].identity_risk_score >= 0.35 THEN { LET $recommendations += [(CREATE agent_governance_control_recommendations CONTENT { tenant_id: $tenant_id, risk_assessment_id: $risk_assessment_id, recommendation_kind: 'identity_control', title: 'Strengthen agent identity ownership and credential governance', description: 'Ensure every agent has an owner, verified identity credentials, scoped sessions, and revocation workflow.', priority: IF $risk[0].identity_risk_score >= 0.60 THEN 'high' ELSE 'medium' END, status: 'open', source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() }).id]; };
  IF $risk[0].tool_risk_score >= 0.35 THEN { LET $recommendations += [(CREATE agent_governance_control_recommendations CONTENT { tenant_id: $tenant_id, risk_assessment_id: $risk_assessment_id, recommendation_kind: 'tool_control', title: 'Restrict and observe agent tool access', description: 'Apply tool allowlists, approval policy, OpenID access evaluation, OPA policy, and OpenFGA relationship checks.', priority: IF $risk[0].tool_risk_score >= 0.60 THEN 'high' ELSE 'medium' END, status: 'open', source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() }).id]; };
  IF $risk[0].data_risk_score >= 0.35 THEN { LET $recommendations += [(CREATE agent_governance_control_recommendations CONTENT { tenant_id: $tenant_id, risk_assessment_id: $risk_assessment_id, recommendation_kind: 'data_control', title: 'Constrain data access and memory retention', description: 'Require data classification, compliance scope, memory minimization, decision logging, and evidence hashing.', priority: IF $risk[0].data_risk_score >= 0.60 THEN 'high' ELSE 'medium' END, status: 'open', source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() }).id]; };
  IF $risk[0].autonomy_risk_score >= 0.35 THEN { LET $recommendations += [(CREATE agent_governance_control_recommendations CONTENT { tenant_id: $tenant_id, risk_assessment_id: $risk_assessment_id, recommendation_kind: 'autonomy_control', title: 'Bound agent autonomy with gated execution', description: 'Require context completeness, human approval for high-risk actions, AgentOps stage gates, and observable intermediate steps.', priority: IF $risk[0].autonomy_risk_score >= 0.60 THEN 'high' ELSE 'medium' END, status: 'open', source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() }).id]; };
  IF $risk[0].compliance_risk_score >= 0.35 THEN { LET $recommendations += [(CREATE agent_governance_control_recommendations CONTENT { tenant_id: $tenant_id, risk_assessment_id: $risk_assessment_id, recommendation_kind: 'compliance_control', title: 'Automate compliance evidence and gate enforcement', description: 'Collect hashed evidence, map controls, auto-assess compliance, open remediation tasks, and require proof snapshots.', priority: IF $risk[0].compliance_risk_score >= 0.60 THEN 'high' ELSE 'medium' END, status: 'open', source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() }).id]; };
  RETURN SELECT * FROM agent_governance_control_recommendations WHERE id INSIDE $recommendations;
};

DEFINE FUNCTION fn::create_agent_governance_posture_report($tenant_id, $report_ref, $scope_kind, $scope_ref, $inventory_snapshot_id, $risk_assessment_ids, $compliance_proof_snapshot_ids, $report_hash, $actor_id) {
  IF $report_hash = NONE OR string::len($report_hash) = 0 THEN { THROW 'agent_governance_posture_report_hash_required'; };
  LET $risks = SELECT * FROM agent_governance_risk_assessments WHERE id INSIDE $risk_assessment_ids;
  LET $proofs = SELECT * FROM compliance_proof_snapshots WHERE id INSIDE $compliance_proof_snapshot_ids;
  LET $mean_risk = IF count($risks) = 0 THEN 1 ELSE fn::clamp01(math::mean($risks[*].aggregate_risk_score)) END;
  LET $mean_compliance = IF count($proofs) = 0 THEN 0 ELSE fn::clamp01(math::mean($proofs[*].aggregate_score)) END;
  LET $posture_score = fn::clamp01((0.55 * (1 - $mean_risk)) + (0.45 * $mean_compliance));
  LET $posture_level = IF $posture_score >= 0.90 THEN 'optimized' ELSE IF $posture_score >= 0.75 THEN 'managed' ELSE IF $posture_score >= 0.50 THEN 'developing' ELSE 'weak' END END END;
  LET $decision_log = fn::log_decision_context($tenant_id, 'agent_governance_posture_report', string::concat($scope_ref), $actor_id, NONE, NONE, { report_ref: $report_ref, scope_kind: $scope_kind, scope_ref: $scope_ref }, {}, {}, {}, {}, {}, {}, { standard_ref: 'github:microsoft/agent-governance-toolkit' }, [{ kind: 'inventory_risk_compliance_proof_required' }, { kind: 'report_hash_required' }], { mean_risk: $mean_risk, mean_compliance: $mean_compliance, posture_score: $posture_score, posture_level: $posture_level }, [{ decision: 'publish_posture_report' }, { decision: 'block_report' }], { decision: 'publish_posture_report' }, [], 'agent_governance_posture_report_created', { report_hash: $report_hash }, array::concat($risk_assessment_ids, $compliance_proof_snapshot_ids), NONE, [], false);
  RETURN CREATE agent_governance_posture_reports CONTENT { tenant_id: $tenant_id, report_ref: $report_ref, scope_kind: $scope_kind, scope_ref: $scope_ref, inventory_snapshot_id: $inventory_snapshot_id, risk_assessment_ids: $risk_assessment_ids, compliance_proof_snapshot_ids: $compliance_proof_snapshot_ids, posture_score: $posture_score, posture_level: $posture_level, report_hash: $report_hash, decision_log_id: $decision_log.id, source_grounding_refs: ['github:microsoft/agent-governance-toolkit'], created_at: time::now() };
};

DEFINE FUNCTION fn::require_agent_governance_posture($posture_report_id, $min_posture_score) {
  LET $report = SELECT * FROM $posture_report_id;
  IF count($report) = 0 THEN { THROW 'agent_governance_posture_report_required'; };
  IF $report[0].posture_score < $min_posture_score THEN { THROW 'agent_governance_posture_too_low'; };
  RETURN true;
};
