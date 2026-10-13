-- ─────────────────────────────────────────────────────────────────────────
-- AGenNext Agent Platform — SurrealDB API schema
--
-- SurrealDB-first: tables, business logic (fn::…), and the HTTP API (DEFINE API)
-- all live here. No external backend service. The dashboard's /api/* calls are
-- served directly by SurrealDB at /api/<ns>/<db>/<path>. Requires SurrealDB 3.x.
-- ─────────────────────────────────────────────────────────────────────────

-- ===== Operational tables =====
DEFINE TABLE OVERWRITE objectives SCHEMALESS;
DEFINE TABLE OVERWRITE artifacts SCHEMALESS;
DEFINE TABLE OVERWRITE agents SCHEMALESS;
DEFINE TABLE OVERWRITE workflow_runs SCHEMALESS;
DEFINE TABLE OVERWRITE eval_results SCHEMALESS;
DEFINE TABLE OVERWRITE trust_scores SCHEMALESS;
DEFINE TABLE OVERWRITE usage_records SCHEMALESS;
DEFINE TABLE OVERWRITE routing_rules SCHEMALESS;

-- ===== Dashboard read-model tables =====
DEFINE TABLE OVERWRITE spaces SCHEMALESS;
DEFINE TABLE OVERWRITE channels SCHEMALESS;
DEFINE TABLE OVERWRITE milestones SCHEMALESS;
DEFINE TABLE OVERWRITE learning_paths SCHEMALESS;
DEFINE TABLE OVERWRITE agent_profiles SCHEMALESS;
DEFINE TABLE OVERWRITE model_routes SCHEMALESS;

-- ===== Business functions (SurrealQL-owned) =====
DEFINE FUNCTION OVERWRITE fn::objective::start($objective_id: string) -> object {
  LET $rec = UPDATE type::record("objectives", $objective_id) SET status = "running", updated_at = time::now() RETURN AFTER;
  RETURN $rec[0];
};

DEFINE FUNCTION OVERWRITE fn::eval::score($scores: object, $threshold: option<float>) -> object {
  LET $t = $threshold ?? 0.7;
  LET $c = (($scores.completeness ?? 0.0) * 0.2) + (($scores.logical ?? 0.0) * 0.2) + (($scores.evidence ?? 0.0) * 0.2) + (($scores.accuracy ?? 0.0) * 0.2) + (($scores.relevance ?? 0.0) * 0.2);
  LET $r = math::round($c * 10000) / 10000;
  RETURN { composite_score: $r, passed: $r >= $t, threshold: $t };
};
DEFINE FUNCTION OVERWRITE fn::eval::evaluate($input: object) -> object {
  LET $dims = $input.dimension_scores ?? {};
  LET $scored = fn::eval::score($dims, $input.threshold);
  LET $created = CREATE ONLY eval_results CONTENT { artifact_id: $input.artifact_id, composite_score: $scored.composite_score, passed: $scored.passed, threshold: $scored.threshold, dimension_scores: $dims, rationale: $input.rationale ?? "", evaluated_at: time::now() };
  UPDATE artifacts SET eval_status = IF $scored.passed THEN "passed" ELSE "failed" END WHERE id = type::record("artifacts", $input.artifact_id) OR id = $input.artifact_id;
  RETURN { result: $created, threshold: $scored.threshold };
};

DEFINE FUNCTION OVERWRITE fn::trust::score($evidence: array) -> object {
  LET $total = array::len($evidence);
  LET $density = math::min([$total / 5.0, 1.0]);
  LET $score = math::round($density * 10000) / 10000;
  RETURN { score: $score, verified: $score >= 0.65, threshold: 0.65 };
};
DEFINE FUNCTION OVERWRITE fn::trust::record($input: object) -> object {
  LET $evidence = $input.evidence_links ?? [];
  LET $scored = fn::trust::score($evidence);
  LET $created = CREATE ONLY trust_scores CONTENT { artifact_id: $input.artifact_id, score: $scored.score, verified: $scored.verified, provenance: $evidence, verification_method: "chain", computed_at: time::now() };
  UPDATE artifacts SET trust_status = IF $scored.verified THEN "verified" ELSE "unverified" END WHERE id = type::record("artifacts", $input.artifact_id) OR id = $input.artifact_id;
  RETURN $created;
};
DEFINE FUNCTION OVERWRITE fn::trust::gate($artifact_id: string, $threshold: option<float>) -> object {
  LET $t = $threshold ?? 0.65;
  LET $latest = (SELECT * FROM trust_scores WHERE artifact_id = $artifact_id ORDER BY computed_at DESC LIMIT 1)[0];
  RETURN IF $latest = NONE THEN { passed: false, score: NONE, verified: false, threshold: $t, reason: "no_trust_score" }
    ELSE { passed: $latest.score >= $t, score: $latest.score, verified: $latest.verified, threshold: $t } END;
};

