-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Task / Work Schema
-- ============================================================

-- Purpose:
-- Task is the governed unit of work. Actions describe what can happen;
-- tasks track planned, delegated, queued, running, blocked, approved,
-- failed, completed, retried, rolled back, and reconciled execution.

DEFINE TABLE task SCHEMAFULL;

DEFINE FIELD entity ON task TYPE record<entity>;
DEFINE FIELD action ON task TYPE option<record<action>>;
DEFINE FIELD parent_task ON task TYPE option<record<task>>;
DEFINE FIELD root_task ON task TYPE option<record<task>>;

DEFINE FIELD task_type ON task TYPE string
  ASSERT $value IN [
    "intent",
    "objective",
    "action_task",
    "subtask",
    "work_item",
    "approval_task",
    "validation_task",
    "evaluation_task",
    "reconciliation_task",
    "rollback_task",
    "handoff_task",
    "delegation_task",
    "scheduled_task",
    "background_task"
  ];

DEFINE FIELD title ON task TYPE string;
DEFINE FIELD description ON task TYPE option<string>;

DEFINE FIELD status ON task TYPE string DEFAULT "draft"
  ASSERT $value IN [
    "draft",
    "planned",
    "ready",
    "queued",
    "running",
    "blocked",
    "waiting",
    "needs_approval",
    "approved",
    "rejected",
    "completed",
    "failed",
    "cancelled",
    "expired",
    "rolled_back"
  ];

DEFINE FIELD priority ON task TYPE string DEFAULT "medium"
  ASSERT $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD risk_level ON task TYPE string DEFAULT "low"
  ASSERT $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD owner ON task TYPE option<record<identity>>;
DEFINE FIELD assignee ON task TYPE option<record<identity>>;
DEFINE FIELD delegated_by ON task TYPE option<record<identity>>;
DEFINE FIELD delegated_to ON task TYPE option<record<identity>>;

DEFINE FIELD input ON task TYPE object DEFAULT {};
DEFINE FIELD expected_output ON task TYPE option<object>;
DEFINE FIELD output ON task TYPE option<object>;
DEFINE FIELD outcome ON task TYPE option<object>;
DEFINE FIELD evidence ON task TYPE option<object>;
DEFINE FIELD error ON task TYPE option<object>;

DEFINE FIELD dependencies ON task TYPE array<record<task>> DEFAULT [];
DEFINE FIELD blockers ON task TYPE array<record<task>> DEFAULT [];
DEFINE FIELD retry_count ON task TYPE int DEFAULT 0;
DEFINE FIELD max_retries ON task TYPE int DEFAULT 0;
DEFINE FIELD retry_policy ON task TYPE option<object>;
DEFINE FIELD rollback_task ON task TYPE option<record<task>>;
DEFINE FIELD compensation_task ON task TYPE option<record<task>>;

DEFINE FIELD approval_required ON task TYPE bool DEFAULT false;
DEFINE FIELD approval ON task TYPE option<record<governance_approval>>;
DEFINE FIELD policy_evaluations ON task TYPE array<record<policy_evaluation>> DEFAULT [];

DEFINE FIELD sla ON task TYPE option<object>;
DEFINE FIELD estimated_cost ON task TYPE option<number>;
DEFINE FIELD actual_cost ON task TYPE option<number>;
DEFINE FIELD estimated_duration_seconds ON task TYPE option<int>;
DEFINE FIELD actual_duration_seconds ON task TYPE option<int>;

DEFINE FIELD confidence ON task TYPE option<number>
  ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);

DEFINE FIELD progress ON task TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 100;

DEFINE FIELD scheduled_at ON task TYPE option<datetime>;
DEFINE FIELD due_at ON task TYPE option<datetime>;
DEFINE FIELD started_at ON task TYPE option<datetime>;
DEFINE FIELD completed_at ON task TYPE option<datetime>;
DEFINE FIELD created_at ON task TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON task TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON task TYPE option<object>;

DEFINE INDEX task_entity_idx ON task FIELDS entity UNIQUE;
DEFINE INDEX task_action_idx ON task FIELDS action;
DEFINE INDEX task_parent_idx ON task FIELDS parent_task;
DEFINE INDEX task_root_idx ON task FIELDS root_task;
DEFINE INDEX task_status_idx ON task FIELDS status;
DEFINE INDEX task_priority_idx ON task FIELDS priority;
DEFINE INDEX task_assignee_idx ON task FIELDS assignee;
DEFINE INDEX task_due_idx ON task FIELDS due_at;

-- ------------------------------------------------------------
-- Task Event Log
-- ------------------------------------------------------------

DEFINE TABLE task_event SCHEMAFULL;

