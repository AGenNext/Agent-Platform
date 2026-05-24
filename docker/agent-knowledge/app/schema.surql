-- ─────────────────────────────────────────────────────────────────────────
-- AGenNext Agent Platform — SurrealDB Schema
-- Applied once on startup via startup.py
-- ─────────────────────────────────────────────────────────────────────────

-- ── Objectives ──────────────────────────────────────────────────────────────
DEFINE TABLE objectives SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD title            ON objectives TYPE string;
DEFINE FIELD objective_type   ON objectives TYPE string  DEFAULT 'generic';
DEFINE FIELD workspace_id     ON objectives TYPE option<string>;
DEFINE FIELD payload          ON objectives FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD status           ON objectives TYPE string  DEFAULT 'pending';
DEFINE FIELD created_at       ON objectives TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at       ON objectives TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_objectives_status    ON objectives FIELDS status;
DEFINE INDEX idx_objectives_workspace ON objectives FIELDS workspace_id;

-- Reactive: mark updated_at whenever status changes
DEFINE EVENT objective_status_changed ON objectives
  WHEN $before.status != $after.status
  THEN (UPDATE $after.id SET updated_at = time::now());

-- ── Artifacts ───────────────────────────────────────────────────────────────
DEFINE TABLE artifacts SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD objective_id  ON artifacts TYPE string;
DEFINE FIELD artifact_type ON artifacts TYPE string;
DEFINE FIELD title         ON artifacts TYPE string;
DEFINE FIELD content_ref   ON artifacts TYPE string;
DEFINE FIELD payload       ON artifacts FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD status        ON artifacts TYPE string DEFAULT 'draft';
DEFINE FIELD eval_status   ON artifacts TYPE option<string>;
DEFINE FIELD trust_status  ON artifacts TYPE option<string>;
DEFINE FIELD created_at    ON artifacts TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_artifacts_objective ON artifacts FIELDS objective_id;
DEFINE INDEX idx_artifacts_status    ON artifacts FIELDS status;

-- ── Agents ───────────────────────────────────────────────────────────────────
DEFINE TABLE agents SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD agent_role  ON agents TYPE string;
DEFINE FIELD run_id      ON agents TYPE string;
DEFINE FIELD status      ON agents TYPE string DEFAULT 'idle';
DEFINE FIELD created_at  ON agents TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_agents_run    ON agents FIELDS run_id;
DEFINE INDEX idx_agents_status ON agents FIELDS status;

-- ── Agent tasks ──────────────────────────────────────────────────────────────
DEFINE TABLE agent_tasks SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD agent_id      ON agent_tasks TYPE string;
DEFINE FIELD description   ON agent_tasks TYPE string;
DEFINE FIELD skill_id      ON agent_tasks TYPE option<string>;
DEFINE FIELD status        ON agent_tasks TYPE string DEFAULT 'pending';
DEFINE FIELD output_ref    ON agent_tasks TYPE option<string>;
DEFINE FIELD started_at    ON agent_tasks TYPE option<datetime>;
DEFINE FIELD completed_at  ON agent_tasks TYPE option<datetime>;
DEFINE INDEX idx_tasks_agent ON agent_tasks FIELDS agent_id;

-- ── A2A handoffs (graph edge) ────────────────────────────────────────────────
-- RELATE agent:a -> handoff -> agent:b CONTENT { context: "..." }
DEFINE TABLE handoff SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD context        ON handoff TYPE string DEFAULT '';
DEFINE FIELD handoff_status ON handoff TYPE string DEFAULT 'initiated';
DEFINE FIELD payload        ON handoff FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD created_at     ON handoff TYPE datetime DEFAULT time::now();

-- ── Workflow runs ────────────────────────────────────────────────────────────
DEFINE TABLE workflow_runs SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD definition_id ON workflow_runs TYPE option<string>;
DEFINE FIELD objective_id  ON workflow_runs TYPE string;
DEFINE FIELD status        ON workflow_runs TYPE string DEFAULT 'running';
DEFINE FIELD state         ON workflow_runs FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD started_at    ON workflow_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at  ON workflow_runs TYPE option<datetime>;
DEFINE INDEX idx_runs_objective ON workflow_runs FIELDS objective_id;
DEFINE INDEX idx_runs_status    ON workflow_runs FIELDS status;

-- ── Checkpoints (LangGraph-compatible) ──────────────────────────────────────
DEFINE TABLE checkpoints SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD run_id        ON checkpoints TYPE string;
DEFINE FIELD thread_id     ON checkpoints TYPE string;
DEFINE FIELD checkpoint_id ON checkpoints TYPE string;
DEFINE FIELD node_id       ON checkpoints TYPE string;
DEFINE FIELD state_json    ON checkpoints TYPE string;
DEFINE FIELD metadata      ON checkpoints FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD created_at    ON checkpoints TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_ckpt_run    ON checkpoints FIELDS run_id;
DEFINE INDEX idx_ckpt_thread ON checkpoints FIELDS thread_id, checkpoint_id UNIQUE;

-- ── Eval results ─────────────────────────────────────────────────────────────
DEFINE TABLE eval_results SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD artifact_id      ON eval_results TYPE string;
DEFINE FIELD rubric_id        ON eval_results TYPE option<string>;
DEFINE FIELD composite_score  ON eval_results TYPE float;
DEFINE FIELD dimension_scores ON eval_results FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD passed           ON eval_results TYPE bool;
DEFINE FIELD rationale        ON eval_results TYPE option<string>;
DEFINE FIELD evaluated_at     ON eval_results TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_eval_artifact ON eval_results FIELDS artifact_id;

-- ── Trust scores ─────────────────────────────────────────────────────────────
DEFINE TABLE trust_scores SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD artifact_id         ON trust_scores TYPE string;
DEFINE FIELD score               ON trust_scores TYPE float;
DEFINE FIELD verified            ON trust_scores TYPE bool DEFAULT false;
DEFINE FIELD provenance          ON trust_scores FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD verification_method ON trust_scores TYPE string DEFAULT 'chain';
DEFINE FIELD computed_at         ON trust_scores TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_trust_artifact ON trust_scores FIELDS artifact_id;

-- ── Usage records (FinOps) ───────────────────────────────────────────────────
DEFINE TABLE usage_records SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD objective_id  ON usage_records TYPE string;
DEFINE FIELD model_id      ON usage_records TYPE string;
DEFINE FIELD provider      ON usage_records TYPE string;
DEFINE FIELD workspace_id  ON usage_records TYPE option<string>;
DEFINE FIELD input_tokens  ON usage_records TYPE int   DEFAULT 0;
DEFINE FIELD output_tokens ON usage_records TYPE int   DEFAULT 0;
DEFINE FIELD cost_usd      ON usage_records TYPE float DEFAULT 0.0;
DEFINE FIELD recorded_at   ON usage_records TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_usage_objective ON usage_records FIELDS objective_id;
DEFINE INDEX idx_usage_model     ON usage_records FIELDS model_id;

-- ── Routing rules ────────────────────────────────────────────────────────────
DEFINE TABLE routing_rules SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD task_type         ON routing_rules TYPE string;
DEFINE FIELD preferred_provider ON routing_rules TYPE string;
DEFINE FIELD models            ON routing_rules FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD max_cost_per_call ON routing_rules TYPE float DEFAULT 0.10;
DEFINE FIELD daily_budget      ON routing_rules TYPE float DEFAULT 10.0;
DEFINE FIELD enabled           ON routing_rules TYPE bool  DEFAULT true;
DEFINE INDEX idx_routing_task ON routing_rules FIELDS task_type UNIQUE;
