DEFINE TABLE service_level_objectives SCHEMAFULL;
DEFINE FIELD tenant_id ON service_level_objectives TYPE option<record<tenants>>;
DEFINE FIELD key ON service_level_objectives TYPE string;
DEFINE FIELD name ON service_level_objectives TYPE string;
DEFINE FIELD scope_kind ON service_level_objectives TYPE string DEFAULT 'platform';
DEFINE FIELD scope_ref ON service_level_objectives TYPE option<record>;
DEFINE FIELD sli_kind ON service_level_objectives TYPE string;
DEFINE FIELD target ON service_level_objectives TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD window_days ON service_level_objectives TYPE int DEFAULT 30;
DEFINE FIELD error_budget_policy ON service_level_objectives TYPE object DEFAULT { burn_rate_alert_threshold: 2, freeze_release_on_exhaustion: true };
DEFINE FIELD escalation_policy ON service_level_objectives TYPE object DEFAULT { severity: 'high', notify: [] };
DEFINE FIELD status ON service_level_objectives TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON service_level_objectives TYPE datetime DEFAULT time::now();
DEFINE INDEX service_level_objectives_key_unique ON service_level_objectives FIELDS tenant_id, key UNIQUE;

DEFINE TABLE service_level_indicators SCHEMAFULL;
DEFINE FIELD tenant_id ON service_level_indicators TYPE option<record<tenants>>;
DEFINE FIELD slo_id ON service_level_indicators TYPE record<service_level_objectives>;
DEFINE FIELD measurement_ref ON service_level_indicators TYPE string;
DEFINE FIELD numerator ON service_level_indicators TYPE number DEFAULT 0;
DEFINE FIELD denominator ON service_level_indicators TYPE number DEFAULT 0;
DEFINE FIELD value ON service_level_indicators TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD window_start ON service_level_indicators TYPE datetime;
DEFINE FIELD window_end ON service_level_indicators TYPE datetime;
DEFINE FIELD evidence_refs ON service_level_indicators TYPE array<record> DEFAULT [];
DEFINE FIELD created_at ON service_level_indicators TYPE datetime DEFAULT time::now();
DEFINE INDEX service_level_indicators_ref_unique ON service_level_indicators FIELDS tenant_id, measurement_ref UNIQUE;

DEFINE TABLE error_budget_snapshots SCHEMAFULL;
DEFINE FIELD tenant_id ON error_budget_snapshots TYPE option<record<tenants>>;
DEFINE FIELD slo_id ON error_budget_snapshots TYPE record<service_level_objectives>;
DEFINE FIELD sli_id ON error_budget_snapshots TYPE record<service_level_indicators>;
DEFINE FIELD budget_total ON error_budget_snapshots TYPE number DEFAULT 0;
DEFINE FIELD budget_consumed ON error_budget_snapshots TYPE number DEFAULT 0;
DEFINE FIELD budget_remaining ON error_budget_snapshots TYPE number DEFAULT 0;
DEFINE FIELD burn_rate ON error_budget_snapshots TYPE number DEFAULT 0;
DEFINE FIELD status ON error_budget_snapshots TYPE string DEFAULT 'healthy';
DEFINE FIELD created_at ON error_budget_snapshots TYPE datetime DEFAULT time::now();

DEFINE TABLE alert_rules SCHEMAFULL;
DEFINE FIELD tenant_id ON alert_rules TYPE option<record<tenants>>;
DEFINE FIELD key ON alert_rules TYPE string;
DEFINE FIELD name ON alert_rules TYPE string;
DEFINE FIELD condition_kind ON alert_rules TYPE string;
DEFINE FIELD threshold ON alert_rules TYPE number;
DEFINE FIELD severity ON alert_rules TYPE string DEFAULT 'medium';
DEFINE FIELD notification_targets ON alert_rules TYPE array<object> DEFAULT [];
DEFINE FIELD enabled ON alert_rules TYPE bool DEFAULT true;
DEFINE FIELD created_at ON alert_rules TYPE datetime DEFAULT time::now();
DEFINE INDEX alert_rules_key_unique ON alert_rules FIELDS tenant_id, key UNIQUE;

DEFINE TABLE alert_events SCHEMAFULL;
DEFINE FIELD tenant_id ON alert_events TYPE option<record<tenants>>;
DEFINE FIELD alert_ref ON alert_events TYPE string;
DEFINE FIELD alert_rule_id ON alert_events TYPE option<record<alert_rules>>;
DEFINE FIELD severity ON alert_events TYPE string;
DEFINE FIELD status ON alert_events TYPE string DEFAULT 'open';
DEFINE FIELD title ON alert_events TYPE string;
DEFINE FIELD description ON alert_events TYPE string;
DEFINE FIELD evidence_refs ON alert_events TYPE array<record> DEFAULT [];
DEFINE FIELD created_at ON alert_events TYPE datetime DEFAULT time::now();
DEFINE FIELD resolved_at ON alert_events TYPE option<datetime>;
DEFINE INDEX alert_events_ref_unique ON alert_events FIELDS tenant_id, alert_ref UNIQUE;

