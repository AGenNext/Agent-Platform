-- AGenNext Platform
-- 0070: HR workflows, skills intelligence, learning paths, LXP, ATS, and HRMS integrations
-- Purpose: support enterprise HR workflows for skills evaluation, gap identification, personalized learning paths, learning experience management integrations, ATS integrations, and HRMS integrations while preserving existing HR systems as source of record.

DEFINE TABLE hr_platform_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON hr_platform_connectors TYPE record<tenants>;
DEFINE FIELD connector_key ON hr_platform_connectors TYPE string;
DEFINE FIELD platform_kind ON hr_platform_connectors TYPE string;
DEFINE FIELD provider_name ON hr_platform_connectors TYPE string;
DEFINE FIELD capabilities ON hr_platform_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON hr_platform_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD source_of_record_policy ON hr_platform_connectors TYPE string DEFAULT 'external_hr_system_remains_source_of_record';
DEFINE FIELD connection_status ON hr_platform_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD governance_status ON hr_platform_connectors TYPE string DEFAULT 'review_required';
DEFINE FIELD created_at ON hr_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON hr_platform_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX hr_platform_connector_unique ON hr_platform_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE workforce_profiles SCHEMAFULL;
DEFINE FIELD tenant_id ON workforce_profiles TYPE record<tenants>;
DEFINE FIELD person_id ON workforce_profiles TYPE record<identity_persons>;
DEFINE FIELD employee_ref ON workforce_profiles TYPE option<string>;
DEFINE FIELD department ON workforce_profiles TYPE option<string>;
DEFINE FIELD job_family ON workforce_profiles TYPE option<string>;
DEFINE FIELD job_role ON workforce_profiles TYPE option<string>;
DEFINE FIELD seniority_level ON workforce_profiles TYPE option<string>;
DEFINE FIELD manager_person_id ON workforce_profiles TYPE option<record<identity_persons>>;
DEFINE FIELD employment_status ON workforce_profiles TYPE string DEFAULT 'active';
DEFINE FIELD source_refs ON workforce_profiles TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON workforce_profiles TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON workforce_profiles TYPE datetime DEFAULT time::now();
DEFINE INDEX workforce_profile_unique ON workforce_profiles FIELDS tenant_id, person_id UNIQUE;

DEFINE TABLE skill_taxonomy_items SCHEMAFULL;
DEFINE FIELD tenant_id ON skill_taxonomy_items TYPE option<record<tenants>>;
DEFINE FIELD skill_key ON skill_taxonomy_items TYPE string;
DEFINE FIELD skill_name ON skill_taxonomy_items TYPE string;
DEFINE FIELD skill_domain ON skill_taxonomy_items TYPE string;
DEFINE FIELD skill_category ON skill_taxonomy_items TYPE option<string>;
DEFINE FIELD proficiency_scale ON skill_taxonomy_items TYPE array<string> DEFAULT ['awareness','working','advanced','expert'];
DEFINE FIELD related_skill_keys ON skill_taxonomy_items TYPE array<string> DEFAULT [];
DEFINE FIELD source_refs ON skill_taxonomy_items TYPE array<string> DEFAULT [];
DEFINE FIELD status ON skill_taxonomy_items TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON skill_taxonomy_items TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON skill_taxonomy_items TYPE datetime DEFAULT time::now();
DEFINE INDEX skill_taxonomy_item_unique ON skill_taxonomy_items FIELDS tenant_id, skill_key UNIQUE;

