-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Workflow Schema
-- ============================================================

-- Purpose:
-- Workflow connects tasks, actions, decisions, approvals, agents, humans,
-- and tools into governed execution graphs. It supports sequence,
-- parallelism, conditions, loops, approvals, delegation, handoff, retry,
-- rollback, compensation, timeout, escalation, BPMN/DMN, LangGraph,
-- A2A, MCP, human workflows, business workflows, and agent workflows.

DEFINE TABLE workflow SCHEMAFULL;

DEFINE FIELD entity ON workflow TYPE record<entity>;
DEFINE FIELD owner ON workflow TYPE option<record<identity>>;
DEFINE FIELD workflow_type ON workflow TYPE string
  ASSERT $value IN [
    "agent_workflow",
    "human_workflow",
    "business_workflow",
    "approval_workflow",
    "delegation_workflow",
    "handoff_workflow",
    "reconciliation_workflow",
    "rollback_workflow",
    "compensation_workflow",
    "scheduled_workflow",
    "event_driven_workflow",
    "bpmn_workflow",
    "dmn_decision_flow",
    "langgraph_workflow",
    "a2a_workflow",
    "mcp_tool_workflow"
  ];

DEFINE FIELD name ON workflow TYPE string;
DEFINE FIELD description ON workflow TYPE option<string>;
DEFINE FIELD status ON workflow TYPE string DEFAULT "draft"
  ASSERT $value IN ["draft", "active", "inactive", "deprecated", "archived"];

DEFINE FIELD version ON workflow TYPE string DEFAULT "0.1.0";
DEFINE FIELD definition ON workflow TYPE object DEFAULT {};
DEFINE FIELD input_schema ON workflow TYPE option<object>;
DEFINE FIELD output_schema ON workflow TYPE option<object>;
DEFINE FIELD policy_refs ON workflow TYPE array<record<governance_object>> DEFAULT [];
DEFINE FIELD protocol_refs ON workflow TYPE array<string> DEFAULT [];
DEFINE FIELD tags ON workflow TYPE array<string> DEFAULT [];

DEFINE FIELD created_at ON workflow TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON workflow TYPE datetime VALUE time::now();
DEFINE FIELD valid_from ON workflow TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON workflow TYPE option<datetime>;
DEFINE FIELD metadata ON workflow TYPE option<object>;

DEFINE INDEX workflow_entity_idx ON workflow FIELDS entity UNIQUE;
DEFINE INDEX workflow_type_idx ON workflow FIELDS workflow_type;
DEFINE INDEX workflow_status_idx ON workflow FIELDS status;
DEFINE INDEX workflow_name_idx ON workflow FIELDS name SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Workflow Step
-- ------------------------------------------------------------

DEFINE TABLE workflow_step SCHEMAFULL;

DEFINE FIELD workflow ON workflow_step TYPE record<workflow>;
DEFINE FIELD entity ON workflow_step TYPE record<entity>;
DEFINE FIELD step_key ON workflow_step TYPE string;
DEFINE FIELD name ON workflow_step TYPE string;
DEFINE FIELD description ON workflow_step TYPE option<string>;
DEFINE FIELD step_type ON workflow_step TYPE string
  ASSERT $value IN [
    "start",
    "end",
    "task",
    "action",
    "decision",
    "approval",
    "condition",
    "parallel",
    "join",
    "loop",
    "wait",
    "timer",
    "event",
    "handoff",
    "delegation",
    "tool_call",
    "agent_call",
    "human_task",
    "validation",
    "evaluation",
    "rollback",
    "compensation",
    "escalation"
  ];

