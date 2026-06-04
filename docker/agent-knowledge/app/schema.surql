-- ─────────────────────────────────────────────────────────────────────────
-- AGenNext Agent Platform — SurrealDB Schema
-- Applied once on startup via startup.py
-- ─────────────────────────────────────────────────────────────────────────

-- ── Objectives ──────────────────────────────────────────────────────────────
DEFINE TABLE objectives SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD title            ON objectives TYPE string;
DEFINE FIELD objective_type   ON objectives TYPE string  DEFAULT 'generic';
DEFINE FIELD workspace_id     ON objectives TYPE option<string>;
DEFINE FIELD payload          ON objectives TYPE object DEFAULT {};
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
DEFINE FIELD payload       ON artifacts TYPE object DEFAULT {};
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
DEFINE FIELD payload        ON handoff TYPE object DEFAULT {};
DEFINE FIELD created_at     ON handoff TYPE datetime DEFAULT time::now();

-- ── Workflow runs ────────────────────────────────────────────────────────────
DEFINE TABLE workflow_runs SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD definition_id ON workflow_runs TYPE option<string>;
DEFINE FIELD objective_id  ON workflow_runs TYPE string;
DEFINE FIELD status        ON workflow_runs TYPE string DEFAULT 'running';
DEFINE FIELD state         ON workflow_runs TYPE object DEFAULT {};
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
DEFINE FIELD metadata      ON checkpoints TYPE object DEFAULT {};
DEFINE FIELD created_at    ON checkpoints TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_ckpt_run    ON checkpoints FIELDS run_id;
DEFINE INDEX idx_ckpt_thread ON checkpoints FIELDS thread_id, checkpoint_id UNIQUE;

-- ── Eval results ─────────────────────────────────────────────────────────────
DEFINE TABLE eval_results SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD artifact_id      ON eval_results TYPE string;
DEFINE FIELD rubric_id        ON eval_results TYPE option<string>;
DEFINE FIELD composite_score  ON eval_results TYPE float;
DEFINE FIELD dimension_scores ON eval_results TYPE array DEFAULT [];
DEFINE FIELD passed           ON eval_results TYPE bool;
DEFINE FIELD rationale        ON eval_results TYPE option<string>;
DEFINE FIELD evaluated_at     ON eval_results TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_eval_artifact ON eval_results FIELDS artifact_id;

-- ── Trust scores ─────────────────────────────────────────────────────────────
DEFINE TABLE trust_scores SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD artifact_id         ON trust_scores TYPE string;
DEFINE FIELD score               ON trust_scores TYPE float;
DEFINE FIELD verified            ON trust_scores TYPE bool DEFAULT false;
DEFINE FIELD provenance          ON trust_scores TYPE array DEFAULT [];
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
DEFINE FIELD models            ON routing_rules TYPE array DEFAULT [];
DEFINE FIELD max_cost_per_call ON routing_rules TYPE float DEFAULT 0.10;
DEFINE FIELD daily_budget      ON routing_rules TYPE float DEFAULT 10.0;
DEFINE FIELD enabled           ON routing_rules TYPE bool  DEFAULT true;
DEFINE INDEX idx_routing_task ON routing_rules FIELDS task_type UNIQUE;

-- ── Platform host discovery ────────────────────────────────────────────────
DEFINE TABLE platform_hosts SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD name       ON platform_hosts TYPE string;
DEFINE FIELD role       ON platform_hosts TYPE string;
DEFINE FIELD url        ON platform_hosts TYPE string;
DEFINE FIELD health     ON platform_hosts TYPE string;
DEFINE FIELD enabled    ON platform_hosts TYPE bool DEFAULT true;
DEFINE FIELD priority   ON platform_hosts TYPE int DEFAULT 100;
DEFINE FIELD metadata   ON platform_hosts TYPE object DEFAULT {};
DEFINE FIELD updated_at ON platform_hosts TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_platform_hosts_name ON platform_hosts FIELDS name UNIQUE;
DEFINE INDEX idx_platform_hosts_enabled_priority ON platform_hosts FIELDS enabled, priority;

UPSERT platform_hosts:agent_platform SET name = "agent-platform", role = "platform", url = "http://localhost:3000", health = "http://localhost:3000/.well-known/agent-platform.json", enabled = true, priority = 10, metadata = {};
UPSERT platform_hosts:agent_knowledge SET name = "agent-knowledge", role = "api", url = "http://localhost:8000/api/agent_platform/agent_platform", health = "http://localhost:8000/health", enabled = true, priority = 20, metadata = {};
UPSERT platform_hosts:agent_dashboard SET name = "agent-dashboard", role = "dashboard", url = "http://localhost:3000", health = "http://localhost:3000/health", enabled = true, priority = 30, metadata = {};
UPSERT platform_hosts:agent_site SET name = "agent-site", role = "site", url = "http://localhost:3001", health = "http://localhost:3001/health", enabled = true, priority = 40, metadata = {};

