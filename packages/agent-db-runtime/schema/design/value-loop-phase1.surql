-- Agent DB Runtime Phase 1 Value Loop Design Schema
-- Status: design artifact only.
-- Do not include in runtime load order until validated.
-- Taxonomy dependencies:
--   packages/agent-db-runtime/taxonomies/runtime-taxonomy.v0.1.yaml
--   packages/agent-db-runtime/taxonomies/value-loop-taxonomy.v0.1.yaml

-- Phase 1 closes the loop:
-- Task -> Output -> Outcome -> ValueRealization -> Learning -> Improvement

DEFINE TABLE output SCHEMAFULL;
DEFINE FIELD task ON output TYPE option<record<task>>;
DEFINE FIELD project ON output TYPE option<record<project>>;
DEFINE FIELD milestone ON output TYPE option<record<milestone>>;
DEFINE FIELD title ON output TYPE string;
DEFINE FIELD description ON output TYPE option<string>;
DEFINE FIELD output_type ON output TYPE string ASSERT $value IN [
  'document',
  'code',
  'report',
  'decision_record',
  'validation_result',
  'artifact',
  'configuration',
  'dataset',
  'workflow'
];
DEFINE FIELD status ON output TYPE string DEFAULT 'draft';
DEFINE FIELD artifact ON output TYPE option<record<artifact>>;
DEFINE FIELD evidence ON output TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD created_at ON output TYPE datetime DEFAULT time::now();
DEFINE FIELD created_by ON output TYPE option<record<identity>>;
DEFINE INDEX output_by_task ON output FIELDS task;
DEFINE INDEX output_by_project ON output FIELDS project;
DEFINE INDEX output_by_type ON output FIELDS output_type;

DEFINE TABLE outcome SCHEMAFULL;
DEFINE FIELD output ON outcome TYPE option<record<output>>;
DEFINE FIELD task ON outcome TYPE option<record<task>>;
DEFINE FIELD project ON outcome TYPE option<record<project>>;
DEFINE FIELD objective_id ON outcome TYPE option<string>;
DEFINE FIELD title ON outcome TYPE string;
DEFINE FIELD description ON outcome TYPE option<string>;
DEFINE FIELD outcome_type ON outcome TYPE string ASSERT $value IN [
  'achieved',
  'partially_achieved',
  'not_achieved',
  'exceeded',
  'blocked',
  'unintended'
];
DEFINE FIELD evidence ON outcome TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD evaluation ON outcome TYPE option<record<evaluation>>;
DEFINE FIELD observed_at ON outcome TYPE datetime DEFAULT time::now();
DEFINE FIELD observed_by ON outcome TYPE option<record<identity>>;
DEFINE INDEX outcome_by_output ON outcome FIELDS output;
DEFINE INDEX outcome_by_project ON outcome FIELDS project;
DEFINE INDEX outcome_by_type ON outcome FIELDS outcome_type;

DEFINE TABLE value_realization SCHEMAFULL;
DEFINE FIELD outcome ON value_realization TYPE record<outcome>;
DEFINE FIELD project ON value_realization TYPE option<record<project>>;
DEFINE FIELD beneficiary_id ON value_realization TYPE option<string>;
DEFINE FIELD value_type ON value_realization TYPE string ASSERT $value IN [
  'financial',
  'operational',
  'user',
  'compliance',
  'trust',
  'knowledge',
  'risk_reduction',
  'time_saved',
  'quality_improvement',
  'reliability_improvement'
];
DEFINE FIELD state ON value_realization TYPE string DEFAULT 'not_started' ASSERT $value IN [
  'not_started',
  'measuring',
  'realized',
  'partially_realized',
  'not_realized',
  'disputed'
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
DEFINE INDEX value_realization_by_outcome ON value_realization FIELDS outcome;
DEFINE INDEX value_realization_by_project ON value_realization FIELDS project;
DEFINE INDEX value_realization_by_type ON value_realization FIELDS value_type;
DEFINE INDEX value_realization_by_state ON value_realization FIELDS state;

DEFINE TABLE learning SCHEMAFULL;
DEFINE FIELD value_realization ON learning TYPE option<record<value_realization>>;
DEFINE FIELD outcome ON learning TYPE option<record<outcome>>;
DEFINE FIELD task ON learning TYPE option<record<task>>;
DEFINE FIELD project ON learning TYPE option<record<project>>;
DEFINE FIELD decision ON learning TYPE option<record<decision>>;
DEFINE FIELD learning_type ON learning TYPE string ASSERT $value IN [
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
  'quality_learning'
];
DEFINE FIELD title ON learning TYPE string;
DEFINE FIELD insight ON learning TYPE string;
DEFINE FIELD evidence ON learning TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD confidence ON learning TYPE option<number>;
DEFINE FIELD knowledge_candidate ON learning TYPE option<record<knowledge_candidate>>;
DEFINE FIELD recorded_at ON learning TYPE datetime DEFAULT time::now();
DEFINE FIELD recorded_by ON learning TYPE option<record<identity>>;
DEFINE INDEX learning_by_project ON learning FIELDS project;
DEFINE INDEX learning_by_type ON learning FIELDS learning_type;
DEFINE INDEX learning_by_value_realization ON learning FIELDS value_realization;

DEFINE TABLE improvement SCHEMAFULL;
DEFINE FIELD learning ON improvement TYPE option<record<learning>>;
DEFINE FIELD project ON improvement TYPE option<record<project>>;
DEFINE FIELD task ON improvement TYPE option<record<task>>;
DEFINE FIELD improvement_type ON improvement TYPE string ASSERT $value IN [
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
  'risk_mitigation'
];
DEFINE FIELD state ON improvement TYPE string DEFAULT 'proposed' ASSERT $value IN [
  'proposed',
  'accepted',
  'rejected',
  'planned',
  'in_progress',
  'applied',
  'validated'
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
DEFINE INDEX improvement_by_project ON improvement FIELDS project;
DEFINE INDEX improvement_by_type ON improvement FIELDS improvement_type;
DEFINE INDEX improvement_by_state ON improvement FIELDS state;
DEFINE INDEX improvement_by_learning ON improvement FIELDS learning;
