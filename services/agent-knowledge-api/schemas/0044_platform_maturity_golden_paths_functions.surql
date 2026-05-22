DEFINE TABLE platform_maturity_models SCHEMAFULL;
DEFINE FIELD tenant_id ON platform_maturity_models TYPE option<record<tenants>>;
DEFINE FIELD key ON platform_maturity_models TYPE string;
DEFINE FIELD name ON platform_maturity_models TYPE string;
DEFINE FIELD model_uri ON platform_maturity_models TYPE option<string>;
DEFINE FIELD levels ON platform_maturity_models TYPE array<object> DEFAULT [];
DEFINE FIELD dimensions ON platform_maturity_models TYPE array<string> DEFAULT [];
DEFINE FIELD status ON platform_maturity_models TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON platform_maturity_models TYPE datetime DEFAULT time::now();
DEFINE INDEX platform_maturity_models_key_unique ON platform_maturity_models FIELDS tenant_id, key UNIQUE;

DEFINE TABLE platform_capability_catalog SCHEMAFULL;
DEFINE FIELD tenant_id ON platform_capability_catalog TYPE option<record<tenants>>;
DEFINE FIELD key ON platform_capability_catalog TYPE string;
DEFINE FIELD name ON platform_capability_catalog TYPE string;
DEFINE FIELD category ON platform_capability_catalog TYPE string;
DEFINE FIELD description ON platform_capability_catalog TYPE string;
DEFINE FIELD maturity_dimension ON platform_capability_catalog TYPE string;
DEFINE FIELD implementation_refs ON platform_capability_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD owner_id ON platform_capability_catalog TYPE option<string>;
DEFINE FIELD status ON platform_capability_catalog TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON platform_capability_catalog TYPE datetime DEFAULT time::now();
DEFINE INDEX platform_capability_catalog_key_unique ON platform_capability_catalog FIELDS tenant_id, key UNIQUE;

DEFINE TABLE platform_golden_paths SCHEMAFULL;
DEFINE FIELD tenant_id ON platform_golden_paths TYPE option<record<tenants>>;
DEFINE FIELD key ON platform_golden_paths TYPE string;
DEFINE FIELD name ON platform_golden_paths TYPE string;
DEFINE FIELD description ON platform_golden_paths TYPE string;
DEFINE FIELD path_kind ON platform_golden_paths TYPE string;
DEFINE FIELD blueprint_template ON platform_golden_paths TYPE object DEFAULT {};
DEFINE FIELD required_capability_keys ON platform_golden_paths TYPE array<string> DEFAULT [];
DEFINE FIELD required_schema_refs ON platform_golden_paths TYPE array<string> DEFAULT [];
DEFINE FIELD setup_steps ON platform_golden_paths TYPE array<object> DEFAULT [];
DEFINE FIELD validation_steps ON platform_golden_paths TYPE array<object> DEFAULT [];
DEFINE FIELD default_guardrails ON platform_golden_paths TYPE array<object> DEFAULT [];
DEFINE FIELD default_slos ON platform_golden_paths TYPE array<object> DEFAULT [];
DEFINE FIELD status ON platform_golden_paths TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON platform_golden_paths TYPE datetime DEFAULT time::now();
DEFINE INDEX platform_golden_paths_key_unique ON platform_golden_paths FIELDS tenant_id, key UNIQUE;

DEFINE TABLE platform_maturity_assessments SCHEMAFULL;
DEFINE FIELD tenant_id ON platform_maturity_assessments TYPE option<record<tenants>>;
DEFINE FIELD assessment_ref ON platform_maturity_assessments TYPE string;
DEFINE FIELD model_id ON platform_maturity_assessments TYPE record<platform_maturity_models>;
DEFINE FIELD scope_kind ON platform_maturity_assessments TYPE string;
DEFINE FIELD scope_ref ON platform_maturity_assessments TYPE option<record>;
DEFINE FIELD self_service_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD developer_experience_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD operations_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD security_governance_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD observability_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD reliability_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD adoption_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD aggregate_score ON platform_maturity_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD maturity_level ON platform_maturity_assessments TYPE int DEFAULT 1;
DEFINE FIELD evidence_refs ON platform_maturity_assessments TYPE array<record> DEFAULT [];
DEFINE FIELD findings ON platform_maturity_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD decision_log_id ON platform_maturity_assessments TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON platform_maturity_assessments TYPE datetime DEFAULT time::now();
DEFINE INDEX platform_maturity_assessments_ref_unique ON platform_maturity_assessments FIELDS tenant_id, assessment_ref UNIQUE;

