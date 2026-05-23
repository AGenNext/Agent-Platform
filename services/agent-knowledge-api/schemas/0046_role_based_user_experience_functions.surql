DEFINE TABLE user_role_catalog SCHEMAFULL;
DEFINE FIELD tenant_id ON user_role_catalog TYPE option<record<tenants>>;
DEFINE FIELD key ON user_role_catalog TYPE string;
DEFINE FIELD name ON user_role_catalog TYPE string;
DEFINE FIELD job_function ON user_role_catalog TYPE string;
DEFINE FIELD seniority_level ON user_role_catalog TYPE string;
DEFINE FIELD description ON user_role_catalog TYPE string;
DEFINE FIELD default_capabilities ON user_role_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD default_landing_route ON user_role_catalog TYPE string;
DEFINE FIELD allowed_api_groups ON user_role_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD denied_api_groups ON user_role_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD default_guardrails ON user_role_catalog TYPE array<object> DEFAULT [];
DEFINE FIELD status ON user_role_catalog TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON user_role_catalog TYPE datetime DEFAULT time::now();
DEFINE INDEX user_role_catalog_key_unique ON user_role_catalog FIELDS tenant_id, key UNIQUE;

DEFINE TABLE user_role_assignments SCHEMAFULL;
DEFINE FIELD tenant_id ON user_role_assignments TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON user_role_assignments TYPE string;
DEFINE FIELD role_key ON user_role_assignments TYPE string;
DEFINE FIELD role_id ON user_role_assignments TYPE record<user_role_catalog>;
DEFINE FIELD seniority_level ON user_role_assignments TYPE string;
DEFINE FIELD job_function ON user_role_assignments TYPE string;
DEFINE FIELD scope_kind ON user_role_assignments TYPE string DEFAULT 'tenant';
DEFINE FIELD scope_ref ON user_role_assignments TYPE option<record>;
DEFINE FIELD status ON user_role_assignments TYPE string DEFAULT 'active';
DEFINE FIELD assigned_by ON user_role_assignments TYPE string;
DEFINE FIELD created_at ON user_role_assignments TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON user_role_assignments TYPE option<datetime>;
DEFINE INDEX user_role_assignments_unique ON user_role_assignments FIELDS tenant_id, subject_id, role_key, scope_kind, scope_ref UNIQUE;

DEFINE TABLE user_experience_views SCHEMAFULL;
DEFINE FIELD tenant_id ON user_experience_views TYPE option<record<tenants>>;
DEFINE FIELD role_key ON user_experience_views TYPE string;
DEFINE FIELD view_key ON user_experience_views TYPE string;
DEFINE FIELD name ON user_experience_views TYPE string;
DEFINE FIELD route ON user_experience_views TYPE string;
DEFINE FIELD api_group ON user_experience_views TYPE string;
DEFINE FIELD widgets ON user_experience_views TYPE array<object> DEFAULT [];
DEFINE FIELD actions ON user_experience_views TYPE array<object> DEFAULT [];
DEFINE FIELD status ON user_experience_views TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON user_experience_views TYPE datetime DEFAULT time::now();
DEFINE INDEX user_experience_views_unique ON user_experience_views FIELDS tenant_id, role_key, view_key UNIQUE;

DEFINE TABLE user_api_access_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON user_api_access_decisions TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON user_api_access_decisions TYPE string;
DEFINE FIELD role_key ON user_api_access_decisions TYPE string;
DEFINE FIELD api_group ON user_api_access_decisions TYPE string;
DEFINE FIELD route ON user_api_access_decisions TYPE string;
DEFINE FIELD action ON user_api_access_decisions TYPE string;
DEFINE FIELD allowed ON user_api_access_decisions TYPE bool DEFAULT false;
DEFINE FIELD reason ON user_api_access_decisions TYPE string;
DEFINE FIELD evidence_refs ON user_api_access_decisions TYPE array<record> DEFAULT [];
DEFINE FIELD decision_log_id ON user_api_access_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON user_api_access_decisions TYPE datetime DEFAULT time::now();

