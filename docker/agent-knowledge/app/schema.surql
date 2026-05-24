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

-- Reactive: log status transitions to events table
DEFINE EVENT objective_status_changed ON objectives
  WHEN $before.status != $after.status
  THEN {
    UPDATE $after.id SET updated_at = time::now();
    CREATE events SET
      entity_type = 'objective',
      entity_id   = string::concat('', $after.id),
      event_type  = 'status_changed',
      payload     = { from: $before.status, to: $after.status, title: $after.title },
      occurred_at = time::now();
  };

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

-- ── Discovered models registry ───────────────────────────────────────────────
-- Populated by auto-discovery probes (Ollama /api/tags, Anthropic known list).
-- Router reads this table; routing_rules reference model_id from here.
DEFINE TABLE discovered_models SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD model_id         ON discovered_models TYPE string;
DEFINE FIELD provider         ON discovered_models TYPE string;  -- ollama | anthropic | openai | cohere | ...
DEFINE FIELD display_name     ON discovered_models TYPE string;
DEFINE FIELD model_family     ON discovered_models TYPE option<string>;
DEFINE FIELD context_window   ON discovered_models TYPE option<int>;
DEFINE FIELD input_modalities ON discovered_models FLEXIBLE TYPE array DEFAULT [];  -- text | image | audio
DEFINE FIELD output_modalities ON discovered_models FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD capabilities     ON discovered_models FLEXIBLE TYPE object DEFAULT {};
  -- { reasoning: bool, code: bool, vision: bool, function_calling: bool, streaming: bool }
DEFINE FIELD cost_per_1k_input  ON discovered_models TYPE float DEFAULT 0.0;  -- USD
DEFINE FIELD cost_per_1k_output ON discovered_models TYPE float DEFAULT 0.0;  -- USD
DEFINE FIELD max_output_tokens  ON discovered_models TYPE option<int>;
DEFINE FIELD is_local           ON discovered_models TYPE bool DEFAULT false;
DEFINE FIELD is_available       ON discovered_models TYPE bool DEFAULT true;
DEFINE FIELD last_seen          ON discovered_models TYPE datetime DEFAULT time::now();
DEFINE FIELD discovered_at      ON discovered_models TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata           ON discovered_models FLEXIBLE TYPE object DEFAULT {};
DEFINE INDEX idx_model_id       ON discovered_models FIELDS model_id, provider UNIQUE;
DEFINE INDEX idx_model_provider ON discovered_models FIELDS provider;
DEFINE INDEX idx_model_available ON discovered_models FIELDS is_available;

-- ── Model performance history ─────────────────────────────────────────────────
-- One record per model call outcome — used by intelligent router to score models.
DEFINE TABLE model_performance SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD model_id          ON model_performance TYPE string;
DEFINE FIELD provider          ON model_performance TYPE string;
DEFINE FIELD task_type         ON model_performance TYPE string;
DEFINE FIELD objective_id      ON model_performance TYPE option<string>;
DEFINE FIELD latency_ms        ON model_performance TYPE option<int>;
DEFINE FIELD input_tokens      ON model_performance TYPE int DEFAULT 0;
DEFINE FIELD output_tokens     ON model_performance TYPE int DEFAULT 0;
DEFINE FIELD cost_usd          ON model_performance TYPE float DEFAULT 0.0;
DEFINE FIELD eval_score        ON model_performance TYPE option<float>;  -- CLEAR composite if available
DEFINE FIELD success           ON model_performance TYPE bool DEFAULT true;
DEFINE FIELD error_code        ON model_performance TYPE option<string>;
DEFINE FIELD recorded_at       ON model_performance TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_perf_model    ON model_performance FIELDS model_id, task_type;
DEFINE INDEX idx_perf_time     ON model_performance FIELDS recorded_at;