DEFINE TABLE platform_maturity_recommendations SCHEMAFULL;
DEFINE FIELD tenant_id ON platform_maturity_recommendations TYPE option<record<tenants>>;
DEFINE FIELD assessment_id ON platform_maturity_recommendations TYPE record<platform_maturity_assessments>;
DEFINE FIELD recommendation_kind ON platform_maturity_recommendations TYPE string;
DEFINE FIELD priority ON platform_maturity_recommendations TYPE string DEFAULT 'medium';
DEFINE FIELD title ON platform_maturity_recommendations TYPE string;
DEFINE FIELD description ON platform_maturity_recommendations TYPE string;
DEFINE FIELD target_dimension ON platform_maturity_recommendations TYPE string;
DEFINE FIELD implementation_refs ON platform_maturity_recommendations TYPE array<string> DEFAULT [];
DEFINE FIELD status ON platform_maturity_recommendations TYPE string DEFAULT 'open';
DEFINE FIELD created_at ON platform_maturity_recommendations TYPE datetime DEFAULT time::now();

UPSERT platform_maturity_models:cncf_platform_maturity CONTENT { tenant_id: NONE, key: 'cncf_platform_maturity', name: 'CNCF-style Platform Maturity Model', model_uri: 'https://tag-app-delivery.cncf.io/whitepapers/platforms/', levels: [{ level: 1, name: 'ad_hoc' }, { level: 2, name: 'repeatable' }, { level: 3, name: 'defined' }, { level: 4, name: 'managed' }, { level: 5, name: 'optimized' }], dimensions: ['self_service', 'developer_experience', 'operations', 'security_governance', 'observability', 'reliability', 'adoption'], status: 'active' };

UPSERT platform_capability_catalog:agent_builder CONTENT { tenant_id: NONE, key: 'agent_builder', name: 'Agent Builder APIs', category: 'self_service', description: 'APIs for application, project, task, agent blueprint and execution planning flows.', maturity_dimension: 'self_service', implementation_refs: ['src/routes/agent-builder.mjs', 'surreal/schema/0041_agent_capability_knowledge_memory_guardrails_functions.surql'], status: 'active' };
UPSERT platform_capability_catalog:governance_controls CONTENT { tenant_id: NONE, key: 'governance_controls', name: 'Governance Controls', category: 'security_governance', description: 'Identity, authorization, compliance, OPA, OpenFGA and release gate controls.', maturity_dimension: 'security_governance', implementation_refs: ['surreal/schema/0024_security_compliance_governance_frameworks.surql', 'surreal/schema/0033_open_policy_agent_integration_functions.surql', 'surreal/schema/0034_openfga_relationship_authorization_functions.surql'], status: 'active' };
UPSERT platform_capability_catalog:observability CONTENT { tenant_id: NONE, key: 'observability', name: 'Observability and Debuggability', category: 'operations', description: 'Traces, telemetry, usage, health checks, adoption tracking and debug bundles.', maturity_dimension: 'observability', implementation_refs: ['surreal/schema/0042_telemetry_traces_analytics_debuggability_functions.surql'], status: 'active' };
UPSERT platform_capability_catalog:release_certification CONTENT { tenant_id: NONE, key: 'release_certification', name: 'Release Certification', category: 'operations', description: 'Release readiness, manifests, CI workflow, runtime checks and certification.', maturity_dimension: 'operations', implementation_refs: ['surreal/schema/0039_release_readiness_functions.surql', 'surreal/schema/0040_release_manifest_and_ci_functions.surql', '.github/workflows/release-readiness.yml'], status: 'active' };
UPSERT platform_capability_catalog:distribution CONTENT { tenant_id: NONE, key: 'distribution', name: 'Distribution', category: 'developer_experience', description: 'Docker and npm packaging.', maturity_dimension: 'developer_experience', implementation_refs: ['Dockerfile', 'package.json'], status: 'active' };

