DEFINE TABLE telemetry_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON telemetry_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON telemetry_policies TYPE string;
DEFINE FIELD name ON telemetry_policies TYPE string;
DEFINE FIELD sampling_rate ON telemetry_policies TYPE number DEFAULT 1 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD trace_retention_days ON telemetry_policies TYPE int DEFAULT 30;
DEFINE FIELD metrics_retention_days ON telemetry_policies TYPE int DEFAULT 365;
DEFINE FIELD capture_payloads ON telemetry_policies TYPE bool DEFAULT false;
DEFINE FIELD redact_pii ON telemetry_policies TYPE bool DEFAULT true;
DEFINE FIELD enabled ON telemetry_policies TYPE bool DEFAULT true;
DEFINE FIELD created_at ON telemetry_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX telemetry_policies_key_unique ON telemetry_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE trace_sessions SCHEMAFULL;
DEFINE FIELD tenant_id ON trace_sessions TYPE option<record<tenants>>;
DEFINE FIELD trace_id ON trace_sessions TYPE string;
DEFINE FIELD subject_id ON trace_sessions TYPE string;
DEFINE FIELD agent_id ON trace_sessions TYPE option<record<agents>>;
DEFINE FIELD application_id ON trace_sessions TYPE option<record<applications>>;
DEFINE FIELD project_id ON trace_sessions TYPE option<record<projects>>;
DEFINE FIELD task_id ON trace_sessions TYPE option<record<tasks>>;
DEFINE FIELD parent_trace_id ON trace_sessions TYPE option<string>;
DEFINE FIELD status ON trace_sessions TYPE string DEFAULT 'running';
DEFINE FIELD started_at ON trace_sessions TYPE datetime DEFAULT time::now();
DEFINE FIELD ended_at ON trace_sessions TYPE option<datetime>;
DEFINE FIELD metadata ON trace_sessions TYPE object DEFAULT {};
DEFINE INDEX trace_sessions_trace_unique ON trace_sessions FIELDS tenant_id, trace_id UNIQUE;

DEFINE TABLE trace_spans SCHEMAFULL;
DEFINE FIELD tenant_id ON trace_spans TYPE option<record<tenants>>;
DEFINE FIELD trace_id ON trace_spans TYPE string;
DEFINE FIELD span_id ON trace_spans TYPE string;
DEFINE FIELD parent_span_id ON trace_spans TYPE option<string>;
DEFINE FIELD span_kind ON trace_spans TYPE string;
DEFINE FIELD name ON trace_spans TYPE string;
DEFINE FIELD status ON trace_spans TYPE string DEFAULT 'running';
DEFINE FIELD started_at ON trace_spans TYPE datetime DEFAULT time::now();
DEFINE FIELD ended_at ON trace_spans TYPE option<datetime>;
DEFINE FIELD duration_ms ON trace_spans TYPE option<number>;
DEFINE FIELD attributes ON trace_spans TYPE object DEFAULT {};
DEFINE FIELD events ON trace_spans TYPE array<object> DEFAULT [];
DEFINE FIELD error ON trace_spans TYPE option<object>;
DEFINE INDEX trace_spans_span_unique ON trace_spans FIELDS tenant_id, trace_id, span_id UNIQUE;

DEFINE TABLE usage_events SCHEMAFULL;
DEFINE FIELD tenant_id ON usage_events TYPE option<record<tenants>>;
DEFINE FIELD event_ref ON usage_events TYPE string;
DEFINE FIELD subject_id ON usage_events TYPE string;
DEFINE FIELD agent_id ON usage_events TYPE option<record<agents>>;
DEFINE FIELD application_id ON usage_events TYPE option<record<applications>>;
DEFINE FIELD event_kind ON usage_events TYPE string;
DEFINE FIELD feature_key ON usage_events TYPE string;
DEFINE FIELD units ON usage_events TYPE number DEFAULT 1;
DEFINE FIELD cost_minor ON usage_events TYPE int DEFAULT 0;
DEFINE FIELD currency ON usage_events TYPE string DEFAULT 'USD';
DEFINE FIELD trace_id ON usage_events TYPE option<string>;
DEFINE FIELD metadata ON usage_events TYPE object DEFAULT {};
DEFINE FIELD occurred_at ON usage_events TYPE datetime DEFAULT time::now();
DEFINE INDEX usage_events_ref_unique ON usage_events FIELDS tenant_id, event_ref UNIQUE;

