-- ============================================================
-- AGenNext Agent DB Runtime
-- Value Loop Integration Schema
-- Status: validated runtime artifact
-- Purpose: Phase 1 value loop runtime slice - closes the loop:
-- Task -> Output -> Outcome -> ValueRealization -> Learning -> Improvement
-- ============================================================

-- Phase 1 value loop entities
-- These tables are designed to integrate with the core runtime schema
-- without conflicting with existing core tables.

-- Evidence table - records proof of work and validation
DEFINE TABLE evidence SCHEMAFULL;
DEFINE FIELD entity ON evidence TYPE option<record<entity>>;
DEFINE FIELD evidence_type ON evidence TYPE string
  ASSERT $value IN [
    "validation_report",
    "test_result",
    "audit_log",
    "metrics_snapshot",
    "performance_benchmark",
    "compliance_report",
    "security_scan",
    "deployment_record",
    "smoke_test_result",
    "regression_test_result",
    "integration_test_result",
    "manual_review",
    "automated_check",
    "external_verification"
  ];
DEFINE FIELD source ON evidence TYPE option<string>;
DEFINE FIELD source_ref ON evidence TYPE option<string>;
DEFINE FIELD artifact ON evidence TYPE option<record<artifact>>;
DEFINE FIELD created_at ON evidence TYPE datetime DEFAULT time::now();
DEFINE FIELD created_by ON evidence TYPE option<record<identity>>;
DEFINE FIELD status ON evidence TYPE string DEFAULT 'active'
  ASSERT $value IN ['active', 'archived', 'superseded'];
DEFINE FIELD metadata ON evidence FLEXIBLE TYPE option<object>;
DEFINE INDEX evidence_type_idx ON evidence FIELDS evidence_type;
DEFINE INDEX evidence_entity_idx ON evidence FIELDS entity;
DEFINE INDEX evidence_created_idx ON evidence FIELDS created_at;

-- Output table - represents work products from tasks
DEFINE TABLE output SCHEMAFULL;
DEFINE FIELD entity ON output TYPE option<record<entity>>;
DEFINE FIELD task ON output TYPE option<record<task>>;
DEFINE FIELD project ON output TYPE option<record<project>>;
DEFINE FIELD milestone ON output TYPE option<record<milestone>>;
DEFINE FIELD title ON output TYPE string;
DEFINE FIELD description ON output TYPE option<string>;
DEFINE FIELD output_type ON output TYPE string
  ASSERT $value IN [
    'document',
    'code',
    'report',
    'decision_record',
    'validation_result',
    'artifact',
    'configuration',
    'dataset',
    'workflow',
    'model',
    'api_spec',
    'schema',
    'policy',
    'contract'
  ];
DEFINE FIELD status ON output TYPE string DEFAULT 'draft'
  ASSERT $value IN ['draft', 'generated', 'reviewing', 'approved', 'published', 'superseded', 'archived', 'active'];
DEFINE FIELD artifact ON output TYPE option<record<artifact>>;
DEFINE FIELD evidence ON output TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD created_at ON output TYPE datetime DEFAULT time::now();
DEFINE FIELD created_by ON output TYPE option<record<identity>>;
DEFINE FIELD version ON output TYPE string DEFAULT '0.1.0';
DEFINE INDEX output_task_idx ON output FIELDS task;
DEFINE INDEX output_project_idx ON output FIELDS project;
DEFINE INDEX output_type_idx ON output FIELDS output_type;

-- Outcome table - represents the result of task execution
DEFINE TABLE outcome SCHEMAFULL;
DEFINE FIELD entity ON outcome TYPE option<record<entity>>;
DEFINE FIELD output ON outcome TYPE option<record<output>>;
DEFINE FIELD task ON outcome TYPE option<record<task>>;
DEFINE FIELD project ON outcome TYPE option<record<project>>;
DEFINE FIELD objective_id ON outcome TYPE option<string>;
DEFINE FIELD title ON outcome TYPE string;
DEFINE FIELD description ON outcome TYPE option<string>;
DEFINE FIELD outcome_type ON outcome TYPE string
  ASSERT $value IN [
    'achieved',
    'partially_achieved',
    'not_achieved',
    'exceeded',
    'blocked',
    'unintended',
    'cancelled'
  ];
DEFINE FIELD evidence ON outcome TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD evaluation ON outcome TYPE option<record<evaluation>>;
DEFINE FIELD observed_at ON outcome TYPE datetime DEFAULT time::now();
DEFINE FIELD observed_by ON outcome TYPE option<record<identity>>;
DEFINE INDEX outcome_output_idx ON outcome FIELDS output;
DEFINE INDEX outcome_project_idx ON outcome FIELDS project;
DEFINE INDEX outcome_type_idx ON outcome FIELDS outcome_type;

