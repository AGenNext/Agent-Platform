-- Agent DB Runtime Value Loop Smoke Test
-- Status: design smoke script. Requires schema/design/value-loop-phase1.surql to be applied.
-- Purpose: prove Task -> Output -> Outcome -> ValueRealization -> Learning -> Improvement can be created and queried.

BEGIN TRANSACTION;

LET $identity = CREATE identity CONTENT {
  identity_type: 'human',
  display_name: 'Value Loop Smoke Tester',
  status: 'active'
};

LET $org = CREATE organization CONTENT {
  name: 'AGenNext Runtime Validation',
  industry: 'software',
  status: 'active'
};

LET $project = CREATE project CONTENT {
  name: 'Value Loop Smoke Project',
  scope: 'Validate value loop phase 1 design schema',
  owner: $identity.id,
  status: 'active'
};

LET $milestone = CREATE milestone CONTENT {
  project: $project.id,
  name: 'Phase 1 smoke milestone',
  status: 'active'
};

LET $task = CREATE task CONTENT {
  project: $project.id,
  milestone: $milestone.id,
  title: 'Create value loop validation output',
  status: 'active',
  progress: 1,
  owner: $identity.id,
  assignee: $identity.id
};

LET $evidence = CREATE evidence CONTENT {
  evidence_type: 'validation_report',
  source: 'tests/value-loop-smoke.surql',
  created_at: time::now()
};

LET $output = CREATE output CONTENT {
  task: $task.id,
  project: $project.id,
  milestone: $milestone.id,
  title: 'Value loop smoke output',
  description: 'Smoke output proving value loop creation path.',
  output_type: 'validation_result',
  status: 'active',
  evidence: [$evidence.id],
  created_by: $identity.id
};

LET $outcome = CREATE outcome CONTENT {
  output: $output.id,
  task: $task.id,
  project: $project.id,
  title: 'Value loop path created',
  description: 'Output, outcome, value realization, learning, and improvement records were created.',
  outcome_type: 'achieved',
  evidence: [$evidence.id],
  observed_by: $identity.id
};

LET $value = CREATE value_realization CONTENT {
  outcome: $outcome.id,
  project: $project.id,
  value_type: 'operational',
  state: 'realized',
  metric_name: 'value_loop_records_created',
  baseline_value: 0,
  target_value: 5,
  realized_value: 5,
  unit: 'records',
  cost: 1,
  value_efficiency: 5,
  evidence: [$evidence.id],
  measured_at: time::now(),
  measured_by: $identity.id
};

LET $learning = CREATE learning CONTENT {
  value_realization: $value.id,
  outcome: $outcome.id,
  task: $task.id,
  project: $project.id,
  learning_type: 'quality_learning',
  title: 'Value loop can be represented end-to-end',
  insight: 'The value loop requires schema, taxonomy, evidence, and smoke validation to prove readiness.',
  evidence: [$evidence.id],
  confidence: 0.8,
  recorded_by: $identity.id
};

LET $improvement = CREATE improvement CONTENT {
  learning: $learning.id,
  project: $project.id,
  task: $task.id,
  improvement_type: 'runtime_fix',
  state: 'proposed',
  title: 'Wire value loop smoke test into make check',
  description: 'Add this smoke script to runtime validation gates after schema reconciliation.',
  target_object_type: 'make_target',
  target_object_id: 'make check',
  owner: $identity.id,
  evidence: [$evidence.id]
};

RETURN {
  identity: $identity.id,
  organization: $org.id,
  project: $project.id,
  milestone: $milestone.id,
  task: $task.id,
  evidence: $evidence.id,
  output: $output.id,
  outcome: $outcome.id,
  value_realization: $value.id,
  learning: $learning.id,
  improvement: $improvement.id
};

COMMIT TRANSACTION;

SELECT id, title, output_type FROM output WHERE project = $project.id;
SELECT id, title, outcome_type FROM outcome WHERE project = $project.id;
SELECT id, value_type, state, realized_value FROM value_realization WHERE project = $project.id;
SELECT id, learning_type, title FROM learning WHERE project = $project.id;
SELECT id, improvement_type, state, title FROM improvement WHERE project = $project.id;