-- ── SurrealDB-owned platform APIs and business functions ───────────────────
DEFINE FUNCTION fn::platform::hosts() -> array { RETURN SELECT name, role, url, health, enabled, priority, metadata FROM platform_hosts WHERE enabled = true ORDER BY priority; };
DEFINE FUNCTION fn::platform::manifest() -> object { LET $hosts = fn::platform::hosts(); LET $platform_url = $hosts[0].url; LET $knowledge_url = $hosts[WHERE name = "agent-knowledge"][0].url; RETURN { schema: "https://agennext.dev/schemas/well-known/agent-platform.v1.json", service: "agent-platform", display_name: "AGenNext Agent Platform", version: "0.1.0", environment: "dev", issuer: $platform_url, hosts: $hosts, capabilities: ["agent-orchestration", "source-to-artifact", "evaluation", "trust", "model-routing", "surrealdb-context-graph"], endpoints: { manifest: string::concat($platform_url, "/.well-known/agent-platform.json"), agent: string::concat($platform_url, "/.well-known/agent.json"), openapi: string::concat($knowledge_url, "/openapi.json"), health: string::concat($knowledge_url, "/health"), eval: string::concat($knowledge_url, "/eval/evaluate"), trust: string::concat($knowledge_url, "/trust/provenance"), model_router: string::concat($knowledge_url, "/model-router/select") }, evidence: { source: "SurrealDB platform_hosts registry", configured_by: ["platform_hosts"] } }; };
DEFINE FUNCTION fn::platform::agent_manifest() -> object { LET $manifest = fn::platform::manifest(); RETURN { name: $manifest.service, display_name: $manifest.display_name, description: "Customer-facing AGenNext platform host discovery for agent runtimes and clients.", version: $manifest.version, url: $manifest.issuer, preferred_manifest: $manifest.endpoints.manifest, hosts: $manifest.hosts, capabilities: $manifest.capabilities, endpoints: $manifest.endpoints }; };

DEFINE FUNCTION fn::objective::start($objective_id: string) -> object { LET $record = UPDATE type::thing("objectives", $objective_id) SET status = "running", updated_at = time::now() RETURN AFTER; RETURN $record[0]; };
DEFINE FUNCTION fn::artifact::create($input: object) -> object { RETURN CREATE ONLY artifacts CONTENT { objective_id: $input.objective_id, artifact_type: $input.artifact_type, title: $input.title, content_ref: $input.content_ref, payload: $input.payload ?? {}, status: "draft", created_at: time::now() }; };

DEFINE FUNCTION fn::eval::score($scores: object, $threshold: option<float>) -> object { LET $t = $threshold ?? 0.7; LET $composite = (($scores.completeness ?? 0.0) * 0.2) + (($scores.logical ?? 0.0) * 0.2) + (($scores.evidence ?? 0.0) * 0.2) + (($scores.accuracy ?? 0.0) * 0.2) + (($scores.relevance ?? 0.0) * 0.2); LET $rounded = math::round($composite * 10000) / 10000; RETURN { composite_score: $rounded, passed: $rounded >= $t, threshold: $t, dimension_scores: [{ dimension: "completeness", score: $scores.completeness ?? 0.0, weight: 0.2 }, { dimension: "logical", score: $scores.logical ?? 0.0, weight: 0.2 }, { dimension: "evidence", score: $scores.evidence ?? 0.0, weight: 0.2 }, { dimension: "accuracy", score: $scores.accuracy ?? 0.0, weight: 0.2 }, { dimension: "relevance", score: $scores.relevance ?? 0.0, weight: 0.2 }] }; };
DEFINE FUNCTION fn::eval::evaluate($input: object) -> object { LET $scored = fn::eval::score($input.dimension_scores ?? {}, $input.threshold); LET $created = CREATE ONLY eval_results CONTENT { artifact_id: $input.artifact_id, rubric_id: $input.rubric_id, composite_score: $scored.composite_score, dimension_scores: $scored.dimension_scores, passed: $scored.passed, rationale: $input.rationale, evaluated_at: time::now() }; UPDATE artifacts SET eval_status = IF $scored.passed THEN "passed" ELSE "failed" END WHERE id = type::thing("artifacts", $input.artifact_id) OR id = $input.artifact_id; RETURN { result: $created, threshold: $scored.threshold }; };