-- ── Agent-Constraints policy store ──────────────────────────────────────────
-- Policy types: workspace_budget | objective_budget | model_allowlist |
--               model_denylist | max_cost_per_call | token_quota
DEFINE TABLE agent_constraints SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD policy_type      ON agent_constraints TYPE string;
DEFINE FIELD scope            ON agent_constraints TYPE string DEFAULT 'global';
  -- global | workspace:<id> | objective:<id> | task_type:<name>
DEFINE FIELD target_id        ON agent_constraints TYPE option<string>;
DEFINE FIELD value            ON agent_constraints FLEXIBLE TYPE any;
  -- float for budgets, array for lists
DEFINE FIELD unit             ON agent_constraints TYPE string DEFAULT 'usd';
DEFINE FIELD period           ON agent_constraints TYPE string DEFAULT 'daily';
  -- daily | weekly | monthly | per_call | total
DEFINE FIELD enabled          ON agent_constraints TYPE bool DEFAULT true;
DEFINE FIELD created_at       ON agent_constraints TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at       ON agent_constraints TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_constraint_scope  ON agent_constraints FIELDS scope, policy_type;
DEFINE INDEX idx_constraint_target ON agent_constraints FIELDS target_id;

-- ── Runtime events (audit trail) ────────────────────────────────────────────
DEFINE TABLE events SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD entity_type ON events TYPE string;
DEFINE FIELD entity_id   ON events TYPE string;
DEFINE FIELD event_type  ON events TYPE string;
DEFINE FIELD payload     ON events FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD occurred_at ON events TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_events_entity ON events FIELDS entity_type, entity_id;
DEFINE INDEX idx_events_time   ON events FIELDS occurred_at;

-- ── Routing rules ────────────────────────────────────────────────────────────
DEFINE TABLE routing_rules SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD task_type         ON routing_rules TYPE string;
DEFINE FIELD preferred_provider ON routing_rules TYPE string;
DEFINE FIELD models            ON routing_rules FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD max_cost_per_call ON routing_rules TYPE float DEFAULT 0.10;
DEFINE FIELD daily_budget      ON routing_rules TYPE float DEFAULT 10.0;
DEFINE FIELD enabled           ON routing_rules TYPE bool  DEFAULT true;
DEFINE INDEX idx_routing_task ON routing_rules FIELDS task_type UNIQUE;

-- ── Maturity assessments ─────────────────────────────────────────────────────
DEFINE TABLE maturity_scores SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD objective_id   ON maturity_scores TYPE string;
DEFINE FIELD score          ON maturity_scores TYPE float;
DEFINE FIELD level          ON maturity_scores TYPE string;  -- initial/developing/capable/optimising
DEFINE FIELD gates          ON maturity_scores FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD assessed_at    ON maturity_scores TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_maturity_objective ON maturity_scores FIELDS objective_id;

-- ── Human approvals ───────────────────────────────────────────────────────────
DEFINE TABLE approvals SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD objective_id   ON approvals TYPE string;
DEFINE FIELD status         ON approvals TYPE string DEFAULT 'pending';  -- pending/approved/rejected
DEFINE FIELD requested_by   ON approvals TYPE option<string>;
DEFINE FIELD reviewed_by    ON approvals TYPE option<string>;
DEFINE FIELD notes          ON approvals TYPE option<string>;
DEFINE FIELD readiness_snapshot ON approvals FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD requested_at   ON approvals TYPE datetime DEFAULT time::now();
DEFINE FIELD reviewed_at    ON approvals TYPE option<datetime>;
DEFINE INDEX idx_approvals_objective ON approvals FIELDS objective_id;

