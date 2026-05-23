-- Schema: functions
-- DEFINE FUNCTION — reusable SurrealQL business logic.
-- Functions run inside the DB: no round-trips, no application-layer logic.
-- Ref: https://surrealdb.com/docs/surrealql/statements/define/function

-- ─── Trust / evaluation ──────────────────────────────────────────────────────

-- Compute CLEAR composite score from 5 dimension scores
DEFINE FUNCTION fn::clear_score(
    $correct: float,
    $logical: float,
    $evidence: float,
    $aligned: float,
    $readable: float
) {
    RETURN ($correct + $logical + $evidence + $aligned + $readable) / 5.0;
};

-- Check if an artifact has passed trust gate (score >= $MIN_TRUST_SCORE)
DEFINE FUNCTION fn::trust_gate_passed($artifact_id: record<artifact>) {
    LET $record = SELECT trust_score, eval_status FROM ONLY $artifact_id;
    RETURN $record.eval_status = 'passed' AND $record.trust_score >= $MIN_TRUST_SCORE;
};

-- ─── Billing ─────────────────────────────────────────────────────────────────

-- Total spend for a tenant in the current calendar month
DEFINE FUNCTION fn::spend_this_month($tenant_id: string) {
    LET $start = time::floor(time::now(), 1month);
    RETURN SELECT VALUE math::sum(cost_usd)
        FROM usage_record
        WHERE tenant_id = $tenant_id
          AND recorded_at >= $start;
};

-- Check if tenant is over budget (returns bool)
DEFINE FUNCTION fn::over_budget($tenant_id: string) {
    LET $spent = fn::spend_this_month($tenant_id)[0];
    LET $budget = SELECT VALUE limit_usd
        FROM budget
        WHERE tenant_id = $tenant_id AND active = true AND period = 'monthly'
        LIMIT 1;
    IF $budget IS NONE OR array::len($budget) = 0 {
        RETURN false;
    };
    RETURN $spent >= $budget[0];
};

-- ─── Agent ───────────────────────────────────────────────────────────────────

-- Compute an agent's health score based on recent activity
DEFINE FUNCTION fn::agent_health_score($agent_id: string) {
    LET $last_seen = SELECT VALUE last_seen_at
        FROM agent WHERE agent_id = $agent_id LIMIT 1;
    IF $last_seen IS NONE OR array::len($last_seen) = 0 {
        RETURN 0.0;
    };
    LET $minutes_since = duration::secs(time::now() - $last_seen[0]) / 60;
    -- Score decays: 1.0 at 0 min, 0.0 at 10 min
    RETURN math::max(0.0, 1.0 - ($minutes_since / 10.0));
};

-- Verify all required capabilities are set to true on an agent record
DEFINE FUNCTION fn::capabilities_valid($caps: object) {
    LET $required = $REQUIRED_CAPABILITIES;
    LET $missing = array::filter($required, |$c| { $caps[$c] != true });
    RETURN array::len($missing) = 0;
};

-- ─── Memory ──────────────────────────────────────────────────────────────────

-- Importance-weighted memory retrieval score (70% similarity + 30% importance)
DEFINE FUNCTION fn::memory_score($similarity: float, $importance: float) {
    RETURN ($similarity * 0.7) + ($importance * 0.3);
};

-- ─── Objectives ──────────────────────────────────────────────────────────────

-- Check if all tasks for an objective are terminal (completed/failed/skipped)
DEFINE FUNCTION fn::objective_complete($objective_id: record<objective>) {
    LET $pending = SELECT count() AS n FROM task
        WHERE objective_id = $objective_id
          AND status NOT IN ['completed', 'failed', 'skipped'];
    RETURN $pending[0].n = 0;
};

-- ─── Commerce ────────────────────────────────────────────────────────────────

-- Compute invoice total from line items (quantity × unit_price)
DEFINE FUNCTION fn::invoice_total($line_items: array) {
    RETURN math::sum(array::map($line_items, |$item| {
        $item.quantity * $item.unit_price
    }));
};
