-- Seed data for the AGenNext Agent Platform dashboard read models + demo runtime.
-- Idempotent (UPSERT by explicit record id). Loaded after schema.surql.

-- Spaces
UPSERT spaces:research SET name = "Research", owner = "ada", description = "Enterprise research workspace", status = "active", kind = "research", runs = 42, artifacts = 18, trust = 0.86, updated_at = time::now();
UPSERT spaces:generation SET name = "Generation", owner = "grace", description = "Source-to-artifact generation", status = "active", kind = "generation", runs = 31, artifacts = 27, trust = 0.79, updated_at = time::now();
UPSERT spaces:evaluation SET name = "Evaluation", owner = "linus", description = "Artifact evaluation & trust", status = "active", kind = "eval", runs = 12, artifacts = 4, trust = 0.91, updated_at = time::now();

-- Channels
UPSERT channels:planner SET name = "planner", kind = "agent", unread = 2, last_message = "Objective decomposed into 4 tasks", last_at = time::now(), active = true;
UPSERT channels:system SET name = "system", kind = "system", unread = 0, last_message = "Workflow run wf-1 completed", last_at = time::now(), active = true;
UPSERT channels:review SET name = "review", kind = "human", unread = 1, last_message = "Deck ready for approval", last_at = time::now(), active = false;

-- Milestones
UPSERT milestones:m1 SET name = "MVP launch", space = "Generation", status = "in_progress", progress = 0.6, due_at = time::now() + 14d, tasks_done = 9, tasks_total = 15, owner = "grace";
UPSERT milestones:m2 SET name = "Eval harness", space = "Evaluation", status = "planned", progress = 0.1, due_at = time::now() + 30d, tasks_done = 1, tasks_total = 10, owner = "linus";

-- Agent profiles (roster)
UPSERT agent_profiles:researcher SET role = "researcher", status = "active", model = "claude-sonnet", space = "Research", skills = ["search", "summarize", "cite"], current_task = "Survey competitor decks", runs = 14, trust = 0.88;
UPSERT agent_profiles:writer SET role = "writer", status = "idle", model = "claude-opus", space = "Generation", skills = ["draft", "format", "revise"], runs = 22, trust = 0.83;
UPSERT agent_profiles:evaluator SET role = "evaluator", status = "active", model = "claude-haiku", space = "Evaluation", skills = ["score", "gate"], current_task = "Score artifact art-1", runs = 40, trust = 0.94;

-- Model routes
UPSERT model_routes:r1 SET provider = "anthropic", model = "claude-sonnet", requests = 1280, cost_usd = 42.10, p95_ms = 900, error_rate = 0.004, share = 0.55, status = "healthy";
UPSERT model_routes:r2 SET provider = "anthropic", model = "claude-haiku", requests = 640, cost_usd = 6.40, p95_ms = 300, error_rate = 0.002, share = 0.28, status = "healthy";
UPSERT model_routes:r3 SET provider = "ollama", model = "llama3", requests = 390, cost_usd = 0.0, p95_ms = 1500, error_rate = 0.01, share = 0.17, status = "degraded";

-- Routing rules (used by fn::model_router::select)
UPSERT routing_rules:generic SET task_type = "generic", preferred_provider = "anthropic", models = [{ model_id: "claude-sonnet", provider: "anthropic", max_cost_per_call: 0.05, priority: 1 }], max_cost_per_call = 0.05, daily_budget = 25.0, enabled = true;

-- Learning paths
UPSERT learning_paths:foundations SET title = "Agent Platform Foundations", description = "Compose, run, and observe your first agent.", level = "Beginner", duration_min = 45, enrolled = 128, progress = 0.0, modules = [{ id: "intro", title: "What is a composable agent" }, { id: "run", title: "Run a workflow" }];
UPSERT learning_paths:governance SET title = "Governance Guardrails", description = "SurrealDB-first policy and trust gates.", level = "Intermediate", duration_min = 60, enrolled = 54, progress = 0.0, modules = [{ id: "policy", title: "Policy as data" }];

-- Demo objectives + artifacts + usage
UPSERT objectives:demo SET title = "Generate Q3 sales deck", objective_type = "deck", status = "pending", payload = {}, created_at = time::now(), updated_at = time::now();
UPSERT artifacts:art_1 SET objective_id = "demo", artifact_type = "deck", title = "Q3 Sales Deck v1", content_ref = "minio://agent-artifacts/art-1.pptx", status = "draft", created_at = time::now();
UPSERT usage_records:u1 SET objective_id = "demo", model_id = "claude-sonnet", provider = "anthropic", input_tokens = 4200, output_tokens = 1800, cost_usd = 0.09, recorded_at = time::now();