-- ═══════════════════════════════════════════════════════════════════════════
-- REFERENCED FRAMEWORK MODELS
-- Each block is the canonical SurrealQL representation of an external
-- framework. All fields are defined against the framework's own spec.
-- Python service layer is thin — it reads/writes these tables via queries.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── CLEAR Evaluation Rubric ──────────────────────────────────────────────────
-- Source: structured output quality assessment framework used by RealGraph.
-- Aligned with: Ragas (Es et al. 2023), G-Eval (Liu et al. 2023),
--              "Evaluating LLM Outputs: A Survey" (Chang et al. 2023).
-- Dimensions: Completeness · Logical · Evidence · Accuracy · Relevance
-- Evidence is gated by W3C PROV-DM source_grounding (see prov_records table).
DEFINE TABLE clear_evals SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD artifact_id          ON clear_evals TYPE string;
DEFINE FIELD rubric_id            ON clear_evals TYPE option<string>;
DEFINE FIELD completeness         ON clear_evals TYPE float  ASSERT $value >= 0.0 AND $value <= 1.0;
DEFINE FIELD logical              ON clear_evals TYPE float  ASSERT $value >= 0.0 AND $value <= 1.0;
DEFINE FIELD evidence             ON clear_evals TYPE float  ASSERT $value >= 0.0 AND $value <= 1.0;
DEFINE FIELD accuracy             ON clear_evals TYPE float  ASSERT $value >= 0.0 AND $value <= 1.0;
DEFINE FIELD relevance            ON clear_evals TYPE float  ASSERT $value >= 0.0 AND $value <= 1.0;
DEFINE FIELD weights              ON clear_evals FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD composite_score      ON clear_evals TYPE float;
DEFINE FIELD passed               ON clear_evals TYPE bool;
DEFINE FIELD threshold            ON clear_evals TYPE float  DEFAULT 0.70;
DEFINE FIELD source_grounding_enforced ON clear_evals TYPE bool DEFAULT false;
DEFINE FIELD rationale            ON clear_evals TYPE option<string>;
DEFINE FIELD evaluated_at         ON clear_evals TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_clear_artifact   ON clear_evals FIELDS artifact_id;
DEFINE INDEX idx_clear_time       ON clear_evals FIELDS evaluated_at;

-- ── FinOps Foundation FOCUS Model ───────────────────────────────────────────
-- Source: FinOps Foundation FOCUS (FinOps Open Cost and Usage Specification)
--         https://focus.finops.org — v1.0 column set adapted for LLM workloads.
-- Key columns: BillingAccount, Service, SKU, UsageType, EffectiveCost,
--              ListCost, UsageQuantity, UsageUnit, Tags (objective/workspace).
DEFINE TABLE finops_records SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD billing_account_id   ON finops_records TYPE string;
DEFINE FIELD billing_period_start ON finops_records TYPE datetime;
DEFINE FIELD billing_period_end   ON finops_records TYPE datetime;
DEFINE FIELD service_name         ON finops_records TYPE string;   -- e.g. "anthropic", "ollama"
DEFINE FIELD service_category     ON finops_records TYPE string;   -- e.g. "AI and Machine Learning"
DEFINE FIELD sku_id               ON finops_records TYPE string;   -- model_id
DEFINE FIELD sku_price_id         ON finops_records TYPE option<string>;
DEFINE FIELD usage_type           ON finops_records TYPE string;   -- "input_tokens" | "output_tokens"
DEFINE FIELD usage_quantity       ON finops_records TYPE float;
DEFINE FIELD usage_unit           ON finops_records TYPE string;   -- "tokens"
DEFINE FIELD list_unit_price      ON finops_records TYPE float;
DEFINE FIELD list_cost            ON finops_records TYPE float;
DEFINE FIELD effective_cost       ON finops_records TYPE float;
DEFINE FIELD billed_cost          ON finops_records TYPE float;
DEFINE FIELD resource_id          ON finops_records TYPE option<string>;   -- objective_id
DEFINE FIELD resource_name        ON finops_records TYPE option<string>;
DEFINE FIELD region_id            ON finops_records TYPE option<string>;
DEFINE FIELD tags                 ON finops_records FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD charge_period_start  ON finops_records TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_finops_service   ON finops_records FIELDS service_name;
DEFINE INDEX idx_finops_sku       ON finops_records FIELDS sku_id;
DEFINE INDEX idx_finops_resource  ON finops_records FIELDS resource_id;
DEFINE INDEX idx_finops_period    ON finops_records FIELDS billing_period_start;

