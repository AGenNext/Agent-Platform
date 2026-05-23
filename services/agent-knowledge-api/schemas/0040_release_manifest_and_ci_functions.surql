DEFINE TABLE release_manifests SCHEMAFULL;
DEFINE FIELD tenant_id ON release_manifests TYPE option<record<tenants>>;
DEFINE FIELD release_candidate_id ON release_manifests TYPE record<release_candidates>;
DEFINE FIELD manifest_ref ON release_manifests TYPE string;
DEFINE FIELD manifest_version ON release_manifests TYPE string;
DEFINE FIELD schema_file_count ON release_manifests TYPE int DEFAULT 0;
DEFINE FIELD schema_files ON release_manifests TYPE array<object> DEFAULT [];
DEFINE FIELD dependency_files ON release_manifests TYPE array<object> DEFAULT [];
DEFINE FIELD migration_order ON release_manifests TYPE array<string> DEFAULT [];
DEFINE FIELD required_runtime_services ON release_manifests TYPE array<string> DEFAULT [];
DEFINE FIELD required_external_protocols ON release_manifests TYPE array<string> DEFAULT [];
DEFINE FIELD compatibility_matrix ON release_manifests TYPE object DEFAULT {};
DEFINE FIELD rollback_plan ON release_manifests TYPE object DEFAULT {};
DEFINE FIELD manifest_hash ON release_manifests TYPE string;
DEFINE FIELD signed_by ON release_manifests TYPE option<string>;
DEFINE FIELD signature_payload ON release_manifests TYPE option<object>;
DEFINE FIELD decision_log_id ON release_manifests TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON release_manifests TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON release_manifests TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_manifests TYPE array<string> DEFAULT ['schema:SoftwareSourceCode', 'agx:ReleaseManifest'];
DEFINE INDEX release_manifests_ref_unique ON release_manifests FIELDS tenant_id, manifest_ref UNIQUE;

DEFINE TABLE release_ci_workflows SCHEMAFULL;
DEFINE FIELD tenant_id ON release_ci_workflows TYPE option<record<tenants>>;
DEFINE FIELD release_candidate_id ON release_ci_workflows TYPE record<release_candidates>;
DEFINE FIELD workflow_ref ON release_ci_workflows TYPE string;
DEFINE FIELD workflow_provider ON release_ci_workflows TYPE string DEFAULT 'github_actions';
DEFINE FIELD workflow_uri ON release_ci_workflows TYPE option<string>;
DEFINE FIELD run_id ON release_ci_workflows TYPE option<string>;
DEFINE FIELD commit_sha ON release_ci_workflows TYPE string;
DEFINE FIELD status ON release_ci_workflows TYPE string DEFAULT 'pending';
DEFINE FIELD conclusion ON release_ci_workflows TYPE option<string>;
DEFINE FIELD required_jobs ON release_ci_workflows TYPE array<string> DEFAULT [];
DEFINE FIELD completed_jobs ON release_ci_workflows TYPE array<object> DEFAULT [];
DEFINE FIELD artifact_ids ON release_ci_workflows TYPE array<string> DEFAULT [];
DEFINE FIELD log_hash ON release_ci_workflows TYPE option<string>;
DEFINE FIELD created_at ON release_ci_workflows TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON release_ci_workflows TYPE option<datetime>;
DEFINE FIELD jsonld_context ON release_ci_workflows TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_ci_workflows TYPE array<string> DEFAULT ['schema:Action', 'agx:ReleaseCIWorkflow'];
DEFINE INDEX release_ci_workflows_ref_unique ON release_ci_workflows FIELDS tenant_id, workflow_ref UNIQUE;

