-- AGenNext Platform
-- 0075: Agent builder, canvas, collaborative multimodal editor, git-backed publishing, and technical SEO
-- Purpose: add production product contracts for React Flow/XYFlow agent builder, enterprise canvas, collaborative multimodal creative editor, git-backed publishing, and built-in technical SEO.

DEFINE TABLE agent_builder_projects SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_builder_projects TYPE record<tenants>;
DEFINE FIELD project_ref ON agent_builder_projects TYPE string;
DEFINE FIELD project_name ON agent_builder_projects TYPE string;
DEFINE FIELD builder_mode ON agent_builder_projects TYPE string DEFAULT 'ui_first';
DEFINE FIELD code_repository_ref ON agent_builder_projects TYPE option<string>;
DEFINE FIELD visual_graph_ref ON agent_builder_projects TYPE option<string>;
DEFINE FIELD verified_skill_refs ON agent_builder_projects TYPE array<string> DEFAULT [];
DEFINE FIELD approved_tool_refs ON agent_builder_projects TYPE array<string> DEFAULT [];
DEFINE FIELD governance_status ON agent_builder_projects TYPE string DEFAULT 'draft';
DEFINE FIELD created_by_person_id ON agent_builder_projects TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON agent_builder_projects TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON agent_builder_projects TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_builder_project_ref_unique ON agent_builder_projects FIELDS project_ref UNIQUE;

DEFINE TABLE xyflow_agent_graphs SCHEMAFULL;
DEFINE FIELD tenant_id ON xyflow_agent_graphs TYPE record<tenants>;
DEFINE FIELD project_id ON xyflow_agent_graphs TYPE record<agent_builder_projects>;
DEFINE FIELD graph_ref ON xyflow_agent_graphs TYPE string;
DEFINE FIELD nodes ON xyflow_agent_graphs TYPE array<object> DEFAULT [];
DEFINE FIELD edges ON xyflow_agent_graphs TYPE array<object> DEFAULT [];
DEFINE FIELD viewport ON xyflow_agent_graphs TYPE object DEFAULT {};
DEFINE FIELD validation_status ON xyflow_agent_graphs TYPE string DEFAULT 'not_validated';
DEFINE FIELD version_label ON xyflow_agent_graphs TYPE string DEFAULT '1.0.0';
DEFINE FIELD created_at ON xyflow_agent_graphs TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON xyflow_agent_graphs TYPE datetime DEFAULT time::now();
DEFINE INDEX xyflow_agent_graph_ref_unique ON xyflow_agent_graphs FIELDS graph_ref UNIQUE;

DEFINE TABLE collaborative_canvas_documents SCHEMAFULL;
DEFINE FIELD tenant_id ON collaborative_canvas_documents TYPE record<tenants>;
DEFINE FIELD document_ref ON collaborative_canvas_documents TYPE string;
DEFINE FIELD document_title ON collaborative_canvas_documents TYPE string;
DEFINE FIELD work_type ON collaborative_canvas_documents TYPE string;
DEFINE FIELD editor_kind ON collaborative_canvas_documents TYPE string DEFAULT 'multimodal_collaborative';
DEFINE FIELD content_state ON collaborative_canvas_documents TYPE object DEFAULT {};
DEFINE FIELD media_refs ON collaborative_canvas_documents TYPE array<object> DEFAULT [];
DEFINE FIELD collaborators ON collaborative_canvas_documents TYPE array<object> DEFAULT [];
DEFINE FIELD current_version_ref ON collaborative_canvas_documents TYPE option<string>;
DEFINE FIELD publishing_status ON collaborative_canvas_documents TYPE string DEFAULT 'draft';
DEFINE FIELD created_by_person_id ON collaborative_canvas_documents TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON collaborative_canvas_documents TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON collaborative_canvas_documents TYPE datetime DEFAULT time::now();
DEFINE INDEX collaborative_canvas_document_ref_unique ON collaborative_canvas_documents FIELDS document_ref UNIQUE;

DEFINE TABLE creative_work_versions SCHEMAFULL;
DEFINE FIELD tenant_id ON creative_work_versions TYPE record<tenants>;
DEFINE FIELD document_id ON creative_work_versions TYPE record<collaborative_canvas_documents>;
DEFINE FIELD version_ref ON creative_work_versions TYPE string;
DEFINE FIELD version_label ON creative_work_versions TYPE string;
DEFINE FIELD content_snapshot ON creative_work_versions TYPE object DEFAULT {};
DEFINE FIELD media_snapshot_refs ON creative_work_versions TYPE array<object> DEFAULT [];
DEFINE FIELD change_summary ON creative_work_versions TYPE option<string>;
DEFINE FIELD created_by_person_id ON creative_work_versions TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON creative_work_versions TYPE datetime DEFAULT time::now();
DEFINE INDEX creative_work_version_ref_unique ON creative_work_versions FIELDS version_ref UNIQUE;