DEFINE TABLE incidents SCHEMAFULL;
DEFINE FIELD tenant_id ON incidents TYPE option<record<tenants>>;
DEFINE FIELD incident_ref ON incidents TYPE string;
DEFINE FIELD title ON incidents TYPE string;
DEFINE FIELD severity ON incidents TYPE string;
DEFINE FIELD status ON incidents TYPE string DEFAULT 'open';
DEFINE FIELD affected_scope_kind ON incidents TYPE string;
DEFINE FIELD affected_scope_ref ON incidents TYPE option<record>;
DEFINE FIELD alert_event_ids ON incidents TYPE array<record<alert_events>> DEFAULT [];
DEFINE FIELD trace_ids ON incidents TYPE array<string> DEFAULT [];
DEFINE FIELD debug_session_ids ON incidents TYPE array<record<debug_sessions>> DEFAULT [];
DEFINE FIELD owner_id ON incidents TYPE string;
DEFINE FIELD timeline ON incidents TYPE array<object> DEFAULT [];
DEFINE FIELD started_at ON incidents TYPE datetime DEFAULT time::now();
DEFINE FIELD resolved_at ON incidents TYPE option<datetime>;
DEFINE INDEX incidents_ref_unique ON incidents FIELDS tenant_id, incident_ref UNIQUE;

DEFINE TABLE postmortems SCHEMAFULL;
DEFINE FIELD tenant_id ON postmortems TYPE option<record<tenants>>;
DEFINE FIELD incident_id ON postmortems TYPE record<incidents>;
DEFINE FIELD summary ON postmortems TYPE string;
DEFINE FIELD root_causes ON postmortems TYPE array<object> DEFAULT [];
DEFINE FIELD corrective_actions ON postmortems TYPE array<object> DEFAULT [];
DEFINE FIELD prevention_actions ON postmortems TYPE array<object> DEFAULT [];
DEFINE FIELD human_approved_by ON postmortems TYPE option<string>;
DEFINE FIELD status ON postmortems TYPE string DEFAULT 'draft';
DEFINE FIELD created_at ON postmortems TYPE datetime DEFAULT time::now();
DEFINE FIELD approved_at ON postmortems TYPE option<datetime>;

UPSERT alert_rules:error_budget_burn CONTENT { tenant_id: NONE, key: 'error_budget_burn', name: 'Error Budget Burn Alert', condition_kind: 'burn_rate', threshold: 2, severity: 'high', notification_targets: [], enabled: true };