-- ValueRealization table - tracks value delivered by outcomes
DEFINE TABLE value_realization SCHEMAFULL;
DEFINE FIELD entity ON value_realization TYPE option<record<entity>>;
DEFINE FIELD outcome ON value_realization TYPE record<outcome>;
DEFINE FIELD project ON value_realization TYPE option<record<project>>;
DEFINE FIELD beneficiary_id ON value_realization TYPE option<string>;
DEFINE FIELD value_type ON value_realization TYPE string
  ASSERT $value IN [
    'financial',
    'operational',
    'user',
    'compliance',
    'trust',
    'knowledge',
    'risk_reduction',
    'time_saved',
    'quality_improvement',
    'reliability_improvement',
    'efficiency_gain',
    'cost_savings'
  ];
DEFINE FIELD state ON value_realization TYPE string DEFAULT 'not_started'
  ASSERT $value IN [
    'not_started',
    'measuring',
    'realized',
    'partially_realized',
    'not_realized',
    'disputed',
    'verified'
  ];
DEFINE FIELD metric_name ON value_realization TYPE option<string>;
DEFINE FIELD baseline_value ON value_realization TYPE option<number>;
DEFINE FIELD target_value ON value_realization TYPE option<number>;
DEFINE FIELD realized_value ON value_realization TYPE option<number>;
DEFINE FIELD unit ON value_realization TYPE option<string>;
DEFINE FIELD cost ON value_realization TYPE option<number>;
DEFINE FIELD value_efficiency ON value_realization TYPE option<number>;
DEFINE FIELD evidence ON value_realization TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD evaluation ON value_realization TYPE option<record<evaluation>>;
DEFINE FIELD trust_assessment ON value_realization TYPE option<record<trust_assessment>>;
DEFINE FIELD measured_at ON value_realization TYPE option<datetime>;
DEFINE FIELD measured_by ON value_realization TYPE option<record<identity>>;
DEFINE INDEX value_realization_outcome_idx ON value_realization FIELDS outcome;
DEFINE INDEX value_realization_project_idx ON value_realization FIELDS project;
DEFINE INDEX value_realization_type_idx ON value_realization FIELDS value_type;
DEFINE INDEX value_realization_state_idx ON value_realization FIELDS state;

-- Learning table - captures insights from value realization
DEFINE TABLE learning SCHEMAFULL;
DEFINE FIELD entity ON learning TYPE option<record<entity>>;
DEFINE FIELD value_realization ON learning TYPE option<record<value_realization>>;
DEFINE FIELD outcome ON learning TYPE option<record<outcome>>;
DEFINE FIELD task ON learning TYPE option<record<task>>;
DEFINE FIELD project ON learning TYPE option<record<project>>;
DEFINE FIELD decision ON learning TYPE option<record<decision>>;
DEFINE FIELD learning_type ON learning TYPE string
  ASSERT $value IN [
    'decision_learning',
    'skill_learning',
    'tool_learning',
    'operator_learning',
    'policy_learning',
    'recommendation_learning',
    'selection_learning',
    'trust_learning',
    'knowledge_learning',
    'workflow_learning',
    'cost_learning',
    'risk_learning',
    'quality_learning',
    'performance_learning'
  ];
DEFINE FIELD title ON learning TYPE string;
DEFINE FIELD insight ON learning TYPE string;
DEFINE FIELD evidence ON learning TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD confidence ON learning TYPE option<number>
  ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD knowledge_candidate ON learning TYPE option<record<knowledge_candidate>>;
DEFINE FIELD recorded_at ON learning TYPE datetime DEFAULT time::now();
DEFINE FIELD recorded_by ON learning TYPE option<record<identity>>;
DEFINE INDEX learning_project_idx ON learning FIELDS project;
DEFINE INDEX learning_type_idx ON learning FIELDS learning_type;
DEFINE INDEX learning_value_realization_idx ON learning FIELDS value_realization;

-- Improvement table - tracks actionable improvements from learning
DEFINE TABLE improvement SCHEMAFULL;
DEFINE FIELD entity ON improvement TYPE option<record<entity>>;
DEFINE FIELD learning ON improvement TYPE option<record<learning>>;
DEFINE FIELD project ON improvement TYPE option<record<project>>;
DEFINE FIELD task ON improvement TYPE option<record<task>>;
DEFINE FIELD improvement_type ON improvement TYPE string
  ASSERT $value IN [
    'strategy_update',
    'objective_update',
    'policy_update',
    'work_definition_update',
    'skill_update',
    'tool_update',
    'operator_update',
    'workflow_update',
    'knowledge_update',
    'runtime_fix',
    'risk_mitigation',
    'quality_improvement',
    'performance_optimization'
  ];
DEFINE FIELD state ON improvement TYPE string DEFAULT 'proposed'
  ASSERT $value IN [
    'proposed',
    'accepted',
    'rejected',
    'planned',
    'in_progress',
    'applied',
    'validated',
    'archived'
  ];