DEFINE FIELD action ON workflow_step TYPE option<record<action>>;
DEFINE FIELD task_template ON workflow_step TYPE option<object>;
DEFINE FIELD condition ON workflow_step TYPE option<object>;
DEFINE FIELD retry_policy ON workflow_step TYPE option<object>;
DEFINE FIELD timeout_policy ON workflow_step TYPE option<object>;
DEFINE FIELD compensation_step ON workflow_step TYPE option<record<workflow_step>>;
DEFINE FIELD rollback_step ON workflow_step TYPE option<record<workflow_step>>;
DEFINE FIELD approval_required ON workflow_step TYPE bool DEFAULT false;
DEFINE FIELD human_required ON workflow_step TYPE bool DEFAULT false;
DEFINE FIELD risk_level ON workflow_step TYPE string DEFAULT "low" ASSERT $value IN ["low", "medium", "high", "critical"];
DEFINE FIELD metadata ON workflow_step TYPE option<object>;
DEFINE FIELD created_at ON workflow_step TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON workflow_step TYPE datetime VALUE time::now();

DEFINE INDEX workflow_step_workflow_idx ON workflow_step FIELDS workflow;
DEFINE INDEX workflow_step_entity_idx ON workflow_step FIELDS entity UNIQUE;
DEFINE INDEX workflow_step_key_idx ON workflow_step FIELDS workflow, step_key UNIQUE;
DEFINE INDEX workflow_step_type_idx ON workflow_step FIELDS step_type;

-- ------------------------------------------------------------
-- Workflow Edge
-- ------------------------------------------------------------

DEFINE TABLE workflow_edge TYPE RELATION IN workflow_step OUT workflow_step SCHEMAFULL;

DEFINE FIELD workflow ON workflow_edge TYPE record<workflow>;
DEFINE FIELD edge_type ON workflow_edge TYPE string DEFAULT "sequence"
  ASSERT $value IN [
    "sequence",
    "conditional",
    "parallel",
    "join",
    "loop",
    "success",
    "failure",
    "timeout",
    "approval",
    "rejection",
    "handoff",
    "delegation",
    "escalation",
    "rollback",
    "compensation"
  ];

DEFINE FIELD condition ON workflow_edge TYPE option<object>;
DEFINE FIELD priority ON workflow_edge TYPE int DEFAULT 0;
DEFINE FIELD created_at ON workflow_edge TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON workflow_edge TYPE option<object>;

DEFINE INDEX workflow_edge_workflow_idx ON workflow_edge FIELDS workflow;
DEFINE INDEX workflow_edge_type_idx ON workflow_edge FIELDS edge_type;

-- ------------------------------------------------------------
-- Workflow Run
-- ------------------------------------------------------------

DEFINE TABLE workflow_run SCHEMAFULL;

DEFINE FIELD workflow ON workflow_run TYPE record<workflow>;
DEFINE FIELD entity ON workflow_run TYPE record<entity>;
DEFINE FIELD subject ON workflow_run TYPE option<record<identity>>;
DEFINE FIELD root_task ON workflow_run TYPE option<record<task>>;
DEFINE FIELD status ON workflow_run TYPE string DEFAULT "queued"
  ASSERT $value IN [
    "queued",
    "running",
    "waiting",
    "blocked",
    "needs_approval",
    "completed",
    "failed",
    "cancelled",
    "expired",
    "rolled_back",
    "compensated"
  ];

DEFINE FIELD input ON workflow_run TYPE object DEFAULT {};
DEFINE FIELD output ON workflow_run TYPE option<object>;
DEFINE FIELD context ON workflow_run TYPE object DEFAULT {};
DEFINE FIELD current_steps ON workflow_run TYPE array<record<workflow_step>> DEFAULT [];
DEFINE FIELD completed_steps ON workflow_run TYPE array<record<workflow_step>> DEFAULT [];
DEFINE FIELD failed_steps ON workflow_run TYPE array<record<workflow_step>> DEFAULT [];
DEFINE FIELD decisions ON workflow_run TYPE array<record<decision>> DEFAULT [];
DEFINE FIELD tasks ON workflow_run TYPE array<record<task>> DEFAULT [];
DEFINE FIELD approvals ON workflow_run TYPE array<record<governance_approval>> DEFAULT [];
DEFINE FIELD error ON workflow_run TYPE option<object>;
DEFINE FIELD confidence ON workflow_run TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD started_at ON workflow_run TYPE option<datetime>;
DEFINE FIELD completed_at ON workflow_run TYPE option<datetime>;
DEFINE FIELD created_at ON workflow_run TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON workflow_run TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON workflow_run TYPE option<object>;

