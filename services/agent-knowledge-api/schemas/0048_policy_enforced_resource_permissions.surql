-- AGenNext Platform
-- 0048: SurrealDB-native resource permission enforcement helpers
-- Purpose: attach explicit record/resource gates to high-value domain operations.

DEFINE TABLE resource_permission_enforcement_rules SCHEMAFULL;
DEFINE FIELD tenant_id ON resource_permission_enforcement_rules TYPE record<tenants>;
DEFINE FIELD table_name ON resource_permission_enforcement_rules TYPE string;
DEFINE FIELD action ON resource_permission_enforcement_rules TYPE string;
DEFINE FIELD required_permission ON resource_permission_enforcement_rules TYPE string;
DEFINE FIELD min_classification ON resource_permission_enforcement_rules TYPE option<string>;
DEFINE FIELD requires_explicit_grant ON resource_permission_enforcement_rules TYPE bool DEFAULT false;
DEFINE FIELD requires_relationship_check ON resource_permission_enforcement_rules TYPE bool DEFAULT false;
DEFINE FIELD requires_policy_check ON resource_permission_enforcement_rules TYPE bool DEFAULT false;
DEFINE FIELD active ON resource_permission_enforcement_rules TYPE bool DEFAULT true;
DEFINE FIELD created_at ON resource_permission_enforcement_rules TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::create_resource_permission_enforcement_rule(
  $tenant_id: record<tenants>,
  $table_name: string,
  $action: string,
  $required_permission: string,
  $min_classification: option<string>,
  $requires_explicit_grant: bool,
  $requires_relationship_check: bool,
  $requires_policy_check: bool
) {
  RETURN CREATE resource_permission_enforcement_rules CONTENT {
    tenant_id: $tenant_id,
    table_name: $table_name,
    action: $action,
    required_permission: $required_permission,
    min_classification: $min_classification,
    requires_explicit_grant: $requires_explicit_grant,
    requires_relationship_check: $requires_relationship_check,
    requires_policy_check: $requires_policy_check,
    active: true,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::require_resource_permission_enforced(
  $tenant_id: record<tenants>,
  $subject_id: string,
  $resource_ref: string,
  $table_name: string,
  $action: string,
  $actor_id: option<string>
) {
  LET $rules = SELECT * FROM resource_permission_enforcement_rules
    WHERE tenant_id = $tenant_id
      AND table_name = $table_name
      AND (action = $action OR action = '*')
      AND active = true;

  LET $rule_count = count($rules);

  IF $rule_count = 0 THEN {
    THROW 'resource_permission_rule_missing';
  };

  LET $access = fn::evaluate_resource_access(
    $tenant_id,
    $subject_id,
    $resource_ref,
    $action,
    {},
    $actor_id
  );

  IF $access.decision != 'allow' THEN {
    THROW 'resource_access_denied';
  };

  CREATE audit_logs CONTENT {
    tenant_id: $tenant_id,
    actor_id: $actor_id,
    action: 'resource.permission.enforced',
    resource_type: $table_name,
    resource_id: $resource_ref,
    metadata: {
      subject_id: $subject_id,
      action: $action,
      rule_count: $rule_count,
      access_decision: $access.id
    },
    observed_at: time::now()
  };

  RETURN {
    allowed: true,
    resource_ref: $resource_ref,
    table_name: $table_name,
    action: $action,
    access_decision: $access.id
  };
};

DEFINE FUNCTION fn::resource_secure_select_query_plan(
  $tenant_id: record<tenants>,
  $subject_id: string,
  $table_name: string,
  $action: string
) {
  LET $filter = fn::record_level_filter_for_subject($tenant_id, $subject_id, $table_name);

  RETURN {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    table_name: $table_name,
    action: $action,
    filter: $filter,
    requires_per_record_check: true,
    required_gate: 'fn::require_resource_permission_enforced'
  };
};

-- Default high-value enforcement rules. These are intentionally broad and can be overridden per tenant.
CREATE resource_permission_enforcement_rules:agents_read CONTENT {
  tenant_id: tenants:platform,
  table_name: 'agents',
  action: 'read',
  required_permission: 'agent:read',
  requires_explicit_grant: false,
  requires_relationship_check: true,
  requires_policy_check: true,
  active: true,
  created_at: time::now()
};

CREATE resource_permission_enforcement_rules:agents_execute CONTENT {
  tenant_id: tenants:platform,
  table_name: 'agents',
  action: 'execute',
  required_permission: 'agent:execute',
  requires_explicit_grant: false,
  requires_relationship_check: true,
  requires_policy_check: true,
  active: true,
  created_at: time::now()
};

CREATE resource_permission_enforcement_rules:knowledge_read CONTENT {
  tenant_id: tenants:platform,
  table_name: 'agent_knowledge_items',
  action: 'read',
  required_permission: 'knowledge:read',
  min_classification: 'internal',
  requires_explicit_grant: false,
  requires_relationship_check: true,
  requires_policy_check: true,
  active: true,
  created_at: time::now()
};

CREATE resource_permission_enforcement_rules:memory_read CONTENT {
  tenant_id: tenants:platform,
  table_name: 'memory_nodes',
  action: 'read',
  required_permission: 'memory:read',
  min_classification: 'internal',
  requires_explicit_grant: false,
  requires_relationship_check: true,
  requires_policy_check: true,
  active: true,
  created_at: time::now()
};

CREATE resource_permission_enforcement_rules:release_certify CONTENT {
  tenant_id: tenants:platform,
  table_name: 'release_candidates',
  action: 'certify',
  required_permission: 'release:certify',
  min_classification: 'confidential',
  requires_explicit_grant: true,
  requires_relationship_check: true,
  requires_policy_check: true,
  active: true,
  created_at: time::now()
};