DEFINE FIELD title ON improvement TYPE string;
DEFINE FIELD description ON improvement TYPE option<string>;
DEFINE FIELD target_object_type ON improvement TYPE option<string>;
DEFINE FIELD target_object_id ON improvement TYPE option<string>;
DEFINE FIELD owner ON improvement TYPE option<record<identity>>;
DEFINE FIELD evidence ON improvement TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD decision ON improvement TYPE option<record<decision>>;
DEFINE FIELD created_at ON improvement TYPE datetime DEFAULT time::now();
DEFINE FIELD applied_at ON improvement TYPE option<datetime>;
DEFINE FIELD validated_at ON improvement TYPE option<datetime>;
DEFINE INDEX improvement_project_idx ON improvement FIELDS project;
DEFINE INDEX improvement_type_idx ON improvement FIELDS improvement_type;
DEFINE INDEX improvement_state_idx ON improvement FIELDS state;
DEFINE INDEX improvement_learning_idx ON improvement FIELDS learning;

-- KnowledgeCandidate table - for knowledge that needs verification
DEFINE TABLE knowledge_candidate SCHEMAFULL;
DEFINE FIELD entity ON knowledge_candidate TYPE option<record<entity>>;
DEFINE FIELD artifact ON knowledge_candidate TYPE record<artifact>;
DEFINE FIELD title ON knowledge_candidate TYPE string;
DEFINE FIELD content ON knowledge_candidate TYPE option<string>;
DEFINE FIELD source_ref ON knowledge_candidate TYPE option<string>;
DEFINE FIELD evidence ON knowledge_candidate TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD verification_state ON knowledge_candidate TYPE string DEFAULT 'unverified'
  ASSERT $value IN ['unverified', 'pending_review', 'approved', 'rejected', 'superseded'];
DEFINE FIELD submitted_by ON knowledge_candidate TYPE option<record<identity>>;
DEFINE FIELD submitted_at ON knowledge_candidate TYPE datetime DEFAULT time::now();
DEFINE FIELD reviewed_by ON knowledge_candidate TYPE option<record<identity>>;
DEFINE FIELD reviewed_at ON knowledge_candidate TYPE option<datetime>;
DEFINE INDEX knowledge_candidate_artifact_idx ON knowledge_candidate FIELDS artifact;
DEFINE INDEX knowledge_candidate_state_idx ON knowledge_candidate FIELDS verification_state;

-- Project table - organizes work into scoped initiatives
DEFINE TABLE project SCHEMAFULL;
DEFINE FIELD entity ON project TYPE option<record<entity>>;
DEFINE FIELD name ON project TYPE string;
DEFINE FIELD scope ON project TYPE string;
DEFINE FIELD owner ON project TYPE option<record<identity>>;
DEFINE FIELD status ON project TYPE string DEFAULT 'active'
  ASSERT $value IN ['draft', 'active', 'on_hold', 'completed', 'cancelled', 'archived'];
DEFINE FIELD start_date ON project TYPE option<datetime>;
DEFINE FIELD end_date ON project TYPE option<datetime>;
DEFINE FIELD created_at ON project TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON project TYPE datetime VALUE time::now();
DEFINE INDEX project_owner_idx ON project FIELDS owner;
DEFINE INDEX project_status_idx ON project FIELDS status;

-- Milestone table - tracks project progress checkpoints
DEFINE TABLE milestone SCHEMAFULL;
DEFINE FIELD entity ON milestone TYPE option<record<entity>>;
DEFINE FIELD project ON milestone TYPE record<project>;
DEFINE FIELD name ON milestone TYPE string;
DEFINE FIELD description ON milestone TYPE option<string>;
DEFINE FIELD deadline ON milestone TYPE option<datetime>;
DEFINE FIELD status ON milestone TYPE string DEFAULT 'active'
  ASSERT $value IN ['draft', 'active', 'achieved', 'missed', 'cancelled'];
DEFINE FIELD completion_criteria ON milestone TYPE array<string> DEFAULT [];
DEFINE FIELD created_at ON milestone TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON milestone TYPE datetime VALUE time::now();
DEFINE INDEX milestone_project_idx ON milestone FIELDS project;
DEFINE INDEX milestone_status_idx ON milestone FIELDS status;

-- Organization table - top-level organizational entity
DEFINE TABLE organization SCHEMAFULL;
DEFINE FIELD entity ON organization TYPE option<record<entity>>;
DEFINE FIELD name ON organization TYPE string;
DEFINE FIELD industry ON organization TYPE option<string>;
DEFINE FIELD status ON organization TYPE string DEFAULT 'active'
  ASSERT $value IN ['draft', 'active', 'inactive', 'archived'];
DEFINE FIELD website ON organization TYPE option<string>;
DEFINE FIELD created_at ON organization TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON organization TYPE datetime VALUE time::now();
DEFINE INDEX organization_name_idx ON organization FIELDS name SEARCH ANALYZER ascii BM25;