-- ── Google A2A Protocol (Agent-to-Agent) ─────────────────────────────────────
-- Source: Google Agent-to-Agent (A2A) protocol specification v0.2.
--         https://google.github.io/A2A
-- Key objects: Task, Message, Artifact, AgentCard, TaskState.
-- Task lifecycle: submitted → working → input-required → completed | failed | canceled
DEFINE TABLE a2a_tasks SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD task_id              ON a2a_tasks TYPE string;
DEFINE FIELD session_id           ON a2a_tasks TYPE option<string>;
DEFINE FIELD agent_card_url       ON a2a_tasks TYPE option<string>;
DEFINE FIELD status_state         ON a2a_tasks TYPE string DEFAULT 'submitted';
  -- submitted | working | input-required | completed | failed | canceled
DEFINE FIELD status_message       ON a2a_tasks FLEXIBLE TYPE option<object>;
DEFINE FIELD status_timestamp     ON a2a_tasks TYPE datetime DEFAULT time::now();
DEFINE FIELD history              ON a2a_tasks FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD artifacts            ON a2a_tasks FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD metadata             ON a2a_tasks FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD push_notification    ON a2a_tasks FLEXIBLE TYPE option<object>;
DEFINE FIELD created_at           ON a2a_tasks TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at           ON a2a_tasks TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_a2a_task_id      ON a2a_tasks FIELDS task_id UNIQUE;
DEFINE INDEX idx_a2a_session      ON a2a_tasks FIELDS session_id;
DEFINE INDEX idx_a2a_status       ON a2a_tasks FIELDS status_state;

DEFINE TABLE a2a_messages SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD task_id              ON a2a_messages TYPE string;
DEFINE FIELD role                 ON a2a_messages TYPE string;  -- "user" | "agent"
DEFINE FIELD parts                ON a2a_messages FLEXIBLE TYPE array DEFAULT [];
  -- part types: text { text: string } | file { file: {uri, mimeType, bytes} }
  --             data { data: object }
DEFINE FIELD metadata             ON a2a_messages FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD sent_at              ON a2a_messages TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_a2a_msg_task     ON a2a_messages FIELDS task_id;
DEFINE INDEX idx_a2a_msg_time     ON a2a_messages FIELDS sent_at;

DEFINE TABLE a2a_agent_cards SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD name                 ON a2a_agent_cards TYPE string;
DEFINE FIELD description          ON a2a_agent_cards TYPE option<string>;
DEFINE FIELD url                  ON a2a_agent_cards TYPE string;
DEFINE FIELD version              ON a2a_agent_cards TYPE string DEFAULT '0.0.1';
DEFINE FIELD capabilities         ON a2a_agent_cards FLEXIBLE TYPE object DEFAULT {};
  -- { streaming: bool, pushNotifications: bool, stateTransitionHistory: bool }
DEFINE FIELD skills               ON a2a_agent_cards FLEXIBLE TYPE array DEFAULT [];
  -- [{ id, name, description, tags, examples, inputModes, outputModes }]
DEFINE FIELD default_input_modes  ON a2a_agent_cards FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD default_output_modes ON a2a_agent_cards FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD authentication       ON a2a_agent_cards FLEXIBLE TYPE option<object>;
DEFINE FIELD provider             ON a2a_agent_cards FLEXIBLE TYPE option<object>;
DEFINE FIELD registered_at        ON a2a_agent_cards TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_a2a_card_name    ON a2a_agent_cards FIELDS name;
DEFINE INDEX idx_a2a_card_url     ON a2a_agent_cards FIELDS url UNIQUE;