DEFINE FUNCTION fn::trust::score($evidence: array) -> object { LET $total = array::len($evidence); LET $complete = IF $total > 0 THEN array::len($evidence[WHERE source_ref != NONE AND source_ref != ""]) / $total ELSE 0 END; LET $diversity = IF $total > 0 THEN math::min([array::len(array::distinct($evidence.source_ref)) / $total, 1.0]) ELSE 0 END; LET $density = math::min([$total / 5.0, 1.0]); LET $score = math::round((($complete * 0.5) + ($diversity * 0.3) + ($density * 0.2)) * 10000) / 10000; RETURN { score: $score, verified: $score >= 0.65, threshold: 0.65 }; };
DEFINE FUNCTION fn::trust::record($input: object) -> object { LET $evidence = $input.evidence_links ?? []; LET $scored = fn::trust::score($evidence); LET $created = CREATE ONLY trust_scores CONTENT { artifact_id: $input.artifact_id, score: $scored.score, verified: $scored.verified, provenance: $evidence, verification_method: "chain", chain_hash: crypto::sha256(<string>$evidence), computed_at: time::now() }; UPDATE artifacts SET trust_status = IF $scored.verified THEN "verified" ELSE "unverified" END WHERE id = type::thing("artifacts", $input.artifact_id) OR id = $input.artifact_id; RETURN $created; };
DEFINE FUNCTION fn::trust::gate($artifact_id: string, $threshold: option<float>) -> object { LET $t = $threshold ?? 0.65; LET $latest = (SELECT * FROM trust_scores WHERE artifact_id = $artifact_id ORDER BY computed_at DESC LIMIT 1)[0]; RETURN IF $latest = NONE THEN { passed: false, score: NONE, verified: false, threshold: $t, reason: "no_trust_score" } ELSE { passed: $latest.score >= $t, score: $latest.score, verified: $latest.verified, threshold: $t, reason: IF $latest.score >= $t THEN "ok" ELSE "score_below_threshold" END } END; };

DEFINE FUNCTION fn::finops::daily_spend() -> float { LET $rows = SELECT math::sum(cost_usd) AS spent FROM usage_records WHERE recorded_at > time::now() - 1d GROUP ALL; RETURN <float>($rows[0].spent ?? 0.0); };
DEFINE FUNCTION fn::model_router::select($input: object) -> object { LET $rule = (SELECT * FROM routing_rules WHERE task_type = $input.task_type AND enabled = true LIMIT 1)[0]; RETURN IF $rule = NONE THEN { model_id: "llama3", provider: "ollama", estimated_cost: 0.0, rationale: "fallback (no_rule)", rule_id: NONE } ELSE { LET $daily_spend = fn::finops::daily_spend(); LET $daily_budget = $rule.daily_budget ?? 10.0; RETURN IF $daily_spend >= $daily_budget THEN { model_id: "llama3", provider: "ollama", estimated_cost: 0.0, rationale: "fallback (daily_budget_exhausted)", rule_id: $rule.id } ELSE { LET $max_cost = $input.max_cost_override ?? $rule.max_cost_per_call ?? 0.10; LET $candidates = $rule.models[WHERE max_cost_per_call <= $max_cost].sort((|$a, $b| $a.priority < $b.priority)); LET $candidate = $candidates[0]; RETURN IF $candidate = NONE THEN { model_id: "llama3", provider: "ollama", estimated_cost: 0.0, rationale: "fallback (no_candidate_within_cost)", rule_id: $rule.id } ELSE { model_id: $candidate.model_id, provider: $candidate.provider, estimated_cost: $candidate.max_cost_per_call ?? 0.0, rationale: string::concat("priority=", <string>($candidate.priority ?? 0)), rule_id: $rule.id } END } END } END; };

DEFINE API OVERWRITE "/.well-known/agent-platform.json" FOR get THEN { RETURN { status: 200, body: fn::platform::manifest(), headers: { "cache-control": "public, max-age=60, stale-while-revalidate=300" } }; } PERMISSIONS FULL;
DEFINE API OVERWRITE "/.well-known/agent.json" FOR get THEN { RETURN { status: 200, body: fn::platform::agent_manifest(), headers: { "cache-control": "public, max-age=60, stale-while-revalidate=300" } }; } PERMISSIONS FULL;
DEFINE API OVERWRITE "/eval/evaluate" FOR post THEN { RETURN { status: 200, body: fn::eval::evaluate($request.body) }; } PERMISSIONS FULL;
DEFINE API OVERWRITE "/trust/provenance" FOR post THEN { RETURN { status: 200, body: fn::trust::record($request.body) }; } PERMISSIONS FULL;
DEFINE API OVERWRITE "/trust/gate" FOR post THEN { RETURN { status: 200, body: fn::trust::gate($request.body.artifact_id, $request.body.threshold) }; } PERMISSIONS FULL;
DEFINE API OVERWRITE "/model-router/select" FOR post THEN { RETURN { status: 200, body: fn::model_router::select($request.body) }; } PERMISSIONS FULL;