DEFINE TABLE analytics_counters SCHEMAFULL;
DEFINE FIELD tenant_id ON analytics_counters TYPE option<record<tenants>>;
DEFINE FIELD metric_key ON analytics_counters TYPE string;
DEFINE FIELD dimensions ON analytics_counters TYPE object DEFAULT {};
DEFINE FIELD bucket_start ON analytics_counters TYPE datetime;
DEFINE FIELD bucket_granularity ON analytics_counters TYPE string DEFAULT 'day';
DEFINE FIELD count ON analytics_counters TYPE number DEFAULT 0;
DEFINE FIELD sum ON analytics_counters TYPE number DEFAULT 0;
DEFINE FIELD min ON analytics_counters TYPE option<number>;
DEFINE FIELD max ON analytics_counters TYPE option<number>;
DEFINE FIELD updated_at ON analytics_counters TYPE datetime DEFAULT time::now();

DEFINE TABLE health_checks SCHEMAFULL;
DEFINE FIELD tenant_id ON health_checks TYPE option<record<tenants>>;
DEFINE FIELD check_ref ON health_checks TYPE string;
DEFINE FIELD component ON health_checks TYPE string;
DEFINE FIELD status ON health_checks TYPE string;
DEFINE FIELD latency_ms ON health_checks TYPE option<number>;
DEFINE FIELD details ON health_checks TYPE object DEFAULT {};
DEFINE FIELD checked_at ON health_checks TYPE datetime DEFAULT time::now();
DEFINE INDEX health_checks_ref_unique ON health_checks FIELDS tenant_id, check_ref UNIQUE;

DEFINE TABLE adoption_snapshots SCHEMAFULL;
DEFINE FIELD tenant_id ON adoption_snapshots TYPE option<record<tenants>>;
DEFINE FIELD snapshot_ref ON adoption_snapshots TYPE string;
DEFINE FIELD scope_kind ON adoption_snapshots TYPE string;
DEFINE FIELD scope_ref ON adoption_snapshots TYPE option<record>;
DEFINE FIELD active_agents ON adoption_snapshots TYPE int DEFAULT 0;
DEFINE FIELD active_users ON adoption_snapshots TYPE int DEFAULT 0;
DEFINE FIELD active_applications ON adoption_snapshots TYPE int DEFAULT 0;
DEFINE FIELD total_tasks ON adoption_snapshots TYPE int DEFAULT 0;
DEFINE FIELD completed_tasks ON adoption_snapshots TYPE int DEFAULT 0;
DEFINE FIELD feature_usage ON adoption_snapshots TYPE object DEFAULT {};
DEFINE FIELD adoption_score ON adoption_snapshots TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD measured_at ON adoption_snapshots TYPE datetime DEFAULT time::now();
DEFINE INDEX adoption_snapshots_ref_unique ON adoption_snapshots FIELDS tenant_id, snapshot_ref UNIQUE;