DEFINE TABLE git_publishing_targets SCHEMAFULL;
DEFINE FIELD tenant_id ON git_publishing_targets TYPE record<tenants>;
DEFINE FIELD target_ref ON git_publishing_targets TYPE string;
DEFINE FIELD provider_name ON git_publishing_targets TYPE string DEFAULT 'github';
DEFINE FIELD repository_full_name ON git_publishing_targets TYPE string;
DEFINE FIELD default_branch ON git_publishing_targets TYPE string DEFAULT 'main';
DEFINE FIELD publish_path_prefix ON git_publishing_targets TYPE string DEFAULT 'content';
DEFINE FIELD review_policy ON git_publishing_targets TYPE object DEFAULT {};
DEFINE FIELD status ON git_publishing_targets TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON git_publishing_targets TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON git_publishing_targets TYPE datetime DEFAULT time::now();
DEFINE INDEX git_publishing_target_ref_unique ON git_publishing_targets FIELDS target_ref UNIQUE;

DEFINE TABLE publishing_runs SCHEMAFULL;
DEFINE FIELD tenant_id ON publishing_runs TYPE record<tenants>;
DEFINE FIELD run_ref ON publishing_runs TYPE string;
DEFINE FIELD document_id ON publishing_runs TYPE record<collaborative_canvas_documents>;
DEFINE FIELD version_id ON publishing_runs TYPE record<creative_work_versions>;
DEFINE FIELD target_id ON publishing_runs TYPE record<git_publishing_targets>;
DEFINE FIELD branch_name ON publishing_runs TYPE string;
DEFINE FIELD commit_sha ON publishing_runs TYPE option<string>;
DEFINE FIELD pull_request_ref ON publishing_runs TYPE option<string>;
DEFINE FIELD seo_check_id ON publishing_runs TYPE option<record<technical_seo_audits>>;
DEFINE FIELD approval_status ON publishing_runs TYPE string DEFAULT 'pending_review';
DEFINE FIELD publish_status ON publishing_runs TYPE string DEFAULT 'not_published';
DEFINE FIELD created_at ON publishing_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD published_at ON publishing_runs TYPE option<datetime>;
DEFINE INDEX publishing_run_ref_unique ON publishing_runs FIELDS run_ref UNIQUE;

DEFINE TABLE technical_seo_audits SCHEMAFULL;
DEFINE FIELD tenant_id ON technical_seo_audits TYPE record<tenants>;
DEFINE FIELD audit_ref ON technical_seo_audits TYPE string;
DEFINE FIELD document_id ON technical_seo_audits TYPE option<record<collaborative_canvas_documents>>;
DEFINE FIELD url_or_path ON technical_seo_audits TYPE string;
DEFINE FIELD checks ON technical_seo_audits TYPE array<object> DEFAULT [];
DEFINE FIELD issues ON technical_seo_audits TYPE array<object> DEFAULT [];
DEFINE FIELD schema_org_entities ON technical_seo_audits TYPE array<object> DEFAULT [];
DEFINE FIELD score ON technical_seo_audits TYPE number DEFAULT 0;
DEFINE FIELD status ON technical_seo_audits TYPE string DEFAULT 'completed';
DEFINE FIELD created_at ON technical_seo_audits TYPE datetime DEFAULT time::now();
DEFINE INDEX technical_seo_audit_ref_unique ON technical_seo_audits FIELDS audit_ref UNIQUE;

DEFINE FUNCTION fn::builder_canvas_context($tenant_id: record<tenants>) {
  RETURN {
    agent_builder_projects: SELECT * FROM agent_builder_projects WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    xyflow_graphs: SELECT * FROM xyflow_agent_graphs WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    canvas_documents: SELECT * FROM collaborative_canvas_documents WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    creative_versions: SELECT * FROM creative_work_versions WHERE tenant_id = $tenant_id ORDER BY created_at DESC LIMIT 100,
    git_targets: SELECT * FROM git_publishing_targets WHERE tenant_id = $tenant_id ORDER BY updated_at DESC,
    publishing_runs: SELECT * FROM publishing_runs WHERE tenant_id = $tenant_id ORDER BY created_at DESC,
    seo_audits: SELECT * FROM technical_seo_audits WHERE tenant_id = $tenant_id ORDER BY created_at DESC
  };
};