DEFINE FUNCTION OVERWRITE fn::finops::daily_spend() -> float {
  LET $rows = SELECT math::sum(cost_usd) AS spent FROM usage_records WHERE recorded_at > time::now() - 1d GROUP ALL;
  RETURN <float>($rows[0].spent ?? 0.0);
};
DEFINE FUNCTION OVERWRITE fn::model_router::select($input: object) -> object {
  LET $rule = (SELECT * FROM routing_rules WHERE task_type = $input.task_type AND enabled = true LIMIT 1)[0];
  IF $rule = NONE {
    RETURN { model_id: "llama3", provider: "ollama", estimated_cost: 0.0, rationale: "fallback (no_rule)", rule_id: NONE };
  };
  -- Enforce the rule's daily budget: once the day's spend meets it, fall back
  -- to the free local model instead of routing more paid traffic.
  LET $daily_spend = fn::finops::daily_spend();
  LET $daily_budget = $rule.daily_budget ?? 10.0;
  IF $daily_spend >= $daily_budget {
    RETURN { model_id: "llama3", provider: "ollama", estimated_cost: 0.0, rationale: "fallback (daily_budget_exhausted)", rule_id: $rule.id };
  };
  -- Filter candidates to those within the caller's / rule's cost ceiling and
  -- pick the highest priority (lowest priority number).
  LET $max_cost = $input.max_cost_override ?? $rule.max_cost_per_call ?? 0.10;
  LET $candidates = array::sort(($rule.models ?? [])[WHERE (max_cost_per_call ?? 0.0) <= $max_cost], |$a, $b| $a.priority < $b.priority);
  LET $candidate = $candidates[0];
  RETURN IF $candidate = NONE THEN { model_id: "llama3", provider: "ollama", estimated_cost: 0.0, rationale: "fallback (no_candidate_within_cost)", rule_id: $rule.id }
    ELSE { model_id: $candidate.model_id, provider: $candidate.provider ?? $rule.preferred_provider ?? "ollama", estimated_cost: $candidate.max_cost_per_call ?? 0.0, rationale: string::concat("priority=", <string>($candidate.priority ?? 0)), rule_id: $rule.id } END;
};

-- ===== JSON response helper =====
DEFINE FUNCTION OVERWRITE fn::api::json($value: any) -> object {
  RETURN { status: 200, headers: { "content-type": "application/json", "access-control-allow-origin": "*" }, body: encoding::json::encode($value) };
};

-- ===== HTTP API (served at /api/<ns>/<db>/<path>) =====
DEFINE API OVERWRITE "/health" FOR get THEN {
  RETURN fn::api::json({ status: "ok", service: "agent-platform", version: "0.1.0", surrealdb: "up", env: "production" });
};

DEFINE API OVERWRITE "/objectives"
  FOR get THEN {
    LET $s = $request.query.status;
    LET $rows = IF $s THEN (SELECT * FROM objectives WHERE status = $s ORDER BY created_at DESC)
                ELSE (SELECT * FROM objectives ORDER BY created_at DESC) END;
    RETURN fn::api::json($rows);
  }
  FOR post THEN {
    LET $b = encoding::json::decode(<string>$request.body);
    LET $rec = CREATE ONLY objectives CONTENT { title: $b.title, objective_type: $b.objective_type ?? "generic", payload: $b.payload ?? {}, status: "pending", created_at: time::now(), updated_at: time::now() };
    RETURN fn::api::json($rec);
  };

DEFINE API OVERWRITE "/objectives/:id/run" FOR post THEN {
  LET $r = fn::objective::start($request.params.id);
  RETURN fn::api::json({ objective_id: $request.params.id, status: $r.status ?? "running" });
};

DEFINE API OVERWRITE "/artifacts" FOR get THEN {
  LET $o = $request.query.objective_id;
  LET $rows = IF $o THEN (SELECT * FROM artifacts WHERE objective_id = $o ORDER BY created_at DESC)
              ELSE (SELECT * FROM artifacts ORDER BY created_at DESC) END;
  RETURN fn::api::json($rows);
};
DEFINE API OVERWRITE "/artifacts/hub" FOR get THEN {
  RETURN fn::api::json(SELECT * FROM artifacts ORDER BY created_at DESC);
};