-- ── LangGraph Checkpoint Model ───────────────────────────────────────────────
-- Source: LangChain LangGraph framework — BaseCheckpointSaver interface.
--         https://langchain-ai.github.io/langgraph/concepts/persistence/
-- Supports: thread_id → checkpoint_id → state_snapshot lineage.
-- Compatible with: PostgresSaver, SqliteSaver, MemorySaver interface contract.
DEFINE TABLE lg_checkpoints SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD thread_id            ON lg_checkpoints TYPE string;
DEFINE FIELD checkpoint_ns        ON lg_checkpoints TYPE string DEFAULT '';
DEFINE FIELD checkpoint_id        ON lg_checkpoints TYPE string;
DEFINE FIELD parent_checkpoint_id ON lg_checkpoints TYPE option<string>;
DEFINE FIELD type                 ON lg_checkpoints TYPE string DEFAULT 'checkpoint';
DEFINE FIELD channel_values       ON lg_checkpoints FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD channel_versions     ON lg_checkpoints FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD versions_seen        ON lg_checkpoints FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD pending_sends        ON lg_checkpoints FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD created_at           ON lg_checkpoints TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_lg_ckpt_thread   ON lg_checkpoints FIELDS thread_id, checkpoint_ns, checkpoint_id UNIQUE;
DEFINE INDEX idx_lg_ckpt_parent   ON lg_checkpoints FIELDS parent_checkpoint_id;

DEFINE TABLE lg_checkpoint_writes SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD thread_id            ON lg_checkpoint_writes TYPE string;
DEFINE FIELD checkpoint_ns        ON lg_checkpoint_writes TYPE string DEFAULT '';
DEFINE FIELD checkpoint_id        ON lg_checkpoint_writes TYPE string;
DEFINE FIELD task_id              ON lg_checkpoint_writes TYPE string;
DEFINE FIELD idx                  ON lg_checkpoint_writes TYPE int;
DEFINE FIELD channel              ON lg_checkpoint_writes TYPE string;
DEFINE FIELD type                 ON lg_checkpoint_writes TYPE string;
DEFINE FIELD blob                 ON lg_checkpoint_writes TYPE string;
DEFINE FIELD created_at           ON lg_checkpoint_writes TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_lg_writes_ckpt   ON lg_checkpoint_writes FIELDS thread_id, checkpoint_id, task_id, idx UNIQUE;

-- ── W3C PROV-DM Provenance Model ─────────────────────────────────────────────
-- Source: W3C PROV Data Model (PROV-DM) — https://www.w3.org/TR/prov-dm/
-- Core types: Entity, Activity, Agent
-- Core relations: wasGeneratedBy, wasDerivedFrom, wasAttributedTo,
--                 wasAssociatedWith, used, actedOnBehalfOf
-- RealGraph maps: artifact → Entity, objective_run → Activity, agent → Agent
DEFINE TABLE prov_entities SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD entity_id            ON prov_entities TYPE string;    -- artifact_id or external URI
DEFINE FIELD entity_type          ON prov_entities TYPE string;    -- "artifact" | "source" | "dataset"
DEFINE FIELD label                ON prov_entities TYPE option<string>;
DEFINE FIELD location             ON prov_entities TYPE option<string>;  -- source_ref / URI
DEFINE FIELD value                ON prov_entities FLEXIBLE TYPE option<object>;
DEFINE FIELD generated_at_time    ON prov_entities TYPE option<datetime>;
DEFINE FIELD invalidated_at_time  ON prov_entities TYPE option<datetime>;
DEFINE FIELD attributes           ON prov_entities FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD recorded_at          ON prov_entities TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_prov_entity_id   ON prov_entities FIELDS entity_id UNIQUE;

DEFINE TABLE prov_activities SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD activity_id          ON prov_activities TYPE string;  -- objective_run_id or agent task_id
DEFINE FIELD activity_type        ON prov_activities TYPE string;
DEFINE FIELD label                ON prov_activities TYPE option<string>;
DEFINE FIELD started_at_time      ON prov_activities TYPE option<datetime>;
DEFINE FIELD ended_at_time        ON prov_activities TYPE option<datetime>;
DEFINE FIELD attributes           ON prov_activities FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD recorded_at          ON prov_activities TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_prov_activity_id ON prov_activities FIELDS activity_id UNIQUE;