DEFINE TABLE release_runtime_checks SCHEMAFULL;
DEFINE FIELD tenant_id ON release_runtime_checks TYPE option<record<tenants>>;
DEFINE FIELD release_candidate_id ON release_runtime_checks TYPE record<release_candidates>;
DEFINE FIELD check_ref ON release_runtime_checks TYPE string;
DEFINE FIELD check_kind ON release_runtime_checks TYPE string;
DEFINE FIELD target_environment ON release_runtime_checks TYPE string;
DEFINE FIELD status ON release_runtime_checks TYPE string DEFAULT 'pending';
DEFINE FIELD score ON release_runtime_checks TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD findings ON release_runtime_checks TYPE array<object> DEFAULT [];
DEFINE FIELD evidence_ids ON release_runtime_checks TYPE array<record> DEFAULT [];
DEFINE FIELD payload_hash ON release_runtime_checks TYPE string;
DEFINE FIELD created_at ON release_runtime_checks TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON release_runtime_checks TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON release_runtime_checks TYPE array<string> DEFAULT ['schema:ReviewAction', 'agx:ReleaseRuntimeCheck'];
DEFINE INDEX release_runtime_checks_ref_unique ON release_runtime_checks FIELDS tenant_id, check_ref UNIQUE;

DEFINE FUNCTION fn::create_release_manifest($tenant_id, $release_candidate_id, $manifest_ref, $manifest_version, $schema_files, $dependency_files, $migration_order, $required_runtime_services, $required_external_protocols, $compatibility_matrix, $rollback_plan, $manifest_hash, $signed_by, $signature_payload, $actor_id) {
  LET $candidate = SELECT * FROM $release_candidate_id;
  IF count($candidate) = 0 THEN { THROW 'release_candidate_not_found'; };
  IF $manifest_hash = NONE OR string::len($manifest_hash) = 0 THEN { THROW 'release_manifest_hash_required'; };
  LET $decision_log = fn::log_decision_context($tenant_id, 'release_manifest_created', string::concat($release_candidate_id), $actor_id, NONE, NONE, { release_candidate_id: $release_candidate_id, manifest_ref: $manifest_ref, manifest_version: $manifest_version }, {}, {}, {}, {}, {}, {}, { compatibility_matrix: $compatibility_matrix, rollback_plan: $rollback_plan }, [{ kind: 'manifest_hash_required' }, { kind: 'migration_order_required' }, { kind: 'rollback_plan_required' }], { schema_file_count: count($schema_files), dependency_file_count: count($dependency_files), migration_order: $migration_order }, [{ decision: 'create_manifest' }, { decision: 'reject_manifest' }], { decision: 'create_manifest' }, [], 'release_manifest_recorded', { manifest_hash: $manifest_hash, signed_by: $signed_by }, [$release_candidate_id], NONE, [], false);
  RETURN CREATE release_manifests CONTENT { tenant_id: $tenant_id, release_candidate_id: $release_candidate_id, manifest_ref: $manifest_ref, manifest_version: $manifest_version, schema_file_count: count($schema_files), schema_files: $schema_files, dependency_files: $dependency_files, migration_order: $migration_order, required_runtime_services: $required_runtime_services, required_external_protocols: $required_external_protocols, compatibility_matrix: $compatibility_matrix, rollback_plan: $rollback_plan, manifest_hash: $manifest_hash, signed_by: $signed_by, signature_payload: $signature_payload, decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::record_release_ci_workflow($tenant_id, $release_candidate_id, $workflow_ref, $workflow_provider, $workflow_uri, $run_id, $commit_sha, $status, $conclusion, $required_jobs, $completed_jobs, $artifact_ids, $log_hash) {
  LET $candidate = SELECT * FROM $release_candidate_id;
  IF count($candidate) = 0 THEN { THROW 'release_candidate_not_found'; };
  IF $commit_sha != $candidate[0].git_commit_sha THEN { THROW 'release_ci_commit_sha_mismatch'; };
  RETURN CREATE release_ci_workflows CONTENT { tenant_id: $tenant_id, release_candidate_id: $release_candidate_id, workflow_ref: $workflow_ref, workflow_provider: $workflow_provider, workflow_uri: $workflow_uri, run_id: $run_id, commit_sha: $commit_sha, status: $status, conclusion: $conclusion, required_jobs: $required_jobs, completed_jobs: $completed_jobs, artifact_ids: $artifact_ids, log_hash: $log_hash, created_at: time::now(), completed_at: IF $status = 'completed' THEN time::now() ELSE NONE END };
};

DEFINE FUNCTION fn::record_release_runtime_check($tenant_id, $release_candidate_id, $check_ref, $check_kind, $target_environment, $status, $score, $findings, $evidence_ids, $payload_hash) {
  LET $candidate = SELECT * FROM $release_candidate_id;
  IF count($candidate) = 0 THEN { THROW 'release_candidate_not_found'; };
  IF $payload_hash = NONE OR string::len($payload_hash) = 0 THEN { THROW 'release_runtime_check_payload_hash_required'; };
  RETURN CREATE release_runtime_checks CONTENT { tenant_id: $tenant_id, release_candidate_id: $release_candidate_id, check_ref: $check_ref, check_kind: $check_kind, target_environment: $target_environment, status: $status, score: fn::clamp01($score), findings: $findings, evidence_ids: $evidence_ids, payload_hash: $payload_hash, created_at: time::now() };
};

DEFINE FUNCTION fn::require_release_manifest_complete($release_candidate_id) {
  LET $manifest = SELECT * FROM release_manifests WHERE release_candidate_id = $release_candidate_id ORDER BY created_at DESC LIMIT 1;
  IF count($manifest) = 0 THEN { THROW 'release_manifest_required'; };
  IF count($manifest[0].schema_files) = 0 THEN { THROW 'release_manifest_schema_files_required'; };
  IF count($manifest[0].migration_order) = 0 THEN { THROW 'release_manifest_migration_order_required'; };
  IF $manifest[0].rollback_plan = {} THEN { THROW 'release_manifest_rollback_plan_required'; };
  RETURN true;
};

DEFINE FUNCTION fn::require_release_ci_green($release_candidate_id) {
  LET $workflow = SELECT * FROM release_ci_workflows WHERE release_candidate_id = $release_candidate_id ORDER BY created_at DESC LIMIT 1;
  IF count($workflow) = 0 THEN { THROW 'release_ci_workflow_required'; };
  IF $workflow[0].status != 'completed' THEN { THROW 'release_ci_workflow_not_completed'; };
  IF $workflow[0].conclusion != 'success' THEN { THROW 'release_ci_workflow_not_successful'; };
  IF count($workflow[0].required_jobs) > count($workflow[0].completed_jobs) THEN { THROW 'release_ci_required_jobs_missing'; };
  RETURN true;
};

DEFINE FUNCTION fn::require_release_runtime_checks_passed($release_candidate_id) {
  LET $checks = SELECT * FROM release_runtime_checks WHERE release_candidate_id = $release_candidate_id;
  IF count($checks) = 0 THEN { THROW 'release_runtime_checks_required'; };
  LET $failed = SELECT * FROM $checks WHERE status != 'passed' OR score < 1;
  IF count($failed) > 0 THEN { THROW 'release_runtime_checks_failed'; };
  RETURN true;
};

DEFINE FUNCTION fn::certify_release_candidate($tenant_id, $release_candidate_id, $release_readiness_decision_id, $actor_id) {
  fn::require_release_manifest_complete($release_candidate_id);
  fn::require_release_ci_green($release_candidate_id);
  fn::require_release_runtime_checks_passed($release_candidate_id);
  fn::require_release_ready($release_readiness_decision_id);
  LET $candidate = SELECT * FROM $release_candidate_id;
  LET $decision_log = fn::log_decision_context($tenant_id, 'release_candidate_certification', string::concat($release_candidate_id), $actor_id, NONE, NONE, { release_candidate_id: $release_candidate_id, git_commit_sha: $candidate[0].git_commit_sha, artifact_hash: $candidate[0].artifact_hash }, {}, {}, {}, {}, {}, {}, { release_readiness_decision_id: $release_readiness_decision_id }, [{ kind: 'manifest_complete' }, { kind: 'ci_green' }, { kind: 'runtime_checks_passed' }, { kind: 'release_ready' }], { certified: true }, [{ decision: 'certify_release' }, { decision: 'block_release' }], { decision: 'certify_release' }, [], 'release_candidate_certified', { certified_at: time::now() }, [$release_candidate_id, $release_readiness_decision_id], NONE, [], false);
  UPDATE $release_candidate_id SET status = 'certified_release_ready', updated_at = time::now();
  RETURN { release_candidate_id: $release_candidate_id, certified: true, decision_log_id: $decision_log.id };
};
