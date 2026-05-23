DEFINE TABLE release_readiness_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON release_readiness_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON release_readiness_policies TYPE string;
DEFINE FIELD name ON release_readiness_policies TYPE string;
DEFINE FIELD min_schema_validation_score ON release_readiness_policies TYPE number DEFAULT 1 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_test_pass_rate ON release_readiness_policies TYPE number DEFAULT 1 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_compliance_score ON release_readiness_policies TYPE number DEFAULT 0.85 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_governance_posture_score ON release_readiness_policies TYPE number DEFAULT 0.75 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD min_agentops_maturity_level ON release_readiness_policies TYPE int DEFAULT 2;
DEFINE FIELD require_schema_validation ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD require_surreal_parse_validation ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD require_integration_tests ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD require_security_scan ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD require_compliance_proof ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD require_governance_posture ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD require_agentops_gate ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD require_human_approval ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD enabled ON release_readiness_policies TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON release_readiness_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_readiness_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ReleaseReadinessPolicy'];
DEFINE FIELD created_at ON release_readiness_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX release_readiness_policies_key_unique ON release_readiness_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE release_candidates SCHEMAFULL;
DEFINE FIELD tenant_id ON release_candidates TYPE option<record<tenants>>;
DEFINE FIELD release_ref ON release_candidates TYPE string;
DEFINE FIELD version ON release_candidates TYPE string;
DEFINE FIELD git_commit_sha ON release_candidates TYPE string;
DEFINE FIELD git_branch ON release_candidates TYPE string DEFAULT 'main';
DEFINE FIELD artifact_hash ON release_candidates TYPE string;
DEFINE FIELD application_id ON release_candidates TYPE option<record<applications>>;
DEFINE FIELD project_id ON release_candidates TYPE option<record<projects>>;
DEFINE FIELD status ON release_candidates TYPE string DEFAULT 'created';
DEFINE FIELD source_grounding_refs ON release_candidates TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON release_candidates TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_candidates TYPE array<string> DEFAULT ['schema:SoftwareSourceCode', 'agx:ReleaseCandidate'];
DEFINE FIELD created_at ON release_candidates TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON release_candidates TYPE datetime DEFAULT time::now();
DEFINE INDEX release_candidates_ref_unique ON release_candidates FIELDS tenant_id, release_ref UNIQUE;

DEFINE TABLE release_validation_results SCHEMAFULL;
DEFINE FIELD tenant_id ON release_validation_results TYPE option<record<tenants>>;
DEFINE FIELD release_candidate_id ON release_validation_results TYPE record<release_candidates>;
DEFINE FIELD validation_kind ON release_validation_results TYPE string;
DEFINE FIELD status ON release_validation_results TYPE string;
DEFINE FIELD score ON release_validation_results TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD findings ON release_validation_results TYPE array<object> DEFAULT [];
DEFINE FIELD evidence_ids ON release_validation_results TYPE array<record> DEFAULT [];
DEFINE FIELD payload_hash ON release_validation_results TYPE string;
DEFINE FIELD created_at ON release_validation_results TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON release_validation_results TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_validation_results TYPE array<string> DEFAULT ['schema:ReviewAction', 'agx:ReleaseValidationResult'];

DEFINE TABLE release_readiness_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON release_readiness_decisions TYPE option<record<tenants>>;
DEFINE FIELD release_candidate_id ON release_readiness_decisions TYPE record<release_candidates>;
DEFINE FIELD policy_id ON release_readiness_decisions TYPE record<release_readiness_policies>;
DEFINE FIELD decision ON release_readiness_decisions TYPE string;
DEFINE FIELD reason ON release_readiness_decisions TYPE string;
DEFINE FIELD validation_result_ids ON release_readiness_decisions TYPE array<record<release_validation_results>> DEFAULT [];
DEFINE FIELD compliance_proof_snapshot_id ON release_readiness_decisions TYPE option<record<compliance_proof_snapshots>>;
DEFINE FIELD governance_posture_report_id ON release_readiness_decisions TYPE option<record<agent_governance_posture_reports>>;
DEFINE FIELD agentops_gate_decision_id ON release_readiness_decisions TYPE option<record<agentops_gate_decisions>>;
DEFINE FIELD human_approval_required ON release_readiness_decisions TYPE bool DEFAULT true;
DEFINE FIELD human_response_status ON release_readiness_decisions TYPE string DEFAULT 'pending';
DEFINE FIELD decision_log_id ON release_readiness_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON release_readiness_decisions TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON release_readiness_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_readiness_decisions TYPE array<string> DEFAULT ['schema:Action', 'agx:ReleaseReadinessDecision'];