UPSERT user_role_catalog:junior_dev CONTENT { tenant_id: NONE, key: 'junior_dev', name: 'Junior Developer', job_function: 'engineering', seniority_level: 'junior', description: 'Builds features through guided golden paths with guardrails and review gates.', default_capabilities: ['view_assigned_tasks','create_blueprint_draft','run_tests','view_traces'], default_landing_route: '/user/engineering/junior', allowed_api_groups: ['profile','tasks','agent_builder_read','agent_builder_draft','traces_read','debug_read'], denied_api_groups: ['release_certify','admin_security','payments_admin'], default_guardrails: [{ kind: 'requires_senior_review_for_release' }], status: 'active' };
UPSERT user_role_catalog:senior_dev CONTENT { tenant_id: NONE, key: 'senior_dev', name: 'Senior Developer', job_function: 'engineering', seniority_level: 'senior', description: 'Owns implementation, reviews blueprints, manages releases and debugging.', default_capabilities: ['create_blueprint','activate_blueprint','evaluate_release','debug_traces','review_code'], default_landing_route: '/user/engineering/senior', allowed_api_groups: ['profile','tasks','agent_builder','traces_read','debug_write','release_engineering','maturity_read'], denied_api_groups: ['finance_admin','executive_admin'], default_guardrails: [{ kind: 'release_requires_policy_and_ci' }], status: 'active' };
UPSERT user_role_catalog:sre CONTENT { tenant_id: NONE, key: 'sre', name: 'Site Reliability Engineer', job_function: 'operations', seniority_level: 'senior', description: 'Owns reliability, health, telemetry, incidents, SLOs and postmortems.', default_capabilities: ['slo_manage','incident_manage','health_manage','trace_debug','release_gate'], default_landing_route: '/user/sre', allowed_api_groups: ['profile','health','slo','alerts','incidents','postmortems','traces_read','debug_write','release_read'], denied_api_groups: ['finance_admin','marketing_admin'], default_guardrails: [{ kind: 'incident_actions_audited' }], status: 'active' };
UPSERT user_role_catalog:qa CONTENT { tenant_id: NONE, key: 'qa', name: 'QA Engineer', job_function: 'quality', seniority_level: 'mid', description: 'Owns test validation, evaluation results, release validation and defect triage.', default_capabilities: ['record_validation','view_debug','open_defects','evaluate_quality'], default_landing_route: '/user/qa', allowed_api_groups: ['profile','tasks','release_validation','debug_read','traces_read','evaluation_read'], denied_api_groups: ['release_certify','finance_admin'], default_guardrails: [{ kind: 'quality_evidence_required' }], status: 'active' };
UPSERT user_role_catalog:designer CONTENT { tenant_id: NONE, key: 'designer', name: 'Designer', job_function: 'design', seniority_level: 'mid', description: 'Designs agent experiences, reviews workflows, collaboration spaces and user-facing prompts.', default_capabilities: ['view_golden_paths','review_prompts','create_collaboration_space','view_adoption'], default_landing_route: '/user/design', allowed_api_groups: ['profile','golden_paths_read','agent_builder_draft','prompt_read','adoption_read'], denied_api_groups: ['security_admin','release_certify'], default_guardrails: [{ kind: 'design_changes_need_product_review' }], status: 'active' };
UPSERT user_role_catalog:marketing CONTENT { tenant_id: NONE, key: 'marketing', name: 'Marketing', job_function: 'marketing', seniority_level: 'mid', description: 'Uses adoption analytics, content workflows and customer-facing agent insights.', default_capabilities: ['view_adoption','view_usage','create_content_agent_draft'], default_landing_route: '/user/marketing', allowed_api_groups: ['profile','adoption_read','usage_summary','golden_paths_read','agent_builder_draft'], denied_api_groups: ['security_admin','finance_admin','release_certify'], default_guardrails: [{ kind: 'no_sensitive_usage_export' }], status: 'active' };
UPSERT user_role_catalog:sales CONTENT { tenant_id: NONE, key: 'sales', name: 'Sales', job_function: 'sales', seniority_level: 'mid', description: 'Tracks customer-facing agent usage, demos, adoption and account workflows.', default_capabilities: ['view_customer_adoption','view_demo_agents','create_sales_agent_draft'], default_landing_route: '/user/sales', allowed_api_groups: ['profile','adoption_read','usage_summary','golden_paths_read','agent_builder_draft'], denied_api_groups: ['security_admin','release_certify','finance_admin'], default_guardrails: [{ kind: 'customer_data_minimization' }], status: 'active' };
UPSERT user_role_catalog:customer_success CONTENT { tenant_id: NONE, key: 'customer_success', name: 'Customer Success', job_function: 'customer_success', seniority_level: 'mid', description: 'Monitors customer health, adoption, support workflows and incidents.', default_capabilities: ['view_adoption','open_support_debug','view_health','view_incidents'], default_landing_route: '/user/customer-success', allowed_api_groups: ['profile','adoption_read','health_read','incidents_read','debug_write'], denied_api_groups: ['release_certify','security_admin','finance_admin'], default_guardrails: [{ kind: 'support_access_audited' }], status: 'active' };
UPSERT user_role_catalog:finance CONTENT { tenant_id: NONE, key: 'finance', name: 'Finance', job_function: 'finance', seniority_level: 'senior', description: 'Reviews cost, payment, commerce, usage and budget controls.', default_capabilities: ['view_usage_costs','approve_payment_policy','view_ap2_ucp','budget_review'], default_landing_route: '/user/finance', allowed_api_groups: ['profile','usage_cost','payments_read','commerce_read','budget_read','ap2_admin_read'], denied_api_groups: ['security_admin','release_certify'], default_guardrails: [{ kind: 'payment_admin_requires_approval' }], status: 'active' };
UPSERT user_role_catalog:security CONTENT { tenant_id: NONE, key: 'security', name: 'Security', job_function: 'security', seniority_level: 'senior', description: 'Owns identity, policy, authorization, compliance, guardrails and investigations.', default_capabilities: ['manage_policy','review_authorization','view_audit','manage_guardrails','incident_security'], default_landing_route: '/user/security', allowed_api_groups: ['profile','security_admin','policy_admin','identity_admin','compliance_admin','guardrails_admin','debug_read','traces_read'], denied_api_groups: [], default_guardrails: [{ kind: 'security_actions_require_audit' }], status: 'active' };
UPSERT user_role_catalog:it_admin CONTENT { tenant_id: NONE, key: 'it_admin', name: 'IT Admin', job_function: 'it', seniority_level: 'admin', description: 'Manages tenants, integrations, MCP servers, users, roles, health and platform settings.', default_capabilities: ['manage_users','manage_mcp','manage_connectors','view_health','assign_roles'], default_landing_route: '/user/it-admin', allowed_api_groups: ['profile','admin_overview','role_admin','mcp_admin','health','tenant_admin','connector_admin'], denied_api_groups: ['finance_admin'], default_guardrails: [{ kind: 'admin_changes_require_audit' }], status: 'active' };
UPSERT user_role_catalog:cto CONTENT { tenant_id: NONE, key: 'cto', name: 'CTO', job_function: 'executive', seniority_level: 'executive', description: 'Views maturity, reliability, governance, release posture and engineering velocity.', default_capabilities: ['view_maturity','view_reliability','view_governance','view_release_posture','approve_high_risk'], default_landing_route: '/user/executive/cto', allowed_api_groups: ['profile','executive_summary','maturity_read','governance_read','release_read','slo_read','adoption_read'], denied_api_groups: [], default_guardrails: [{ kind: 'executive_approval_audited' }], status: 'active' };
UPSERT user_role_catalog:ceo CONTENT { tenant_id: NONE, key: 'ceo', name: 'CEO', job_function: 'executive', seniority_level: 'executive', description: 'Views business adoption, risk, compliance, customer impact and strategic platform posture.', default_capabilities: ['view_business_summary','view_adoption','view_risk','view_compliance','view_cost_summary'], default_landing_route: '/user/executive/ceo', allowed_api_groups: ['profile','executive_summary','adoption_read','governance_read','compliance_read','usage_summary'], denied_api_groups: ['low_level_debug_write'], default_guardrails: [{ kind: 'executive_view_redacts_sensitive_details' }], status: 'active' };
UPSERT user_role_catalog:intern CONTENT { tenant_id: NONE, key: 'intern', name: 'Intern', job_function: 'general', seniority_level: 'intern', description: 'Learns through sandboxed tasks and read-only guided workflows.', default_capabilities: ['view_assigned_tasks','sandbox_blueprint_draft','view_docs'], default_landing_route: '/user/intern', allowed_api_groups: ['profile','tasks_read','golden_paths_read','sandbox_agent_builder_draft'], denied_api_groups: ['release_engineering','security_admin','payments_admin','admin_write'], default_guardrails: [{ kind: 'sandbox_only' }], status: 'active' };
UPSERT user_role_catalog:customer CONTENT { tenant_id: NONE, key: 'customer', name: 'Customer', job_function: 'customer', seniority_level: 'external', description: 'Uses customer-facing agents, views own usage, health and support status.', default_capabilities: ['use_agent','view_own_usage','open_support_case','view_own_traces'], default_landing_route: '/user/customer', allowed_api_groups: ['profile','customer_agent_use','own_usage_read','support_debug_limited'], denied_api_groups: ['admin','release_engineering','security_admin'], default_guardrails: [{ kind: 'own_data_only' }], status: 'active' };
UPSERT user_role_catalog:auditor CONTENT { tenant_id: NONE, key: 'auditor', name: 'Auditor', job_function: 'audit', seniority_level: 'external', description: 'Reviews compliance proof, audit logs, release evidence and governance posture.', default_capabilities: ['view_compliance_proofs','view_release_evidence','view_audit_logs','export_evidence'], default_landing_route: '/user/auditor', allowed_api_groups: ['profile','audit_read','compliance_read','release_read','governance_read','trace_read_redacted'], denied_api_groups: ['admin_write','debug_write','payments_write'], default_guardrails: [{ kind: 'read_only_redacted_export' }], status: 'active' };