DEFINE TABLE role_skill_requirements SCHEMAFULL;
DEFINE FIELD tenant_id ON role_skill_requirements TYPE record<tenants>;
DEFINE FIELD requirement_key ON role_skill_requirements TYPE string;
DEFINE FIELD job_family ON role_skill_requirements TYPE string;
DEFINE FIELD job_role ON role_skill_requirements TYPE string;
DEFINE FIELD seniority_level ON role_skill_requirements TYPE string;
DEFINE FIELD required_skills ON role_skill_requirements TYPE array<object> DEFAULT [];
DEFINE FIELD optional_skills ON role_skill_requirements TYPE array<object> DEFAULT [];
DEFINE FIELD source_refs ON role_skill_requirements TYPE array<string> DEFAULT [];
DEFINE FIELD status ON role_skill_requirements TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON role_skill_requirements TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON role_skill_requirements TYPE datetime DEFAULT time::now();
DEFINE INDEX role_skill_requirement_unique ON role_skill_requirements FIELDS tenant_id, requirement_key UNIQUE;

DEFINE TABLE skill_evaluations SCHEMAFULL;
DEFINE FIELD tenant_id ON skill_evaluations TYPE record<tenants>;
DEFINE FIELD evaluation_ref ON skill_evaluations TYPE string;
DEFINE FIELD workforce_profile_id ON skill_evaluations TYPE record<workforce_profiles>;
DEFINE FIELD evaluation_kind ON skill_evaluations TYPE string DEFAULT 'self_manager_ai_assisted';
DEFINE FIELD evaluator_person_id ON skill_evaluations TYPE option<record<identity_persons>>;
DEFINE FIELD evidence_refs ON skill_evaluations TYPE array<string> DEFAULT [];
DEFINE FIELD evaluated_skills ON skill_evaluations TYPE array<object> DEFAULT [];
DEFINE FIELD confidence_score ON skill_evaluations TYPE number DEFAULT 0;
DEFINE FIELD status ON skill_evaluations TYPE string DEFAULT 'completed';
DEFINE FIELD created_at ON skill_evaluations TYPE datetime DEFAULT time::now();
DEFINE INDEX skill_evaluation_ref_unique ON skill_evaluations FIELDS evaluation_ref UNIQUE;

DEFINE TABLE skill_gap_assessments SCHEMAFULL;
DEFINE FIELD tenant_id ON skill_gap_assessments TYPE record<tenants>;
DEFINE FIELD gap_ref ON skill_gap_assessments TYPE string;
DEFINE FIELD workforce_profile_id ON skill_gap_assessments TYPE record<workforce_profiles>;
DEFINE FIELD role_requirement_id ON skill_gap_assessments TYPE option<record<role_skill_requirements>>;
DEFINE FIELD current_skill_snapshot ON skill_gap_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD target_skill_snapshot ON skill_gap_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD gaps ON skill_gap_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD priority_gaps ON skill_gap_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD status ON skill_gap_assessments TYPE string DEFAULT 'open';
DEFINE FIELD created_at ON skill_gap_assessments TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON skill_gap_assessments TYPE datetime DEFAULT time::now();
DEFINE INDEX skill_gap_assessment_ref_unique ON skill_gap_assessments FIELDS gap_ref UNIQUE;

DEFINE TABLE learning_content_catalog SCHEMAFULL;
DEFINE FIELD tenant_id ON learning_content_catalog TYPE option<record<tenants>>;
DEFINE FIELD content_key ON learning_content_catalog TYPE string;
DEFINE FIELD provider_name ON learning_content_catalog TYPE string;
DEFINE FIELD content_title ON learning_content_catalog TYPE string;
DEFINE FIELD content_kind ON learning_content_catalog TYPE string;
DEFINE FIELD skill_keys ON learning_content_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD proficiency_target ON learning_content_catalog TYPE option<string>;
DEFINE FIELD duration_minutes ON learning_content_catalog TYPE option<int>;
DEFINE FIELD delivery_mode ON learning_content_catalog TYPE string DEFAULT 'online';
DEFINE FIELD external_content_ref ON learning_content_catalog TYPE option<string>;
DEFINE FIELD status ON learning_content_catalog TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON learning_content_catalog TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON learning_content_catalog TYPE datetime DEFAULT time::now();
DEFINE INDEX learning_content_catalog_unique ON learning_content_catalog FIELDS tenant_id, content_key UNIQUE;