DEFINE INDEX workflow_run_workflow_idx ON workflow_run FIELDS workflow;
DEFINE INDEX workflow_run_entity_idx ON workflow_run FIELDS entity UNIQUE;
DEFINE INDEX workflow_run_subject_idx ON workflow_run FIELDS subject;
DEFINE INDEX workflow_run_status_idx ON workflow_run FIELDS status;

-- ------------------------------------------------------------
-- Workflow Run Event
-- ------------------------------------------------------------

DEFINE TABLE workflow_run_event SCHEMAFULL;

DEFINE FIELD workflow_run ON workflow_run_event TYPE record<workflow_run>;
DEFINE FIELD event_type ON workflow_run_event TYPE string
  ASSERT $value IN [
    "created",
    "started",
    "step_started",
    "step_completed",
    "step_failed",
    "condition_evaluated",
    "approval_requested",
    "approved",
    "rejected",
    "handoff",
    "delegated",
    "retry",
    "timeout",
    "escalated",
    "rollback_started",
    "rolled_back",
    "compensation_started",
    "compensated",
    "completed",
    "failed",
    "cancelled"
  ];

DEFINE FIELD step ON workflow_run_event TYPE option<record<workflow_step>>;
DEFINE FIELD actor ON workflow_run_event TYPE option<record<identity>>;
DEFINE FIELD reason ON workflow_run_event TYPE option<string>;
DEFINE FIELD payload ON workflow_run_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON workflow_run_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON workflow_run_event TYPE option<object>;

DEFINE INDEX workflow_run_event_run_idx ON workflow_run_event FIELDS workflow_run;
DEFINE INDEX workflow_run_event_type_idx ON workflow_run_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::start_workflow_run(
  $workflow: record<workflow>,
  $entity: record<entity>,
  $subject: option<record<identity>>,
  $input: object
) {
  LET $run = CREATE workflow_run SET
    workflow = $workflow,
    entity = $entity,
    subject = $subject,
    input = $input,
    status = "running",
    started_at = time::now();

  CREATE workflow_run_event SET
    workflow_run = $run.id,
    event_type = "started",
    actor = $subject,
    payload = { input: $input };

  RETURN $run;
};

DEFINE FUNCTION fn::complete_workflow_run(
  $workflow_run: record<workflow_run>,
  $actor: option<record<identity>>,
  $output: object,
  $confidence: option<number>
) {
  LET $updated = UPDATE $workflow_run SET
    status = "completed",
    output = $output,
    confidence = $confidence,
    completed_at = time::now();

  CREATE workflow_run_event SET
    workflow_run = $workflow_run,
    event_type = "completed",
    actor = $actor,
    payload = { output: $output, confidence: $confidence };

  RETURN $updated;
};

DEFINE FUNCTION fn::fail_workflow_run(
  $workflow_run: record<workflow_run>,
  $actor: option<record<identity>>,
  $error: object,
  $reason: option<string>
) {
  LET $updated = UPDATE $workflow_run SET
    status = "failed",
    error = $error,
    completed_at = time::now();

  CREATE workflow_run_event SET
    workflow_run = $workflow_run,
    event_type = "failed",
    actor = $actor,
    reason = $reason,
    payload = $error;

  RETURN $updated;
};

DEFINE FUNCTION fn::workflow_requires_approval($workflow_step: record<workflow_step>) {
  LET $step = SELECT * FROM ONLY $workflow_step;
  RETURN $step.approval_required = true
    OR $step.human_required = true
    OR $step.risk_level IN ["high", "critical"];
};