DEFINE FUNCTION fn::create_service_level_objective($tenant_id, $key, $name, $scope_kind, $scope_ref, $sli_kind, $target, $window_days, $error_budget_policy, $escalation_policy) {
  RETURN CREATE service_level_objectives CONTENT { tenant_id: $tenant_id, key: $key, name: $name, scope_kind: $scope_kind, scope_ref: $scope_ref, sli_kind: $sli_kind, target: $target, window_days: $window_days, error_budget_policy: $error_budget_policy, escalation_policy: $escalation_policy, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::record_service_level_indicator($tenant_id, $slo_id, $measurement_ref, $numerator, $denominator, $window_start, $window_end, $evidence_refs) {
  LET $slo = SELECT * FROM $slo_id;
  IF count($slo) = 0 THEN { THROW 'slo_not_found'; };
  LET $value = IF $denominator <= 0 THEN 0 ELSE fn::clamp01($numerator / $denominator) END;
  LET $sli = CREATE service_level_indicators CONTENT { tenant_id: $tenant_id, slo_id: $slo_id, measurement_ref: $measurement_ref, numerator: $numerator, denominator: $denominator, value: $value, window_start: $window_start, window_end: $window_end, evidence_refs: $evidence_refs, created_at: time::now() };
  RETURN fn::compute_error_budget($tenant_id, $slo_id, $sli.id);
};

DEFINE FUNCTION fn::compute_error_budget($tenant_id, $slo_id, $sli_id) {
  LET $slo = SELECT * FROM $slo_id;
  LET $sli = SELECT * FROM $sli_id;
  IF count($slo) = 0 OR count($sli) = 0 THEN { THROW 'slo_or_sli_not_found'; };
  LET $budget_total = 1 - $slo[0].target;
  LET $bad_rate = 1 - $sli[0].value;
  LET $consumed = IF $budget_total <= 0 THEN 1 ELSE fn::clamp01($bad_rate / $budget_total) END;
  LET $remaining = fn::clamp01(1 - $consumed);
  LET $burn = IF $budget_total <= 0 THEN 999 ELSE $bad_rate / $budget_total END;
  LET $status = IF $remaining <= 0 THEN 'exhausted' ELSE IF $burn >= $slo[0].error_budget_policy.burn_rate_alert_threshold THEN 'burning' ELSE 'healthy' END END;
  LET $snapshot = CREATE error_budget_snapshots CONTENT { tenant_id: $tenant_id, slo_id: $slo_id, sli_id: $sli_id, budget_total: $budget_total, budget_consumed: $consumed, budget_remaining: $remaining, burn_rate: $burn, status: $status, created_at: time::now() };
  IF $status IN ['burning', 'exhausted'] THEN { fn::create_alert_event($tenant_id, 'error_budget_burn', $slo[0].escalation_policy.severity ?? 'high', string::concat('SLO error budget ', $status), string::concat('SLO ', $slo[0].key, ' has error budget status ', $status), [$snapshot.id, $sli_id, $slo_id]); };
  RETURN $snapshot;
};

DEFINE FUNCTION fn::create_alert_event($tenant_id, $alert_rule_key, $severity, $title, $description, $evidence_refs) {
  LET $rule = SELECT * FROM alert_rules WHERE (tenant_id = $tenant_id OR tenant_id = NONE) AND key = $alert_rule_key AND enabled = true ORDER BY tenant_id DESC LIMIT 1;
  RETURN CREATE alert_events CONTENT { tenant_id: $tenant_id, alert_ref: rand::uuid(), alert_rule_id: IF count($rule) = 0 THEN NONE ELSE $rule[0].id END, severity: $severity, status: 'open', title: $title, description: $description, evidence_refs: $evidence_refs, created_at: time::now() };
};

DEFINE FUNCTION fn::open_incident($tenant_id, $incident_ref, $title, $severity, $affected_scope_kind, $affected_scope_ref, $alert_event_ids, $trace_ids, $debug_session_ids, $owner_id) {
  RETURN CREATE incidents CONTENT { tenant_id: $tenant_id, incident_ref: $incident_ref, title: $title, severity: $severity, status: 'open', affected_scope_kind: $affected_scope_kind, affected_scope_ref: $affected_scope_ref, alert_event_ids: $alert_event_ids, trace_ids: $trace_ids, debug_session_ids: $debug_session_ids, owner_id: $owner_id, timeline: [{ event: 'incident_opened', at: time::now(), actor_id: $owner_id }], started_at: time::now() };
};

DEFINE FUNCTION fn::resolve_incident($incident_id, $actor_id, $resolution) {
  LET $incident = SELECT * FROM $incident_id;
  IF count($incident) = 0 THEN { THROW 'incident_not_found'; };
  UPDATE $incident_id SET status = 'resolved', resolved_at = time::now(), timeline += { event: 'incident_resolved', at: time::now(), actor_id: $actor_id, resolution: $resolution };
  RETURN SELECT * FROM $incident_id;
};

DEFINE FUNCTION fn::create_postmortem($tenant_id, $incident_id, $summary, $root_causes, $corrective_actions, $prevention_actions) {
  LET $incident = SELECT * FROM $incident_id;
  IF count($incident) = 0 THEN { THROW 'incident_not_found'; };
  RETURN CREATE postmortems CONTENT { tenant_id: $tenant_id, incident_id: $incident_id, summary: $summary, root_causes: $root_causes, corrective_actions: $corrective_actions, prevention_actions: $prevention_actions, status: 'draft', created_at: time::now() };
};

DEFINE FUNCTION fn::approve_postmortem($postmortem_id, $human_actor_id) {
  LET $pm = SELECT * FROM $postmortem_id;
  IF count($pm) = 0 THEN { THROW 'postmortem_not_found'; };
  UPDATE $postmortem_id SET status = 'approved', human_approved_by = $human_actor_id, approved_at = time::now();
  RETURN SELECT * FROM $postmortem_id;
};

DEFINE FUNCTION fn::require_error_budget_healthy($slo_id) {
  LET $latest = SELECT * FROM error_budget_snapshots WHERE slo_id = $slo_id ORDER BY created_at DESC LIMIT 1;
  IF count($latest) = 0 THEN { THROW 'error_budget_snapshot_required'; };
  IF $latest[0].status != 'healthy' THEN { THROW 'error_budget_not_healthy'; };
  RETURN true;
};