DEFINE TABLE personalized_learning_paths SCHEMAFULL;
DEFINE FIELD tenant_id ON personalized_learning_paths TYPE record<tenants>;
DEFINE FIELD path_ref ON personalized_learning_paths TYPE string;
DEFINE FIELD workforce_profile_id ON personalized_learning_paths TYPE record<workforce_profiles>;
DEFINE FIELD gap_assessment_id ON personalized_learning_paths TYPE option<record<skill_gap_assessments>>;
DEFINE FIELD path_name ON personalized_learning_paths TYPE string;
DEFINE FIELD learning_goals ON personalized_learning_paths TYPE array<object> DEFAULT [];
DEFINE FIELD recommended_content ON personalized_learning_paths TYPE array<object> DEFAULT [];
DEFINE FIELD manager_review_required ON personalized_learning_paths TYPE bool DEFAULT true;
DEFINE FIELD approval_status ON personalized_learning_paths TYPE string DEFAULT 'pending_manager_review';
DEFINE FIELD progress_status ON personalized_learning_paths TYPE string DEFAULT 'not_started';
DEFINE FIELD created_at ON personalized_learning_paths TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON personalized_learning_paths TYPE datetime DEFAULT time::now();
DEFINE INDEX personalized_learning_path_ref_unique ON personalized_learning_paths FIELDS path_ref UNIQUE;

DEFINE TABLE learning_progress_events SCHEMAFULL;
DEFINE FIELD tenant_id ON learning_progress_events TYPE record<tenants>;
DEFINE FIELD path_id ON learning_progress_events TYPE option<record<personalized_learning_paths>>;
DEFINE FIELD workforce_profile_id ON learning_progress_events TYPE record<workforce_profiles>;
DEFINE FIELD content_key ON learning_progress_events TYPE option<string>;
DEFINE FIELD event_kind ON learning_progress_events TYPE string;
DEFINE FIELD progress_percent ON learning_progress_events TYPE number DEFAULT 0;
DEFINE FIELD evidence_refs ON learning_progress_events TYPE array<string> DEFAULT [];
DEFINE FIELD observed_at ON learning_progress_events TYPE datetime DEFAULT time::now();

DEFINE TABLE recruiting_candidate_profiles SCHEMAFULL;
DEFINE FIELD tenant_id ON recruiting_candidate_profiles TYPE record<tenants>;
DEFINE FIELD candidate_ref ON recruiting_candidate_profiles TYPE string;
DEFINE FIELD ats_connector_id ON recruiting_candidate_profiles TYPE option<record<hr_platform_connectors>>;
DEFINE FIELD external_candidate_ref ON recruiting_candidate_profiles TYPE option<string>;
DEFINE FIELD candidate_name ON recruiting_candidate_profiles TYPE option<string>;
DEFINE FIELD candidate_email_hash ON recruiting_candidate_profiles TYPE option<string>;
DEFINE FIELD target_job_role ON recruiting_candidate_profiles TYPE option<string>;
DEFINE FIELD skills_snapshot ON recruiting_candidate_profiles TYPE array<object> DEFAULT [];
DEFINE FIELD evaluation_status ON recruiting_candidate_profiles TYPE string DEFAULT 'not_evaluated';
DEFINE FIELD source_refs ON recruiting_candidate_profiles TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON recruiting_candidate_profiles TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON recruiting_candidate_profiles TYPE datetime DEFAULT time::now();
DEFINE INDEX recruiting_candidate_profile_ref_unique ON recruiting_candidate_profiles FIELDS tenant_id, candidate_ref UNIQUE;