UPSERT platform_golden_paths:research_agent CONTENT { tenant_id: NONE, key: 'research_agent', name: 'Research Agent Golden Path', description: 'Default governed path for grounded research and synthesis agents.', path_kind: 'agent_blueprint', required_capability_keys: ['agent_builder', 'governance_controls', 'observability'], required_schema_refs: ['0041', '0042', '0032', '0033', '0034'], blueprint_template: { skills: ['research', 'synthesis', 'citation_grounding'], memory: 'graph_ranked', guardrails: ['source_grounding_required', 'context_completeness_required'], constitution: ['truthfulness', 'citation_required_for_factual_claims'] }, setup_steps: [{ step: 1, action: 'create_knowledge_base' }, { step: 2, action: 'create_skill_catalog_entries' }, { step: 3, action: 'create_agent_blueprint' }, { step: 4, action: 'activate_blueprint' }], validation_steps: [{ action: 'require_agent_blueprint_complete' }, { action: 'run_release_readiness' }], default_guardrails: [{ kind: 'source_grounding_required' }, { kind: 'no_uncited_claims' }], default_slos: [{ metric: 'citation_coverage', target: 0.95 }], status: 'active' };
UPSERT platform_golden_paths:coding_agent CONTENT { tenant_id: NONE, key: 'coding_agent', name: 'Coding Agent Golden Path', description: 'Default governed path for coding, repo modification and release automation agents.', path_kind: 'agent_blueprint', required_capability_keys: ['agent_builder', 'governance_controls', 'observability', 'release_certification'], required_schema_refs: ['0041', '0042', '0039', '0040'], blueprint_template: { skills: ['code_generation', 'test_generation', 'release_readiness'], memory: 'graph_ranked', guardrails: ['no_stubbed_code', 'tests_required', 'release_gate_required'], constitution: ['production_readiness', 'human_approval_for_release'] }, setup_steps: [{ step: 1, action: 'create_repo_context' }, { step: 2, action: 'create_constraints' }, { step: 3, action: 'create_blueprint' }, { step: 4, action: 'run_ci_release_readiness' }], validation_steps: [{ action: 'integration_tests_pass' }, { action: 'release_certified' }], default_guardrails: [{ kind: 'no_secrets' }, { kind: 'schema_parse_required' }], default_slos: [{ metric: 'ci_pass_rate', target: 1 }], status: 'active' };
UPSERT platform_golden_paths:commerce_agent CONTENT { tenant_id: NONE, key: 'commerce_agent', name: 'Commerce Agent Golden Path', description: 'Default governed path for commerce and payment-capable agents.', path_kind: 'agent_blueprint', required_capability_keys: ['agent_builder', 'governance_controls', 'observability'], required_schema_refs: ['0036', '0037', '0041', '0042'], blueprint_template: { skills: ['shopping', 'payment_request', 'order_tracking'], guardrails: ['mandate_required', 'human_approval_required', 'payment_capture_required'], constitution: ['least_privilege_payments', 'human_authority_required'] }, setup_steps: [{ step: 1, action: 'register_payment_provider' }, { step: 2, action: 'create_payment_policy' }, { step: 3, action: 'create_agent_blueprint' }], validation_steps: [{ action: 'ap2_mandate_required' }, { action: 'ucp_order_requires_capture' }], default_guardrails: [{ kind: 'payment_requires_signed_mandate' }, { kind: 'merchant_trust_required' }], default_slos: [{ metric: 'payment_policy_enforcement', target: 1 }], status: 'active' };

DEFINE FUNCTION fn::compute_platform_maturity_level($aggregate_score) {
  RETURN IF $aggregate_score >= 0.90 THEN 5 ELSE IF $aggregate_score >= 0.75 THEN 4 ELSE IF $aggregate_score >= 0.55 THEN 3 ELSE IF $aggregate_score >= 0.35 THEN 2 ELSE 1 END END END END;
};