DEFINE FUNCTION fn::assign_user_role($tenant_id, $subject_id, $role_key, $scope_kind, $scope_ref, $assigned_by, $expires_at) {
  LET $role = SELECT * FROM user_role_catalog WHERE (tenant_id = $tenant_id OR tenant_id = NONE) AND key = $role_key AND status = 'active' ORDER BY tenant_id DESC LIMIT 1;
  IF count($role) = 0 THEN { THROW 'user_role_not_found'; };
  RETURN CREATE user_role_assignments CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, role_key: $role_key, role_id: $role[0].id, seniority_level: $role[0].seniority_level, job_function: $role[0].job_function, scope_kind: $scope_kind, scope_ref: $scope_ref, status: 'active', assigned_by: $assigned_by, created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::get_user_experience_profile($tenant_id, $subject_id) {
  LET $assignments = SELECT * FROM user_role_assignments WHERE tenant_id = $tenant_id AND subject_id = $subject_id AND status = 'active' AND (expires_at = NONE OR expires_at > time::now());
  LET $roles = SELECT * FROM user_role_catalog WHERE id INSIDE $assignments[*].role_id;
  RETURN { subject_id: $subject_id, assignments: $assignments, roles: $roles, capabilities: array::distinct(array::flatten($roles[*].default_capabilities)), allowed_api_groups: array::distinct(array::flatten($roles[*].allowed_api_groups)), denied_api_groups: array::distinct(array::flatten($roles[*].denied_api_groups)), landing_routes: array::distinct($roles[*].default_landing_route), guardrails: array::flatten($roles[*].default_guardrails) };
};

DEFINE FUNCTION fn::evaluate_user_api_access($tenant_id, $subject_id, $api_group, $route, $action, $actor_id) {
  LET $profile = fn::get_user_experience_profile($tenant_id, $subject_id);
  LET $denied = $api_group INSIDE $profile.denied_api_groups OR 'admin' INSIDE $profile.denied_api_groups AND string::starts_with($api_group, 'admin');
  LET $allowed = !$denied AND ($api_group INSIDE $profile.allowed_api_groups OR 'admin' INSIDE $profile.allowed_api_groups OR string::starts_with($api_group, 'profile'));
  LET $role_key = IF count($profile.roles) > 0 THEN $profile.roles[0].key ELSE 'none' END;
  LET $decision_log = fn::log_decision_context($tenant_id, 'user_api_access_decision', $subject_id, $actor_id, NONE, NONE, { api_group: $api_group, route: $route, action: $action }, {}, {}, {}, {}, {}, {}, { profile: $profile }, [{ kind: 'role_allowed_api_group_required' }, { kind: 'denied_group_blocks_access' }], { allowed: $allowed, denied: $denied }, [{ decision: 'allow' }, { decision: 'deny' }], { decision: IF $allowed THEN 'allow' ELSE 'deny' END }, [], 'user_api_access_evaluated', {}, $profile.assignments[*].id, NONE, [], false);
  RETURN CREATE user_api_access_decisions CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, role_key: $role_key, api_group: $api_group, route: $route, action: $action, allowed: $allowed, reason: IF $allowed THEN 'role_allows_api_group' ELSE 'role_denies_or_does_not_allow_api_group' END, evidence_refs: $profile.assignments[*].id, decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::require_user_api_access($tenant_id, $subject_id, $api_group, $route, $action, $actor_id) {
  LET $decision = fn::evaluate_user_api_access($tenant_id, $subject_id, $api_group, $route, $action, $actor_id);
  IF !$decision.allowed THEN { THROW 'user_api_access_denied'; };
  RETURN true;
};