DEFINE TABLE debug_sessions SCHEMAFULL;
DEFINE FIELD tenant_id ON debug_sessions TYPE option<record<tenants>>;
DEFINE FIELD debug_ref ON debug_sessions TYPE string;
DEFINE FIELD trace_id ON debug_sessions TYPE option<string>;
DEFINE FIELD subject_id ON debug_sessions TYPE string;
DEFINE FIELD issue_kind ON debug_sessions TYPE string;
DEFINE FIELD severity ON debug_sessions TYPE string DEFAULT 'medium';
DEFINE FIELD hypothesis ON debug_sessions TYPE string;
DEFINE FIELD evidence_ids ON debug_sessions TYPE array<record> DEFAULT [];
DEFINE FIELD reproduction_steps ON debug_sessions TYPE array<object> DEFAULT [];
DEFINE FIELD root_cause ON debug_sessions TYPE option<string>;
DEFINE FIELD resolution ON debug_sessions TYPE option<string>;
DEFINE FIELD status ON debug_sessions TYPE string DEFAULT 'open';
DEFINE FIELD created_at ON debug_sessions TYPE datetime DEFAULT time::now();
DEFINE FIELD closed_at ON debug_sessions TYPE option<datetime>;
DEFINE INDEX debug_sessions_ref_unique ON debug_sessions FIELDS tenant_id, debug_ref UNIQUE;

UPSERT telemetry_policies:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default Telemetry Policy', sampling_rate: 1, trace_retention_days: 30, metrics_retention_days: 365, capture_payloads: false, redact_pii: true, enabled: true };

DEFINE FUNCTION fn::start_trace_session($tenant_id, $trace_id, $subject_id, $agent_id, $application_id, $project_id, $task_id, $parent_trace_id, $metadata) {
  RETURN CREATE trace_sessions CONTENT { tenant_id: $tenant_id, trace_id: $trace_id, subject_id: $subject_id, agent_id: $agent_id, application_id: $application_id, project_id: $project_id, task_id: $task_id, parent_trace_id: $parent_trace_id, status: 'running', started_at: time::now(), metadata: $metadata };
};

DEFINE FUNCTION fn::finish_trace_session($tenant_id, $trace_id, $status, $metadata) {
  UPDATE trace_sessions SET status = $status, ended_at = time::now(), metadata += $metadata WHERE tenant_id = $tenant_id AND trace_id = $trace_id;
  RETURN SELECT * FROM trace_sessions WHERE tenant_id = $tenant_id AND trace_id = $trace_id LIMIT 1;
};

DEFINE FUNCTION fn::start_trace_span($tenant_id, $trace_id, $span_id, $parent_span_id, $span_kind, $name, $attributes) {
  RETURN CREATE trace_spans CONTENT { tenant_id: $tenant_id, trace_id: $trace_id, span_id: $span_id, parent_span_id: $parent_span_id, span_kind: $span_kind, name: $name, status: 'running', started_at: time::now(), attributes: $attributes, events: [] };
};

DEFINE FUNCTION fn::finish_trace_span($tenant_id, $trace_id, $span_id, $status, $attributes, $error) {
  LET $span = SELECT * FROM trace_spans WHERE tenant_id = $tenant_id AND trace_id = $trace_id AND span_id = $span_id LIMIT 1;
  IF count($span) = 0 THEN { THROW 'trace_span_not_found'; };
  LET $duration = time::unix(time::now()) - time::unix($span[0].started_at);
  UPDATE $span[0].id SET status = $status, ended_at = time::now(), duration_ms = $duration * 1000, attributes += $attributes, error = $error;
  RETURN SELECT * FROM $span[0].id;
};

DEFINE FUNCTION fn::add_trace_event($tenant_id, $trace_id, $span_id, $event_name, $attributes) {
  LET $span = SELECT * FROM trace_spans WHERE tenant_id = $tenant_id AND trace_id = $trace_id AND span_id = $span_id LIMIT 1;
  IF count($span) = 0 THEN { THROW 'trace_span_not_found'; };
  UPDATE $span[0].id SET events += { name: $event_name, attributes: $attributes, observed_at: time::now() };
  RETURN SELECT * FROM $span[0].id;
};

