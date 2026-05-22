DEFINE FUNCTION fn::finish_observation_run($run_id, $status, $summary) {
  LET $run = SELECT * FROM $run_id;
  IF count($run) = 0 THEN { THROW 'observation_run_not_found'; };

  UPDATE $run_id SET
    status = $status,
    ended_at = time::now();

  CREATE audit_logs CONTENT {
    tenant_id: $run[0].tenant_id,
    actor_id: string::concat($run[0].agent_id),
    action: 'finish_observation_run',
    resource_type: 'observation_runs',
    resource_id: string::concat($run_id),
    metadata: { status: $status, summary: $summary },
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:AuditEvent'],
    time: { observed_at: time::now() },
    created_at: time::now()
  };

  RETURN SELECT * FROM $run_id;
};

DEFINE FUNCTION fn::link_observation_steps($previous_step_id, $next_step_id) {
  LET $previous = SELECT * FROM $previous_step_id;
  LET $next = SELECT * FROM $next_step_id;
  IF count($previous) = 0 OR count($next) = 0 THEN { THROW 'observation_step_not_found'; };
  IF $previous[0].tenant_id != $next[0].tenant_id THEN { THROW 'cross_tenant_step_link_rejected'; };
  IF $previous[0].run_id != $next[0].run_id THEN { THROW 'cross_run_step_link_rejected'; };

  UPDATE $next_step_id SET previous_step_id = $previous_step_id;
  UPDATE $previous_step_id SET output = object::extend(output, { next_step_id: $next_step_id });

  RETURN SELECT * FROM $next_step_id;
};

DEFINE FUNCTION fn::record_graph_traversal_step($run_id, $sequence, $start_node, $end_node, $predicates, $depth, $stop_reason, $nodes_considered, $nodes_excluded) {
  LET $run = SELECT * FROM $run_id;
  IF count($run) = 0 THEN { THROW 'observation_run_not_found'; };

  RETURN CREATE observation_steps CONTENT {
    tenant_id: $run[0].tenant_id,
    run_id: $run_id,
    agent_id: $run[0].agent_id,
    sequence: $sequence,
    step_kind: 'graph_traversal',
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:GraphTraversalStep'],
    input: {
      start_node: $start_node,
      end_node: $end_node,
      predicates: $predicates,
      depth: $depth
    },
    output: {
      stop_reason: $stop_reason,
      nodes_considered: $nodes_considered,
      nodes_excluded: $nodes_excluded
    },
    status: 'completed',
    started_at: time::now(),
    ended_at: time::now(),
    observed_at: time::now(),
    method_version: $run[0].method_version,
    graph_path: {
      start_node: $start_node,
      end_node: $end_node,
      predicates: $predicates,
      depth: $depth,
      stop_reason: $stop_reason
    },
    explanation: {
      summary: 'Recorded bounded graph traversal step.'
    }
  };
};

DEFINE FUNCTION fn::record_policy_decision_step($run_id, $sequence, $policy_key, $decision, $reason, $input) {
  LET $run = SELECT * FROM $run_id;
  IF count($run) = 0 THEN { THROW 'observation_run_not_found'; };

  RETURN CREATE observation_steps CONTENT {
    tenant_id: $run[0].tenant_id,
    run_id: $run_id,
    agent_id: $run[0].agent_id,
    sequence: $sequence,
    step_kind: 'policy_decision',
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:PolicyDecisionStep'],
    input: $input,
    output: { policy_key: $policy_key, decision: $decision, reason: $reason },
    status: 'completed',
    started_at: time::now(),
    ended_at: time::now(),
    observed_at: time::now(),
    method_version: $run[0].method_version,
    explanation: { policy_key: $policy_key, decision: $decision, reason: $reason }
  };
};

DEFINE FUNCTION fn::require_observable_steps($run_id, $minimum_steps) {
  LET $steps = SELECT * FROM observation_steps WHERE run_id = $run_id;
  IF count($steps) < $minimum_steps THEN { THROW 'insufficient_observable_steps'; };
  RETURN true;
};