DEFINE TABLE prov_agents SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD agent_id             ON prov_agents TYPE string;  -- agent record id
DEFINE FIELD agent_type           ON prov_agents TYPE string;  -- "SoftwareAgent" | "Person" | "Organization"
DEFINE FIELD label                ON prov_agents TYPE option<string>;
DEFINE FIELD attributes           ON prov_agents FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD recorded_at          ON prov_agents TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_prov_agent_id    ON prov_agents FIELDS agent_id UNIQUE;

-- PROV-DM relations as graph edges
DEFINE TABLE prov_was_generated_by SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD entity_id            ON prov_was_generated_by TYPE string;
DEFINE FIELD activity_id          ON prov_was_generated_by TYPE string;
DEFINE FIELD agent_id             ON prov_was_generated_by TYPE option<string>;
DEFINE FIELD generated_at_time    ON prov_was_generated_by TYPE option<datetime>;
DEFINE FIELD role                 ON prov_was_generated_by TYPE option<string>;
DEFINE INDEX idx_prov_wgb_entity  ON prov_was_generated_by FIELDS entity_id;

DEFINE TABLE prov_was_derived_from SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD generated_entity     ON prov_was_derived_from TYPE string;
DEFINE FIELD used_entity          ON prov_was_derived_from TYPE string;
DEFINE FIELD activity_id          ON prov_was_derived_from TYPE option<string>;
DEFINE FIELD generation_id        ON prov_was_derived_from TYPE option<string>;
DEFINE FIELD usage_id             ON prov_was_derived_from TYPE option<string>;
DEFINE INDEX idx_prov_wdf_gen     ON prov_was_derived_from FIELDS generated_entity;
DEFINE INDEX idx_prov_wdf_used    ON prov_was_derived_from FIELDS used_entity;

DEFINE TABLE prov_used SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD activity_id          ON prov_used TYPE string;
DEFINE FIELD entity_id            ON prov_used TYPE string;
DEFINE FIELD used_at_time         ON prov_used TYPE option<datetime>;
DEFINE FIELD role                 ON prov_used TYPE option<string>;
DEFINE FIELD attributes           ON prov_used FLEXIBLE TYPE object DEFAULT {};
DEFINE INDEX idx_prov_used_act    ON prov_used FIELDS activity_id;
DEFINE INDEX idx_prov_used_ent    ON prov_used FIELDS entity_id;

DEFINE TABLE prov_was_attributed_to SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD entity_id            ON prov_was_attributed_to TYPE string;
DEFINE FIELD agent_id             ON prov_was_attributed_to TYPE string;
DEFINE FIELD attributes           ON prov_was_attributed_to FLEXIBLE TYPE object DEFAULT {};
DEFINE INDEX idx_prov_attr_ent    ON prov_was_attributed_to FIELDS entity_id;
DEFINE INDEX idx_prov_attr_agent  ON prov_was_attributed_to FIELDS agent_id;

-- ── OpenTelemetry Trace Model ─────────────────────────────────────────────────
-- Source: OpenTelemetry Specification — https://opentelemetry.io/docs/specs/otel/
-- Supports: trace_id → span hierarchy, status codes, attributes, events, links.
-- Aligned with OTLP (OpenTelemetry Protocol) data model.
DEFINE TABLE otel_spans SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD trace_id             ON otel_spans TYPE string;
DEFINE FIELD span_id              ON otel_spans TYPE string;
DEFINE FIELD parent_span_id       ON otel_spans TYPE option<string>;
DEFINE FIELD trace_state          ON otel_spans TYPE option<string>;
DEFINE FIELD name                 ON otel_spans TYPE string;
DEFINE FIELD span_kind            ON otel_spans TYPE string DEFAULT 'INTERNAL';
  -- UNSPECIFIED | INTERNAL | SERVER | CLIENT | PRODUCER | CONSUMER
