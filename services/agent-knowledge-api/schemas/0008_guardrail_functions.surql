DEFINE TABLE guardrail_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON guardrail_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON guardrail_policies TYPE string;
DEFINE FIELD name ON guardrail_policies TYPE string;
DEFINE FIELD policy_kind ON guardrail_policies TYPE string;
DEFINE FIELD enabled ON guardrail_policies TYPE bool DEFAULT true;
DEFINE FIELD risk_level ON guardrail_policies TYPE string DEFAULT 'medium';
DEFINE FIELD min_trust_score ON guardrail_policies TYPE number DEFAULT 0.70 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD require_human_approval ON guardrail_policies TYPE bool DEFAULT false;
DEFINE FIELD require_observable_steps ON guardrail_policies TYPE bool DEFAULT true;
DEFINE FIELD required_observable_steps ON guardrail_policies TYPE int DEFAULT 1;
DEFINE FIELD decision_on_fail ON guardrail_policies TYPE string DEFAULT 'reject';
DEFINE FIELD jsonld_context ON guardrail_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON guardrail_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:GuardrailPolicy'];
DEFINE FIELD created_at ON guardrail_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX guardrail_policies_key_unique ON guardrail_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE guardrail_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON guardrail_decisions TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON guardrail_decisions TYPE option<record<agents>>;
DEFINE FIELD policy_id ON guardrail_decisions TYPE record<guardrail_policies>;
DEFINE FIELD subject_id ON guardrail_decisions TYPE string;
DEFINE FIELD action_kind ON guardrail_decisions TYPE string;
DEFINE FIELD decision ON guardrail_decisions TYPE string;
DEFINE FIELD reason ON guardrail_decisions TYPE string;
DEFINE FIELD trust_score_id ON guardrail_decisions TYPE option<record<trust_scores>>;
DEFINE FIELD observation_run_id ON guardrail_decisions TYPE option<record<observation_runs>>;
DEFINE FIELD input ON guardrail_decisions TYPE object DEFAULT {};
DEFINE FIELD output ON guardrail_decisions TYPE object DEFAULT {};
DEFINE FIELD jsonld_context ON guardrail_decisions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON guardrail_decisions TYPE array<string> DEFAULT ['schema:Action', 'agx:GuardrailDecision'];
DEFINE FIELD created_at ON guardrail_decisions TYPE datetime DEFAULT time::now();

UPSERT guardrail_policies:default_low_risk CONTENT {
  tenant_id: NONE,
  key: 'default_low_risk',
  name: 'Default Low Risk Guardrail',
  policy_kind: 'trust_threshold',
  enabled: true,
  risk_level: 'low',
  min_trust_score: 0.70,
  require_human_approval: false,
  require_observable_steps: true,
  required_observable_steps: 1,
  decision_on_fail: 'reject'
};

UPSERT guardrail_policies:default_high_risk CONTENT {
  tenant_id: NONE,
  key: 'default_high_risk',
  name: 'Default High Risk Guardrail',
  policy_kind: 'trust_threshold',
  enabled: true,
  risk_level: 'high',
  min_trust_score: 0.90,
  require_human_approval: true,
  require_observable_steps: true,
  required_observable_steps: 3,
  decision_on_fail: 'require_human_approval'
};

DEFINE FUNCTION fn::select_guardrail_policy($tenant_id, $risk_level) {
  LET $tenant_policy = SELECT * FROM guardrail_policies WHERE tenant_id = $tenant_id AND risk_level = $risk_level AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };

  LET $global_policy = SELECT * FROM guardrail_policies WHERE tenant_id = NONE AND risk_level = $risk_level AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };

  RETURN guardrail_policies:default_low_risk;
};

DEFINE FUNCTION fn::verify_action_boundary($tenant_id, $agent_id, $subject_id, $action_kind, $risk_level, $scope, $observation_run_id, $input) {
  LET $policy = fn::select_guardrail_policy($tenant_id, $risk_level);
  LET $trust = fn::compute_trust_v1($tenant_id, $subject_id, string::concat($agent_id), $scope);

  IF $policy.require_observable_steps AND $observation_run_id != NONE THEN {
    fn::require_observable_steps($observation_run_id, $policy.required_observable_steps);
  };

  LET $passes_trust = $trust.score >= $policy.min_trust_score;
  LET $decision = IF $passes_trust THEN 'allow' ELSE $policy.decision_on_fail END;
  LET $reason = IF $passes_trust THEN 'trust_threshold_passed' ELSE 'trust_threshold_failed' END;

  LET $record = CREATE guardrail_decisions CONTENT {
    tenant_id: $tenant_id,
    agent_id: $agent_id,
    policy_id: $policy.id,
    subject_id: $subject_id,
    action_kind: $action_kind,
    decision: $decision,
    reason: $reason,
    trust_score_id: $trust.id,
    observation_run_id: $observation_run_id,
    input: $input,
    output: {
      min_trust_score: $policy.min_trust_score,
      trust_score: $trust.score,
      require_human_approval: $policy.require_human_approval
    },
    created_at: time::now()
  };

  IF $observation_run_id != NONE THEN {
    fn::record_policy_decision_step($observation_run_id, 800, $policy.key, $decision, $reason, $input);
  };

  CREATE audit_logs CONTENT {
    tenant_id: $tenant_id,
    actor_id: string::concat($agent_id),
    action: 'guardrail_decision',
    resource_type: 'guardrail_decisions',
    resource_id: string::concat($record.id),
    metadata: { decision: $decision, reason: $reason, action_kind: $action_kind, risk_level: $risk_level },
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:AuditEvent'],
    time: { observed_at: time::now() },
    created_at: time::now()
  };

  RETURN $record;
};

DEFINE FUNCTION fn::commit_if_allowed($guardrail_decision_id, $commit_table, $payload) {
  LET $decision = SELECT * FROM $guardrail_decision_id;
  IF count($decision) = 0 THEN { THROW 'guardrail_decision_not_found'; };
  IF $decision[0].decision != 'allow' THEN { THROW 'guardrail_rejected_commit'; };

  RETURN CREATE type::thing($commit_table, rand::uuid()) CONTENT $payload;
};

DEFINE FUNCTION fn::reject_signal($guardrail_decision_id) {
  LET $decision = SELECT * FROM $guardrail_decision_id;
  IF count($decision) = 0 THEN { THROW 'guardrail_decision_not_found'; };

  RETURN {
    rejected: $decision[0].decision != 'allow',
    decision: $decision[0].decision,
    reason: $decision[0].reason,
    output: $decision[0].output
  };
};