UPSERT release_readiness_policies:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default Release Readiness Policy', min_schema_validation_score: 1, min_test_pass_rate: 1, min_compliance_score: 0.85, min_governance_posture_score: 0.75, min_agentops_maturity_level: 2, require_schema_validation: true, require_surreal_parse_validation: true, require_integration_tests: true, require_security_scan: true, require_compliance_proof: true, require_governance_posture: true, require_agentops_gate: true, require_human_approval: true, enabled: true };

DEFINE FUNCTION fn::select_release_readiness_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM release_readiness_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM release_readiness_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN release_readiness_policies:default;
};

DEFINE FUNCTION fn::create_release_candidate($tenant_id, $release_ref, $version, $git_commit_sha, $git_branch, $artifact_hash, $application_id, $project_id, $source_grounding_refs) {
  IF $git_commit_sha = NONE OR string::len($git_commit_sha) = 0 THEN { THROW 'release_git_commit_sha_required'; };
  IF $artifact_hash = NONE OR string::len($artifact_hash) = 0 THEN { THROW 'release_artifact_hash_required'; };
  RETURN CREATE release_candidates CONTENT { tenant_id: $tenant_id, release_ref: $release_ref, version: $version, git_commit_sha: $git_commit_sha, git_branch: $git_branch, artifact_hash: $artifact_hash, application_id: $application_id, project_id: $project_id, status: 'created', source_grounding_refs: $source_grounding_refs, created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::record_release_validation_result($tenant_id, $release_candidate_id, $validation_kind, $status, $score, $findings, $evidence_ids, $payload_hash) {
  LET $candidate = SELECT * FROM $release_candidate_id;
  IF count($candidate) = 0 THEN { THROW 'release_candidate_not_found'; };
  IF $payload_hash = NONE OR string::len($payload_hash) = 0 THEN { THROW 'release_validation_payload_hash_required'; };
  RETURN CREATE release_validation_results CONTENT { tenant_id: $tenant_id, release_candidate_id: $release_candidate_id, validation_kind: $validation_kind, status: $status, score: fn::clamp01($score), findings: $findings, evidence_ids: $evidence_ids, payload_hash: $payload_hash, created_at: time::now() };
};

DEFINE FUNCTION fn::evaluate_release_readiness($tenant_id, $release_candidate_id, $policy_key, $compliance_proof_snapshot_id, $governance_posture_report_id, $agentops_gate_decision_id, $actor_id) {
  LET $candidate = SELECT * FROM $release_candidate_id;
  IF count($candidate) = 0 THEN { THROW 'release_candidate_not_found'; };
  LET $policy = fn::select_release_readiness_policy($tenant_id, $policy_key);
  LET $validations = SELECT * FROM release_validation_results WHERE release_candidate_id = $release_candidate_id;
  LET $schema = SELECT * FROM $validations WHERE validation_kind = 'schema_validation' LIMIT 1;
  LET $parse = SELECT * FROM $validations WHERE validation_kind = 'surreal_parse_validation' LIMIT 1;
  LET $tests = SELECT * FROM $validations WHERE validation_kind = 'integration_tests' LIMIT 1;
  LET $security = SELECT * FROM $validations WHERE validation_kind = 'security_scan' LIMIT 1;
  IF $policy.require_schema_validation AND (count($schema) = 0 OR $schema[0].score < $policy.min_schema_validation_score OR $schema[0].status != 'passed') THEN { THROW 'release_schema_validation_failed'; };
  IF $policy.require_surreal_parse_validation AND (count($parse) = 0 OR $parse[0].status != 'passed') THEN { THROW 'release_surreal_parse_validation_failed'; };
  IF $policy.require_integration_tests AND (count($tests) = 0 OR $tests[0].score < $policy.min_test_pass_rate OR $tests[0].status != 'passed') THEN { THROW 'release_integration_tests_failed'; };
  IF $policy.require_security_scan AND (count($security) = 0 OR $security[0].status != 'passed') THEN { THROW 'release_security_scan_failed'; };
  IF $policy.require_compliance_proof THEN { fn::require_automated_compliance_proof($tenant_id, (SELECT * FROM $compliance_proof_snapshot_id)[0].compliance_scope_id, 'default'); };
  IF $policy.require_governance_posture THEN { fn::require_agent_governance_posture($governance_posture_report_id, $policy.min_governance_posture_score); };
  IF $policy.require_agentops_gate THEN {
    LET $agentops = SELECT * FROM $agentops_gate_decision_id;
    IF count($agentops) = 0 THEN { THROW 'release_agentops_gate_required'; };
    IF $agentops[0].decision != 'approved' THEN { THROW 'release_agentops_gate_not_approved'; };
  };
  LET $decision_log = fn::log_decision_context($tenant_id, 'release_readiness_decision', string::concat($release_candidate_id), $actor_id, NONE, NONE, { release_candidate_id: $release_candidate_id, version: $candidate[0].version, git_commit_sha: $candidate[0].git_commit_sha, artifact_hash: $candidate[0].artifact_hash }, {}, {}, {}, {}, {}, {}, { policy_id: $policy.id, compliance_proof_snapshot_id: $compliance_proof_snapshot_id, governance_posture_report_id: $governance_posture_report_id, agentops_gate_decision_id: $agentops_gate_decision_id }, [{ kind: 'schema_validation_required' }, { kind: 'surreal_parse_validation_required' }, { kind: 'integration_tests_required' }, { kind: 'security_scan_required' }, { kind: 'compliance_proof_required' }, { kind: 'governance_posture_required' }, { kind: 'agentops_gate_required' }], { validation_result_ids: $validations[*].id }, [{ decision: 'release_ready' }, { decision: 'block_release' }], { decision: IF $policy.require_human_approval THEN 'pending_human_approval' ELSE 'release_ready' END }, [], 'release_readiness_evaluated', { validation_count: count($validations), human_approval_required: $policy.require_human_approval }, array::concat($validations[*].id, [$compliance_proof_snapshot_id, $governance_posture_report_id, $agentops_gate_decision_id]), NONE, [], $policy.require_human_approval);
  LET $record = CREATE release_readiness_decisions CONTENT { tenant_id: $tenant_id, release_candidate_id: $release_candidate_id, policy_id: $policy.id, decision: IF $policy.require_human_approval THEN 'pending_human_approval' ELSE 'release_ready' END, reason: 'release_readiness_requirements_passed', validation_result_ids: $validations[*].id, compliance_proof_snapshot_id: $compliance_proof_snapshot_id, governance_posture_report_id: $governance_posture_report_id, agentops_gate_decision_id: $agentops_gate_decision_id, human_approval_required: $policy.require_human_approval, human_response_status: IF $policy.require_human_approval THEN 'pending' ELSE 'not_required' END, decision_log_id: $decision_log.id, created_at: time::now() };
  UPDATE $release_candidate_id SET status = IF $policy.require_human_approval THEN 'pending_release_approval' ELSE 'release_ready' END, updated_at = time::now();
  RETURN $record;
};

DEFINE FUNCTION fn::approve_release_readiness($release_readiness_decision_id, $human_actor_id, $approval_status, $response_text, $structured_response) {
  LET $decision = SELECT * FROM $release_readiness_decision_id;
  IF count($decision) = 0 THEN { THROW 'release_readiness_decision_not_found'; };
  IF !$decision[0].human_approval_required THEN { THROW 'human_approval_not_required'; };
  LET $response = fn::record_human_decision_response($decision[0].tenant_id, $decision[0].decision_log_id, NONE, NONE, $human_actor_id, 'release_readiness_approval', $response_text, $structured_response, [], [], [], $approval_status);
  UPDATE $release_readiness_decision_id SET decision = IF $approval_status = 'approved' THEN 'release_ready' ELSE 'blocked' END, human_response_status = $approval_status;
  UPDATE $decision[0].release_candidate_id SET status = IF $approval_status = 'approved' THEN 'release_ready' ELSE 'blocked' END, updated_at = time::now();
  RETURN SELECT * FROM $release_readiness_decision_id;
};

DEFINE FUNCTION fn::require_release_ready($release_readiness_decision_id) {
  LET $decision = SELECT * FROM $release_readiness_decision_id;
  IF count($decision) = 0 THEN { THROW 'release_readiness_decision_required'; };
  IF $decision[0].decision != 'release_ready' THEN { THROW 'release_not_ready'; };
  RETURN true;
};