DEFINE FIELD start_time_unix_nano ON otel_spans TYPE int;
DEFINE FIELD end_time_unix_nano   ON otel_spans TYPE int;
DEFINE FIELD attributes           ON otel_spans FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD events               ON otel_spans FLEXIBLE TYPE array  DEFAULT [];
  -- [{ time_unix_nano, name, attributes }]
DEFINE FIELD links                ON otel_spans FLEXIBLE TYPE array  DEFAULT [];
  -- [{ trace_id, span_id, trace_state, attributes }]
DEFINE FIELD status_code          ON otel_spans TYPE string DEFAULT 'UNSET';
  -- UNSET | OK | ERROR
DEFINE FIELD status_message       ON otel_spans TYPE option<string>;
DEFINE FIELD dropped_attributes_count ON otel_spans TYPE int DEFAULT 0;
DEFINE FIELD dropped_events_count     ON otel_spans TYPE int DEFAULT 0;
DEFINE FIELD dropped_links_count      ON otel_spans TYPE int DEFAULT 0;
DEFINE FIELD resource_attributes  ON otel_spans FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD scope_name           ON otel_spans TYPE option<string>;
DEFINE FIELD scope_version        ON otel_spans TYPE option<string>;
DEFINE INDEX idx_otel_trace       ON otel_spans FIELDS trace_id;

-- ── Knowledge Bases ───────────────────────────────────────────────────────────
-- Customer-owned collections of chunked content (populated by the RAG layer).
-- One KB = one topical corpus. Artifact generation queries across selected KBs.
DEFINE TABLE knowledge_bases SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD name         ON knowledge_bases TYPE string;
DEFINE FIELD description  ON knowledge_bases TYPE string DEFAULT '';
DEFINE FIELD kb_type      ON knowledge_bases TYPE string DEFAULT 'general';
  -- general | technical | product | legal | marketing | research
DEFINE FIELD workspace_id ON knowledge_bases TYPE option<string>;
DEFINE FIELD chunk_count  ON knowledge_bases TYPE int DEFAULT 0;
DEFINE FIELD created_at   ON knowledge_bases TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at   ON knowledge_bases TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_kb_workspace ON knowledge_bases FIELDS workspace_id;
DEFINE INDEX idx_kb_name      ON knowledge_bases FIELDS name;

-- ── KB Chunks ─────────────────────────────────────────────────────────────────
-- Individual text units within a knowledge base.
-- embedding field holds float[] when vector search is available.
-- source_ref is the canonical citation URL or document identifier.
DEFINE TABLE kb_chunks SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD kb_id        ON kb_chunks TYPE string;
DEFINE FIELD content      ON kb_chunks TYPE string;
DEFINE FIELD embedding    ON kb_chunks FLEXIBLE TYPE option<array>;
DEFINE FIELD source_ref   ON kb_chunks TYPE option<string>;
DEFINE FIELD source_label ON kb_chunks TYPE option<string>;
DEFINE FIELD seq          ON kb_chunks TYPE int DEFAULT 0;
DEFINE FIELD modality     ON kb_chunks TYPE string DEFAULT 'text';
  -- text | image | table | math | figure
DEFINE FIELD raw_content  ON kb_chunks TYPE option<string>;
  -- base64 for images; original markdown for tables; LaTeX for math
DEFINE FIELD metadata     ON kb_chunks FLEXIBLE TYPE object DEFAULT {};
DEFINE FIELD created_at   ON kb_chunks TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_chunk_kb  ON kb_chunks FIELDS kb_id;
DEFINE INDEX idx_chunk_seq ON kb_chunks FIELDS kb_id, seq;

-- ── Artifact Generation Jobs ──────────────────────────────────────────────────
-- Tracks each generation request: KBs selected, chunks retrieved, model used.
DEFINE TABLE artifact_jobs SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD objective_id  ON artifact_jobs TYPE string;
DEFINE FIELD artifact_type ON artifact_jobs TYPE string;
DEFINE FIELD kb_ids        ON artifact_jobs FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD topic         ON artifact_jobs TYPE string;
DEFINE FIELD instructions  ON artifact_jobs TYPE option<string>;
DEFINE FIELD status        ON artifact_jobs TYPE string DEFAULT 'pending';
  -- pending | running | complete | failed