DEFINE FIELD task ON task_event TYPE record<task>;
DEFINE FIELD event_type ON task_event TYPE string
  ASSERT $value IN [
    "created",
    "planned",
    "queued",
    "started",
    "blocked",
    "unblocked",
    "waiting",
    "approval_requested",
    "approved",
    "rejected",
    "delegated",
    "handoff",
    "retried",
    "completed",
    "failed",
    "cancelled",
    "expired",
    "rolled_back",
    "reconciled"
  ];

DEFINE FIELD actor ON task_event TYPE option<record<identity>>;
DEFINE FIELD from_status ON task_event TYPE option<string>;
DEFINE FIELD to_status ON task_event TYPE option<string>;
DEFINE FIELD reason ON task_event TYPE option<string>;
DEFINE FIELD payload ON task_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON task_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON task_event TYPE option<object>;

DEFINE INDEX task_event_task_idx ON task_event FIELDS task;
DEFINE INDEX task_event_type_idx ON task_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_task_event(
  $task: record<task>,
  $event_type: string,
  $actor: option<record<identity>>,
  $from_status: option<string>,
  $to_status: option<string>,
  $reason: option<string>,
  $payload: object
) {
  RETURN CREATE task_event SET
    task = $task,
    event_type = $event_type,
    actor = $actor,
    from_status = $from_status,
    to_status = $to_status,
    reason = $reason,
    payload = $payload;
};

DEFINE FUNCTION fn::create_task_from_action(
  $entity: record<entity>,
  $action: option<record<action>>,
  $task_type: string,
  $title: string,
  $input: object,
  $owner: option<record<identity>>,
  $assignee: option<record<identity>>
) {
  LET $created = CREATE task SET
    entity = $entity,
    action = $action,
    task_type = $task_type,
    title = $title,
    input = $input,
    owner = $owner,
    assignee = $assignee,
    status = "planned";

  CREATE task_event SET
    task = $created.id,
    event_type = "created",
    actor = $owner,
    to_status = "planned",
    payload = { title: $title };

  RETURN $created;
};

DEFINE FUNCTION fn::start_task(
  $task: record<task>,
  $actor: option<record<identity>>
) {
  LET $before = SELECT * FROM ONLY $task;

  LET $updated = UPDATE $task SET
    status = "running",
    started_at = time::now();

  CREATE task_event SET
    task = $task,
    event_type = "started",
    actor = $actor,
    from_status = $before.status,
    to_status = "running";

  RETURN $updated;
};

DEFINE FUNCTION fn::complete_task(
  $task: record<task>,
  $actor: option<record<identity>>,
  $output: object,
  $confidence: option<number>
) {
  LET $before = SELECT * FROM ONLY $task;

  LET $updated = UPDATE $task SET
    status = "completed",
    output = $output,
    outcome = { status: "success", output: $output },
    confidence = $confidence,
    progress = 100,
    completed_at = time::now(),
    actual_duration_seconds = IF $before.started_at != NONE THEN duration::secs(time::now() - $before.started_at) ELSE NONE END;

  CREATE task_event SET
    task = $task,
    event_type = "completed",
    actor = $actor,
    from_status = $before.status,
    to_status = "completed",
    payload = { confidence: $confidence };

  RETURN $updated;
};

DEFINE FUNCTION fn::fail_task(
  $task: record<task>,
  $actor: option<record<identity>>,
  $error: object,
  $reason: option<string>
) {
  LET $before = SELECT * FROM ONLY $task;

  LET $updated = UPDATE $task SET
    status = "failed",
    error = $error,
    outcome = { status: "failed", error: $error },
    completed_at = time::now();

  CREATE task_event SET
    task = $task,
    event_type = "failed",
    actor = $actor,
    from_status = $before.status,
    to_status = "failed",
    reason = $reason,
    payload = $error;

  RETURN $updated;
};

DEFINE FUNCTION fn::delegate_task(
  $task: record<task>,
  $delegated_by: record<identity>,
  $delegated_to: record<identity>,
  $reason: option<string>
) {
  LET $before = SELECT * FROM ONLY $task;

  LET $updated = UPDATE $task SET
    delegated_by = $delegated_by,
    delegated_to = $delegated_to,
    assignee = $delegated_to,
    status = "queued";

  CREATE task_event SET
    task = $task,
    event_type = "delegated",
    actor = $delegated_by,
    from_status = $before.status,
    to_status = "queued",
    reason = $reason,
    payload = { delegated_to: $delegated_to };

  RETURN $updated;
};

DEFINE FUNCTION fn::task_can_run($task: record<task>) {
  LET $t = SELECT * FROM ONLY $task;
  LET $blocked_dependencies = SELECT id FROM $t.dependencies WHERE status NOT IN ["completed"];
  LET $active_blockers = SELECT id FROM $t.blockers WHERE status NOT IN ["completed", "cancelled", "failed"];

  RETURN $t.status IN ["ready", "queued", "planned"]
    AND array::len($blocked_dependencies) = 0
    AND array::len($active_blockers) = 0
    AND ($t.approval_required = false OR $t.approval != NONE);
};