DEFINE FUNCTION fn::record_usage_event($tenant_id, $event_ref, $subject_id, $agent_id, $application_id, $event_kind, $feature_key, $units, $cost_minor, $currency, $trace_id, $metadata) {
  RETURN CREATE usage_events CONTENT { tenant_id: $tenant_id, event_ref: $event_ref, subject_id: $subject_id, agent_id: $agent_id, application_id: $application_id, event_kind: $event_kind, feature_key: $feature_key, units: $units, cost_minor: $cost_minor, currency: $currency, trace_id: $trace_id, metadata: $metadata, occurred_at: time::now() };
};

DEFINE FUNCTION fn::record_health_check($tenant_id, $check_ref, $component, $status, $latency_ms, $details) {
  RETURN CREATE health_checks CONTENT { tenant_id: $tenant_id, check_ref: $check_ref, component: $component, status: $status, latency_ms: $latency_ms, details: $details, checked_at: time::now() };
};

DEFINE FUNCTION fn::create_adoption_snapshot($tenant_id, $snapshot_ref, $scope_kind, $scope_ref) {
  LET $agents = SELECT * FROM agents WHERE tenant_id = $tenant_id;
  LET $apps = SELECT * FROM applications WHERE tenant_id = $tenant_id;
  LET $tasks = SELECT * FROM tasks WHERE tenant_id = $tenant_id;
  LET $completed = SELECT * FROM $tasks WHERE status IN ['done', 'completed'];
  LET $usage = SELECT * FROM usage_events WHERE tenant_id = $tenant_id;
  LET $score = fn::clamp01((math::min([count($agents), 10]) / 10 * 0.35) + (math::min([count($apps), 5]) / 5 * 0.25) + (IF count($tasks) = 0 THEN 0 ELSE count($completed) / count($tasks) END * 0.25) + (math::min([count($usage), 100]) / 100 * 0.15));
  RETURN CREATE adoption_snapshots CONTENT { tenant_id: $tenant_id, snapshot_ref: $snapshot_ref, scope_kind: $scope_kind, scope_ref: $scope_ref, active_agents: count($agents), active_users: count(array::distinct($usage[*].subject_id)), active_applications: count($apps), total_tasks: count($tasks), completed_tasks: count($completed), feature_usage: { event_count: count($usage), features: array::distinct($usage[*].feature_key) }, adoption_score: $score, measured_at: time::now() };
};

DEFINE FUNCTION fn::open_debug_session($tenant_id, $debug_ref, $trace_id, $subject_id, $issue_kind, $severity, $hypothesis, $evidence_ids, $reproduction_steps) {
  RETURN CREATE debug_sessions CONTENT { tenant_id: $tenant_id, debug_ref: $debug_ref, trace_id: $trace_id, subject_id: $subject_id, issue_kind: $issue_kind, severity: $severity, hypothesis: $hypothesis, evidence_ids: $evidence_ids, reproduction_steps: $reproduction_steps, status: 'open', created_at: time::now() };
};

DEFINE FUNCTION fn::close_debug_session($debug_session_id, $root_cause, $resolution) {
  LET $debug = SELECT * FROM $debug_session_id;
  IF count($debug) = 0 THEN { THROW 'debug_session_not_found'; };
  UPDATE $debug_session_id SET status = 'closed', root_cause = $root_cause, resolution = $resolution, closed_at = time::now();
  RETURN SELECT * FROM $debug_session_id;
};

DEFINE FUNCTION fn::get_trace_debug_bundle($tenant_id, $trace_id) {
  RETURN { trace: SELECT * FROM trace_sessions WHERE tenant_id = $tenant_id AND trace_id = $trace_id LIMIT 1, spans: SELECT * FROM trace_spans WHERE tenant_id = $tenant_id AND trace_id = $trace_id ORDER BY started_at ASC, usage: SELECT * FROM usage_events WHERE tenant_id = $tenant_id AND trace_id = $trace_id ORDER BY occurred_at ASC, debug: SELECT * FROM debug_sessions WHERE tenant_id = $tenant_id AND trace_id = $trace_id ORDER BY created_at DESC };
};