DEFINE FIELD artifact_id   ON artifact_jobs TYPE option<string>;
DEFINE FIELD chunks_used   ON artifact_jobs FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD model_used    ON artifact_jobs TYPE option<string>;
DEFINE FIELD error         ON artifact_jobs TYPE option<string>;
DEFINE FIELD created_at    ON artifact_jobs TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at  ON artifact_jobs TYPE option<datetime>;
DEFINE INDEX idx_job_objective ON artifact_jobs FIELDS objective_id;
DEFINE INDEX idx_job_status    ON artifact_jobs FIELDS status;

-- ── KB Entities (graph nodes) ─────────────────────────────────────────────────
-- Extracted from kb_chunks via LLM. Entity nodes in the knowledge graph.
-- Cross-modal: same entity can appear in text, table, and image chunks.
DEFINE TABLE kb_entities SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD kb_id        ON kb_entities TYPE string;
DEFINE FIELD name         ON kb_entities TYPE string;
DEFINE FIELD entity_type  ON kb_entities TYPE string DEFAULT 'concept';
  -- person | org | product | concept | event | location | other
DEFINE FIELD description  ON kb_entities TYPE option<string>;
DEFINE FIELD chunk_ids    ON kb_entities FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD mention_count ON kb_entities TYPE int DEFAULT 1;
DEFINE FIELD created_at   ON kb_entities TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at   ON kb_entities TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_entity_kb   ON kb_entities FIELDS kb_id;
DEFINE INDEX idx_entity_name ON kb_entities FIELDS kb_id, name UNIQUE;

-- ── KB Entity Relations (graph edges via RELATE) ──────────────────────────────
-- RELATE kb_entities:X -> kb_entity_relation -> kb_entities:Y
-- Native SurrealDB graph traversal: entity<->kb_entity_relation<->entity
DEFINE TABLE kb_entity_relation SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD kb_id        ON kb_entity_relation TYPE string;
DEFINE FIELD relation_type ON kb_entity_relation TYPE string;  -- "related_to" | "is_a" | "part_of" | ...
DEFINE FIELD description  ON kb_entity_relation TYPE option<string>;
DEFINE FIELD chunk_id     ON kb_entity_relation TYPE option<string>;
DEFINE FIELD weight       ON kb_entity_relation TYPE float DEFAULT 1.0;
DEFINE FIELD created_at   ON kb_entity_relation TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_rel_kb   ON kb_entity_relation FIELDS kb_id;

-- ── KB Communities ────────────────────────────────────────────────────────────
-- BFS-detected clusters of densely connected entities.
-- LLM generates a summary + title for each community (GraphRAG global search).
DEFINE TABLE kb_communities SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD kb_id         ON kb_communities TYPE string;
DEFINE FIELD community_idx ON kb_communities TYPE int;
DEFINE FIELD title         ON kb_communities TYPE option<string>;
DEFINE FIELD summary       ON kb_communities TYPE option<string>;
DEFINE FIELD entity_names  ON kb_communities FLEXIBLE TYPE array DEFAULT [];
DEFINE FIELD entity_count  ON kb_communities TYPE int DEFAULT 0;
DEFINE FIELD level         ON kb_communities TYPE int DEFAULT 0;
DEFINE FIELD created_at    ON kb_communities TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_community_kb ON kb_communities FIELDS kb_id;
DEFINE INDEX idx_otel_span        ON otel_spans FIELDS span_id UNIQUE;
DEFINE INDEX idx_otel_parent      ON otel_spans FIELDS parent_span_id;
DEFINE INDEX idx_otel_start       ON otel_spans FIELDS start_time_unix_nano;