DEFINE FUNCTION fn::assess_platform_maturity($tenant_id, $assessment_ref, $scope_kind, $scope_ref, $actor_id) {
  LET $model = platform_maturity_models:cncf_platform_maturity;
  LET $capabilities = SELECT * FROM platform_capability_catalog WHERE tenant_id = NONE OR tenant_id = $tenant_id;
  LET $golden_paths = SELECT * FROM platform_golden_paths WHERE tenant_id = NONE OR tenant_id = $tenant_id;
  LET $traces = SELECT * FROM trace_sessions WHERE tenant_id = $tenant_id LIMIT 100;
  LET $usage = SELECT * FROM usage_events WHERE tenant_id = $tenant_id LIMIT 100;
  LET $health = SELECT * FROM health_checks WHERE tenant_id = $tenant_id LIMIT 100;
  LET $posture = SELECT * FROM agent_governance_posture_reports WHERE tenant_id = $tenant_id ORDER BY created_at DESC LIMIT 1;
  LET $release = SELECT * FROM release_candidates WHERE tenant_id = $tenant_id AND status = 'certified_release_ready' LIMIT 10;
  LET $self_service = fn::clamp01((count(SELECT * FROM $capabilities WHERE maturity_dimension = 'self_service') / 3) * 0.5 + (count($golden_paths) / 5) * 0.5);
  LET $dx = fn::clamp01((count(SELECT * FROM $capabilities WHERE maturity_dimension = 'developer_experience') / 3) * 0.6 + 0.4);
  LET $ops = fn::clamp01((count(SELECT * FROM $capabilities WHERE maturity_dimension = 'operations') / 3) * 0.5 + (count($release) > 0 ? 0.5 : 0));
  LET $security = IF count($posture) > 0 THEN $posture[0].posture_score ELSE fn::clamp01(count(SELECT * FROM $capabilities WHERE maturity_dimension = 'security_governance') / 3) END;
  LET $observability = fn::clamp01((count(SELECT * FROM $capabilities WHERE maturity_dimension = 'observability') / 2) * 0.5 + (count($traces) > 0 ? 0.2 : 0) + (count($usage) > 0 ? 0.15 : 0) + (count($health) > 0 ? 0.15 : 0));
  LET $reliability = fn::clamp01((count($release) > 0 ? 0.5 : 0) + (count($health) > 0 ? 0.25 : 0) + (count(SELECT * FROM reliability_profiles WHERE tenant_id = $tenant_id LIMIT 10) > 0 ? 0.25 : 0));
  LET $adoption = fn::clamp01(IF count(SELECT * FROM adoption_snapshots WHERE tenant_id = $tenant_id LIMIT 1) > 0 THEN (SELECT * FROM adoption_snapshots WHERE tenant_id = $tenant_id ORDER BY measured_at DESC LIMIT 1)[0].adoption_score ELSE (count($usage) / 100) END);
  LET $aggregate = fn::clamp01(($self_service + $dx + $ops + $security + $observability + $reliability + $adoption) / 7);
  LET $level = fn::compute_platform_maturity_level($aggregate);
  LET $decision_log = fn::log_decision_context($tenant_id, 'platform_maturity_assessment', string::concat($scope_ref), $actor_id, NONE, NONE, { scope_kind: $scope_kind, scope_ref: $scope_ref }, {}, {}, {}, {}, {}, {}, { model_id: $model.id, dimensions: $model.dimensions }, [{ kind: 'maturity_dimensions_scored' }], { self_service: $self_service, developer_experience: $dx, operations: $ops, security_governance: $security, observability: $observability, reliability: $reliability, adoption: $adoption, aggregate: $aggregate, level: $level }, [{ decision: 'record_assessment' }], { decision: 'record_assessment' }, [], 'platform_maturity_assessed', { capability_count: count($capabilities), golden_path_count: count($golden_paths) }, array::concat($capabilities[*].id, $golden_paths[*].id), NONE, [], false);
  RETURN CREATE platform_maturity_assessments CONTENT { tenant_id: $tenant_id, assessment_ref: $assessment_ref, model_id: $model.id, scope_kind: $scope_kind, scope_ref: $scope_ref, self_service_score: $self_service, developer_experience_score: $dx, operations_score: $ops, security_governance_score: $security, observability_score: $observability, reliability_score: $reliability, adoption_score: $adoption, aggregate_score: $aggregate, maturity_level: $level, evidence_refs: array::concat($capabilities[*].id, $golden_paths[*].id), findings: [], decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::recommend_platform_maturity_improvements($tenant_id, $assessment_id) {
  LET $a = SELECT * FROM $assessment_id;
  IF count($a) = 0 THEN { THROW 'platform_maturity_assessment_not_found'; };
  LET $created = [];
  IF $a[0].self_service_score < 0.75 THEN { LET $created += [(CREATE platform_maturity_recommendations CONTENT { tenant_id: $tenant_id, assessment_id: $assessment_id, recommendation_kind: 'golden_path', priority: 'high', title: 'Expand golden path self-service flows', description: 'Add UI-ready workflow APIs, async operation tracking, and one-click blueprint creation for common agent types.', target_dimension: 'self_service', implementation_refs: ['src/routes/agent-builder.mjs', 'surreal/schema/0044_platform_maturity_golden_paths_functions.surql'], status: 'open', created_at: time::now() }).id]; };
  IF $a[0].developer_experience_score < 0.75 THEN { LET $created += [(CREATE platform_maturity_recommendations CONTENT { tenant_id: $tenant_id, assessment_id: $assessment_id, recommendation_kind: 'developer_experience', priority: 'high', title: 'Add SDK, CLI, examples and generated clients', description: 'Ship TypeScript SDK, CLI commands, OpenAPI coverage and working examples for each golden path.', target_dimension: 'developer_experience', implementation_refs: ['package.json', 'src/openapi.mjs'], status: 'open', created_at: time::now() }).id]; };
  IF $a[0].operations_score < 0.75 THEN { LET $created += [(CREATE platform_maturity_recommendations CONTENT { tenant_id: $tenant_id, assessment_id: $assessment_id, recommendation_kind: 'operations', priority: 'high', title: 'Add Kubernetes and Helm deployment artifacts', description: 'Add Helm chart, migration job, probes, resource limits, network policy and production values.', target_dimension: 'operations', implementation_refs: ['Dockerfile', 'helm/agent-be'], status: 'open', created_at: time::now() }).id]; };
  IF $a[0].observability_score < 0.75 THEN { LET $created += [(CREATE platform_maturity_recommendations CONTENT { tenant_id: $tenant_id, assessment_id: $assessment_id, recommendation_kind: 'observability', priority: 'medium', title: 'Wire telemetry middleware into every API route', description: 'Automatically create trace sessions, route spans, usage events, health records and debug bundles from Fastify middleware.', target_dimension: 'observability', implementation_refs: ['surreal/schema/0042_telemetry_traces_analytics_debuggability_functions.surql', 'src/plugins/telemetry.mjs'], status: 'open', created_at: time::now() }).id]; };
  IF $a[0].reliability_score < 0.75 THEN { LET $created += [(CREATE platform_maturity_recommendations CONTENT { tenant_id: $tenant_id, assessment_id: $assessment_id, recommendation_kind: 'reliability', priority: 'medium', title: 'Add SLO and incident management model', description: 'Track service objectives, error budgets, incidents, escalations and postmortems as release gates.', target_dimension: 'reliability', implementation_refs: ['surreal/schema/0045_slo_incident_management_functions.surql'], status: 'open', created_at: time::now() }).id]; };
  RETURN SELECT * FROM platform_maturity_recommendations WHERE id INSIDE $created;
};

DEFINE FUNCTION fn::require_platform_maturity_level($assessment_id, $min_level) {
  LET $a = SELECT * FROM $assessment_id;
  IF count($a) = 0 THEN { THROW 'platform_maturity_assessment_required'; };
  IF $a[0].maturity_level < $min_level THEN { THROW 'platform_maturity_level_too_low'; };
  RETURN true;
};