DEFINE TABLE hr_workflow_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON hr_workflow_runs TYPE record<tenants>;
DEFINE FIELD workflow_ref ON hr_workflow_runs TYPE string;
DEFINE FIELD workflow_kind ON hr_workflow_runs TYPE string;
DEFINE FIELD subject_person_id ON hr_workflow_runs TYPE option<record<identity_persons>>;
DEFINE FIELD candidate_profile_id ON hr_workflow_runs TYPE option<record<recruiting_candidate_profiles>>;
DEFINE FIELD owner_role ON hr_workflow_runs TYPE string DEFAULT 'hr_owner';
DEFINE FIELD status ON hr_workflow_runs TYPE string DEFAULT 'active';
DEFINE FIELD current_step ON hr_workflow_runs TYPE option<string>;
DEFINE FIELD human_review_required ON hr_workflow_runs TYPE bool DEFAULT true;
DEFINE FIELD evidence_refs ON hr_workflow_runs TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON hr_workflow_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON hr_workflow_runs TYPE datetime DEFAULT time::now();
DEFINE INDEX hr_workflow_run_ref_unique ON hr_workflow_runs FIELDS workflow_ref UNIQUE;

DEFINE FUNCTION fn::register_hr_platform_connector($tenant_id: record<tenants>, $connector_key: string, $platform_kind: string, $provider_name: string, $capabilities: array<string>, $supported_auth_modes: array<string>) {
  RETURN UPSERT type::thing('hr_platform_connectors', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $connector_key)) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    platform_kind: $platform_kind,
    provider_name: $provider_name,
    capabilities: $capabilities,
    supported_auth_modes: $supported_auth_modes,
    source_of_record_policy: 'external_hr_system_remains_source_of_record',
    connection_status: 'connected',
    governance_status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::record_skill_evaluation($tenant_id: record<tenants>, $workforce_profile_id: record<workforce_profiles>, $evaluation_kind: string, $evaluator_person_id: option<record<identity_persons>>, $evidence_refs: array<string>, $evaluated_skills: array<object>, $confidence_score: number) {
  RETURN CREATE skill_evaluations CONTENT {
    tenant_id: $tenant_id,
    evaluation_ref: rand::uuid(),
    workforce_profile_id: $workforce_profile_id,
    evaluation_kind: $evaluation_kind,
    evaluator_person_id: $evaluator_person_id,
    evidence_refs: $evidence_refs,
    evaluated_skills: $evaluated_skills,
    confidence_score: $confidence_score,
    status: 'completed',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::create_skill_gap_assessment($tenant_id: record<tenants>, $workforce_profile_id: record<workforce_profiles>, $role_requirement_id: option<record<role_skill_requirements>>, $current_skill_snapshot: array<object>, $target_skill_snapshot: array<object>, $gaps: array<object>, $priority_gaps: array<object>) {
  RETURN CREATE skill_gap_assessments CONTENT {
    tenant_id: $tenant_id,
    gap_ref: rand::uuid(),
    workforce_profile_id: $workforce_profile_id,
    role_requirement_id: $role_requirement_id,
    current_skill_snapshot: $current_skill_snapshot,
    target_skill_snapshot: $target_skill_snapshot,
    gaps: $gaps,
    priority_gaps: $priority_gaps,
    status: 'open',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::create_personalized_learning_path($tenant_id: record<tenants>, $workforce_profile_id: record<workforce_profiles>, $gap_assessment_id: option<record<skill_gap_assessments>>, $path_name: string, $learning_goals: array<object>, $recommended_content: array<object>) {
  RETURN CREATE personalized_learning_paths CONTENT {
    tenant_id: $tenant_id,
    path_ref: rand::uuid(),
    workforce_profile_id: $workforce_profile_id,
    gap_assessment_id: $gap_assessment_id,
    path_name: $path_name,
    learning_goals: $learning_goals,
    recommended_content: $recommended_content,
    manager_review_required: true,
    approval_status: 'pending_manager_review',
    progress_status: 'not_started',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::hr_workforce_context($tenant_id: record<tenants>) {
  RETURN {
    connectors: SELECT * FROM hr_platform_connectors WHERE tenant_id = $tenant_id ORDER BY provider_name,
    workforce_profiles: SELECT * FROM workforce_profiles WHERE tenant_id = $tenant_id ORDER BY updated_at DESC LIMIT 100,
    skills: SELECT * FROM skill_taxonomy_items WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY skill_domain, skill_name,
    role_requirements: SELECT * FROM role_skill_requirements WHERE tenant_id = $tenant_id ORDER BY job_family, job_role, seniority_level,
    skill_evaluations: SELECT * FROM skill_evaluations WHERE tenant_id = $tenant_id ORDER BY created_at DESC LIMIT 100,
    gap_assessments: SELECT * FROM skill_gap_assessments WHERE tenant_id = $tenant_id ORDER BY updated_at DESC LIMIT 100,
    learning_paths: SELECT * FROM personalized_learning_paths WHERE tenant_id = $tenant_id ORDER BY updated_at DESC LIMIT 100,
    learning_content: SELECT * FROM learning_content_catalog WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY provider_name, content_title,
    candidate_profiles: SELECT * FROM recruiting_candidate_profiles WHERE tenant_id = $tenant_id ORDER BY updated_at DESC LIMIT 100,
    hr_workflows: SELECT * FROM hr_workflow_runs WHERE tenant_id = $tenant_id ORDER BY updated_at DESC LIMIT 100
  };
};

-- Built-in HRMS, ATS, and LXP connector templates.
CREATE hr_platform_connectors:workday_template CONTENT { connector_key: 'workday', platform_kind: 'hrms', provider_name: 'Workday', capabilities: ['employee_profile_sync','job_profile_sync','org_hierarchy_sync','skills_sync','learning_records'], supported_auth_modes: ['oauth','integration_system_user'], source_of_record_policy: 'external_hr_system_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE hr_platform_connectors:successfactors_template CONTENT { connector_key: 'sap_successfactors', platform_kind: 'hrms', provider_name: 'SAP SuccessFactors', capabilities: ['employee_profile_sync','job_profile_sync','skills_sync','performance_context','learning_records'], supported_auth_modes: ['oauth','saml_bearer','api_user'], source_of_record_policy: 'external_hr_system_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE hr_platform_connectors:greenhouse_template CONTENT { connector_key: 'greenhouse', platform_kind: 'ats', provider_name: 'Greenhouse', capabilities: ['candidate_sync','job_sync','interview_context','offer_context','candidate_skill_evaluation'], supported_auth_modes: ['api_key','oauth'], source_of_record_policy: 'external_hr_system_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE hr_platform_connectors:lever_template CONTENT { connector_key: 'lever', platform_kind: 'ats', provider_name: 'Lever', capabilities: ['candidate_sync','job_sync','pipeline_context','interview_context','candidate_skill_evaluation'], supported_auth_modes: ['api_key','oauth'], source_of_record_policy: 'external_hr_system_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE hr_platform_connectors:cornerstone_template CONTENT { connector_key: 'cornerstone', platform_kind: 'lms_lxp', provider_name: 'Cornerstone', capabilities: ['learning_catalog_sync','learning_assignment','completion_sync','skills_context'], supported_auth_modes: ['oauth','api_user'], source_of_record_policy: 'external_hr_system_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE hr_platform_connectors:deg...Degreed_template CONTENT { connector_key: 'degreed', platform_kind: 'lxp', provider_name: 'Degreed', capabilities: ['learning_catalog_sync','skill_plan_sync','learning_path_assignment','completion_sync'], supported_auth_modes: ['oauth','api_token'], source_of_record_policy: 'external_hr_system_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
CREATE hr_platform_connectors:linkedin_learning_template CONTENT { connector_key: 'linkedin_learning', platform_kind: 'learning_content', provider_name: 'LinkedIn Learning', capabilities: ['content_catalog_sync','course_recommendations','completion_sync'], supported_auth_modes: ['oauth','api_key'], source_of_record_policy: 'external_hr_system_remains_source_of_record', connection_status: 'template', governance_status: 'review_required', created_at: time::now(), updated_at: time::now() };
