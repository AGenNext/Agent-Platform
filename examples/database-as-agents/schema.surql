-- ============================================================
-- Database as Agents: SurrealDB Runtime Schema
-- ============================================================

DEFINE NAMESPACE agennext;
DEFINE DATABASE database_as_agents;

USE NS agennext DB database_as_agents;

DEFINE TABLE agent SCHEMAFULL;
DEFINE FIELD name ON agent TYPE string;
DEFINE FIELD role ON agent TYPE string;
DEFINE FIELD status ON agent TYPE string DEFAULT "active" ASSERT $value IN ["active", "suspended", "retired"];
DEFINE FIELD capabilities ON agent TYPE array<string> DEFAULT [];
DEFINE FIELD trust_score ON agent TYPE number DEFAULT 1.0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD created_at ON agent TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON agent TYPE datetime VALUE time::now();

DEFINE TABLE ticket SCHEMAFULL;
DEFINE FIELD title ON ticket TYPE string;
DEFINE FIELD description ON ticket TYPE string;
DEFINE FIELD priority ON ticket TYPE string ASSERT $value IN ["low", "medium", "high", "critical"];
DEFINE FIELD status ON ticket TYPE string DEFAULT "new" ASSERT $value IN ["new", "triage_pending", "needs_review", "in_progress", "resolved", "blocked"];
DEFINE FIELD assigned_agent ON ticket TYPE option<record<agent>>;
DEFINE FIELD risk_score ON ticket TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD created_at ON ticket TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON ticket TYPE datetime VALUE time::now();

DEFINE TABLE agent_task SCHEMAFULL;
DEFINE FIELD type ON agent_task TYPE string;
DEFINE FIELD status ON agent_task TYPE string DEFAULT "queued" ASSERT $value IN ["queued", "running", "blocked", "completed", "failed", "needs_human"];
DEFINE FIELD input ON agent_task TYPE object;
DEFINE FIELD output ON agent_task TYPE option<object>;
DEFINE FIELD agent ON agent_task TYPE record<agent>;
DEFINE FIELD source_record ON agent_task TYPE record;
DEFINE FIELD confidence ON agent_task TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD error ON agent_task TYPE option<string>;
DEFINE FIELD created_at ON agent_task TYPE datetime DEFAULT time::now();
DEFINE FIELD started_at ON agent_task TYPE option<datetime>;
DEFINE FIELD completed_at ON agent_task TYPE option<datetime>;
DEFINE FIELD updated_at ON agent_task TYPE datetime VALUE time::now();

DEFINE TABLE decision_log SCHEMAFULL;
DEFINE FIELD source_record ON decision_log TYPE record;
DEFINE FIELD decision_type ON decision_log TYPE string;
DEFINE FIELD reason ON decision_log TYPE string;
DEFINE FIELD result ON decision_log TYPE object;
DEFINE FIELD created_at ON decision_log TYPE datetime DEFAULT time::now();

DEFINE TABLE approval SCHEMAFULL;
DEFINE FIELD task ON approval TYPE record<agent_task>;
DEFINE FIELD status ON approval TYPE string DEFAULT "pending" ASSERT $value IN ["pending", "approved", "rejected"];
DEFINE FIELD requested_reason ON approval TYPE string;
DEFINE FIELD approved_by ON approval TYPE option<string>;
DEFINE FIELD created_at ON approval TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON approval TYPE datetime VALUE time::now();

DEFINE TABLE audit_log SCHEMAFULL;
DEFINE FIELD actor ON audit_log TYPE option<string>;
DEFINE FIELD action ON audit_log TYPE string;
DEFINE FIELD target ON audit_log TYPE record;
DEFINE FIELD before ON audit_log TYPE option<object>;
DEFINE FIELD after ON audit_log TYPE option<object>;
DEFINE FIELD created_at ON audit_log TYPE datetime DEFAULT time::now();

DEFINE TABLE skill SCHEMAFULL;
DEFINE FIELD name ON skill TYPE string;
DEFINE FIELD description ON skill TYPE option<string>;
DEFINE FIELD created_at ON skill TYPE datetime DEFAULT time::now();
DEFINE TABLE can_perform TYPE RELATION IN agent OUT skill;

DEFINE FUNCTION fn::ticket_risk($priority: string, $description: string) {
  LET $text = string::lowercase($description);
  IF $priority = "critical" { RETURN 0.95; };
  IF string::contains($text, "data breach") { RETURN 0.90; };
  IF string::contains($text, "leak") { RETURN 0.85; };
  IF string::contains($text, "payment") { RETURN 0.75; };
  IF $priority = "high" { RETURN 0.65; };
  IF $priority = "medium" { RETURN 0.45; };
  RETURN 0.25;
};

DEFINE FUNCTION fn::new_trust_score($old: number, $success: bool) {
  IF $success { RETURN math::min($old + 0.02, 1.0); };
  RETURN math::max($old - 0.10, 0.0);
};

DEFINE EVENT ticket_created ON TABLE ticket WHEN $event = "CREATE" THEN {
  LET $risk = fn::ticket_risk($after.priority, $after.description);
  UPDATE $after.id SET risk_score = $risk, status = IF $risk > 0.80 THEN "needs_review" ELSE "triage_pending" END;
  CREATE decision_log SET source_record = $after.id, decision_type = "ticket_risk_classification", reason = "Risk classified using deterministic database function", result = { risk_score: $risk, priority: $after.priority };
  IF $risk > 0.80 {
    CREATE agent_task SET type = "security_review", status = "queued", input = { ticket_id: $after.id, title: $after.title, description: $after.description, priority: $after.priority, risk_score: $risk }, agent = agent:security_reviewer, source_record = $after.id;
  } ELSE {
    CREATE agent_task SET type = "support_triage", status = "queued", input = { ticket_id: $after.id, title: $after.title, description: $after.description, priority: $after.priority, risk_score: $risk }, agent = agent:support_triage, source_record = $after.id;
  };
};

DEFINE EVENT low_confidence_task ON TABLE agent_task WHEN $event = "UPDATE" AND $after.status = "needs_human" THEN {
  CREATE approval SET task = $after.id, status = "pending", requested_reason = "Agent confidence below approval threshold";
  CREATE decision_log SET source_record = $after.id, decision_type = "human_approval_required", reason = "Agent confidence below approval threshold", result = { confidence: $after.confidence, task_status: $after.status };
};

DEFINE EVENT update_agent_trust ON TABLE agent_task WHEN $event = "UPDATE" AND $after.status IN ["completed", "failed", "needs_human"] THEN {
  LET $agent_record = SELECT * FROM ONLY $after.agent;
  LET $success = $after.status = "completed" AND $after.confidence != NONE AND $after.confidence >= 0.70;
  UPDATE $after.agent SET trust_score = fn::new_trust_score($agent_record.trust_score, $success);
  CREATE decision_log SET source_record = $after.agent, decision_type = "agent_trust_update", reason = "Trust score updated after task outcome", result = { task: $after.id, task_status: $after.status, confidence: $after.confidence, success: $success };
};

DEFINE EVENT audit_agent_task_update ON TABLE agent_task WHEN $event = "UPDATE" THEN {
  CREATE audit_log SET actor = "system", action = "agent_task_updated", target = $after.id, before = $before, after = $after;
};