DEFINE API OVERWRITE "/agents"
  FOR post THEN {
    LET $b = encoding::json::decode(<string>$request.body);
    LET $rec = CREATE ONLY agents CONTENT { run_id: $b.run_id, agent_role: $b.agent_role, status: "idle", created_at: time::now() };
    RETURN fn::api::json($rec);
  };
DEFINE API OVERWRITE "/agents/roster" FOR get THEN {
  RETURN fn::api::json(SELECT * FROM agent_profiles ORDER BY role);
};
DEFINE API OVERWRITE "/agents/run/:run_id" FOR get THEN {
  RETURN fn::api::json(SELECT * FROM agents WHERE run_id = $request.params.run_id ORDER BY created_at);
};

DEFINE API OVERWRITE "/spaces" FOR get THEN { RETURN fn::api::json(SELECT * FROM spaces ORDER BY name); };
DEFINE API OVERWRITE "/channels" FOR get THEN { RETURN fn::api::json(SELECT * FROM channels ORDER BY name); };
DEFINE API OVERWRITE "/milestones" FOR get THEN { RETURN fn::api::json(SELECT * FROM milestones ORDER BY due_at); };
DEFINE API OVERWRITE "/learning/paths" FOR get THEN { RETURN fn::api::json(SELECT * FROM learning_paths ORDER BY title); };

DEFINE API OVERWRITE "/model-router/routes" FOR get THEN { RETURN fn::api::json(SELECT * FROM model_routes ORDER BY share DESC); };
DEFINE API OVERWRITE "/model-router/usage/summary" FOR get THEN {
  LET $agg = (SELECT math::sum(cost_usd) AS cost_usd, math::sum(input_tokens) AS input_tokens, math::sum(output_tokens) AS output_tokens, count() AS calls FROM usage_records GROUP ALL)[0];
  LET $calls = <int>($agg.calls ?? 0);
  LET $cost = <float>($agg.cost_usd ?? 0.0);
  RETURN fn::api::json({
    total_calls: $calls,
    total_input_tokens: <int>($agg.input_tokens ?? 0),
    total_output_tokens: <int>($agg.output_tokens ?? 0),
    total_cost_usd: $cost,
    avg_cost_usd: math::round((IF $calls > 0 THEN $cost / $calls ELSE 0.0 END) * 10000) / 10000
  });
};
DEFINE API OVERWRITE "/model-router/select" FOR post THEN {
  LET $b = encoding::json::decode(<string>$request.body);
  RETURN fn::api::json(fn::model_router::select($b));
};

DEFINE API OVERWRITE "/eval/evaluate" FOR post THEN {
  LET $b = encoding::json::decode(<string>$request.body);
  RETURN fn::api::json(fn::eval::evaluate($b));
};
DEFINE API OVERWRITE "/eval/artifacts/:artifact_id" FOR get THEN {
  -- The dashboard reads a single EvalResult (with dimension_scores), so return
  -- the latest evaluation as one normalized object, never an array.
  LET $latest = (SELECT * FROM eval_results WHERE artifact_id = $request.params.artifact_id ORDER BY evaluated_at DESC LIMIT 1)[0];
  RETURN fn::api::json(IF $latest = NONE
    THEN { artifact_id: $request.params.artifact_id, composite_score: 0.0, passed: false, threshold: 0.7, dimension_scores: {}, rationale: "no_evaluation" }
    ELSE { artifact_id: $latest.artifact_id, composite_score: $latest.composite_score, passed: $latest.passed, threshold: $latest.threshold ?? 0.7, dimension_scores: $latest.dimension_scores ?? {}, rationale: $latest.rationale ?? "" } END);
};

DEFINE API OVERWRITE "/trust/provenance" FOR post THEN {
  LET $b = encoding::json::decode(<string>$request.body);
  RETURN fn::api::json(fn::trust::record($b));
};
DEFINE API OVERWRITE "/trust/gate" FOR post THEN {
  LET $b = encoding::json::decode(<string>$request.body);
  RETURN fn::api::json(fn::trust::gate($b.artifact_id, $b.threshold));
};
DEFINE API OVERWRITE "/trust/artifacts/:artifact_id" FOR get THEN {
  -- The dashboard reads a single TrustScore (with evidence_count), so return the
  -- latest trust score as one normalized object, never an array.
  LET $latest = (SELECT * FROM trust_scores WHERE artifact_id = $request.params.artifact_id ORDER BY computed_at DESC LIMIT 1)[0];
  RETURN fn::api::json(IF $latest = NONE
    THEN { artifact_id: $request.params.artifact_id, score: 0.0, evidence_count: 0, passed: false }
    ELSE { artifact_id: $latest.artifact_id, score: $latest.score, evidence_count: array::len($latest.provenance ?? []), passed: $latest.verified ?? false } END);
};
