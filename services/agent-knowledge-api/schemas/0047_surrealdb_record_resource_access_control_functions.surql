DEFINE TABLE resource_access_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON resource_access_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON resource_access_policies TYPE string;
DEFINE FIELD name ON resource_access_policies TYPE string;
DEFINE FIELD table_name ON resource_access_policies TYPE string;
DEFINE FIELD resource_kind ON resource_access_policies TYPE string DEFAULT 'record';
DEFINE FIELD action ON resource_access_policies TYPE string;
DEFINE FIELD effect ON resource_access_policies TYPE string DEFAULT 'allow';
DEFINE FIELD principal_selector ON resource_access_policies TYPE object DEFAULT {};
DEFINE FIELD condition ON resource_access_policies TYPE object DEFAULT {};
DEFINE FIELD priority ON resource_access_policies TYPE int DEFAULT 100;
DEFINE FIELD enabled ON resource_access_policies TYPE bool DEFAULT true;
DEFINE FIELD created_at ON resource_access_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX resource_access_policies_key_unique ON resource_access_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE resource_access_grants SCHEMAFULL;
DEFINE FIELD tenant_id ON resource_access_grants TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON resource_access_grants TYPE string;
DEFINE FIELD resource_ref ON resource_access_grants TYPE record;
DEFINE FIELD resource_type ON resource_access_grants TYPE string;
DEFINE FIELD actions ON resource_access_grants TYPE array<string> DEFAULT [];
DEFINE FIELD relationship ON resource_access_grants TYPE option<string>;
DEFINE FIELD scope_kind ON resource_access_grants TYPE string DEFAULT 'record';
DEFINE FIELD scope_ref ON resource_access_grants TYPE option<record>;
DEFINE FIELD constraints ON resource_access_grants TYPE array<object> DEFAULT [];
DEFINE FIELD status ON resource_access_grants TYPE string DEFAULT 'active';
DEFINE FIELD granted_by ON resource_access_grants TYPE string;
DEFINE FIELD created_at ON resource_access_grants TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON resource_access_grants TYPE option<datetime>;
DEFINE INDEX resource_access_grants_unique ON resource_access_grants FIELDS tenant_id, subject_id, resource_ref, actions UNIQUE;

DEFINE TABLE resource_access_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON resource_access_decisions TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON resource_access_decisions TYPE string;
DEFINE FIELD resource_ref ON resource_access_decisions TYPE record;
DEFINE FIELD resource_type ON resource_access_decisions TYPE string;
DEFINE FIELD action ON resource_access_decisions TYPE string;
DEFINE FIELD allowed ON resource_access_decisions TYPE bool DEFAULT false;
DEFINE FIELD reason ON resource_access_decisions TYPE string;
DEFINE FIELD matched_policy_ids ON resource_access_decisions TYPE array<record<resource_access_policies>> DEFAULT [];
DEFINE FIELD matched_grant_ids ON resource_access_decisions TYPE array<record<resource_access_grants>> DEFAULT [];
DEFINE FIELD relationship_access_check_id ON resource_access_decisions TYPE option<record<relationship_access_checks>>;
DEFINE FIELD policy_decision_result_id ON resource_access_decisions TYPE option<record<policy_decision_results>>;
DEFINE FIELD decision_log_id ON resource_access_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON resource_access_decisions TYPE datetime DEFAULT time::now();

DEFINE TABLE resource_security_labels SCHEMAFULL;
DEFINE FIELD tenant_id ON resource_security_labels TYPE option<record<tenants>>;
DEFINE FIELD resource_ref ON resource_security_labels TYPE record;
DEFINE FIELD resource_type ON resource_security_labels TYPE string;
DEFINE FIELD classification ON resource_security_labels TYPE string DEFAULT 'internal';
DEFINE FIELD sensitivity ON resource_security_labels TYPE string DEFAULT 'medium';
DEFINE FIELD owner_id ON resource_security_labels TYPE string;
DEFINE FIELD data_domains ON resource_security_labels TYPE array<string> DEFAULT [];
DEFINE FIELD allowed_role_keys ON resource_security_labels TYPE array<string> DEFAULT [];
DEFINE FIELD denied_role_keys ON resource_security_labels TYPE array<string> DEFAULT [];
DEFINE FIELD require_explicit_grant ON resource_security_labels TYPE bool DEFAULT false;
DEFINE FIELD require_relationship_access ON resource_security_labels TYPE bool DEFAULT false;
DEFINE FIELD require_policy_allow ON resource_security_labels TYPE bool DEFAULT false;
DEFINE FIELD created_at ON resource_security_labels TYPE datetime DEFAULT time::now();
DEFINE INDEX resource_security_labels_unique ON resource_security_labels FIELDS tenant_id, resource_ref UNIQUE;

DEFINE FUNCTION fn::label_resource_security($tenant_id, $resource_ref, $resource_type, $classification, $sensitivity, $owner_id, $data_domains, $allowed_role_keys, $denied_role_keys, $require_explicit_grant, $require_relationship_access, $require_policy_allow) {
  RETURN CREATE resource_security_labels CONTENT { tenant_id: $tenant_id, resource_ref: $resource_ref, resource_type: $resource_type, classification: $classification, sensitivity: $sensitivity, owner_id: $owner_id, data_domains: $data_domains, allowed_role_keys: $allowed_role_keys, denied_role_keys: $denied_role_keys, require_explicit_grant: $require_explicit_grant, require_relationship_access: $require_relationship_access, require_policy_allow: $require_policy_allow, created_at: time::now() };
};

DEFINE FUNCTION fn::create_resource_access_policy($tenant_id, $key, $name, $table_name, $resource_kind, $action, $effect, $principal_selector, $condition, $priority) {
  RETURN CREATE resource_access_policies CONTENT { tenant_id: $tenant_id, key: $key, name: $name, table_name: $table_name, resource_kind: $resource_kind, action: $action, effect: $effect, principal_selector: $principal_selector, condition: $condition, priority: $priority, enabled: true, created_at: time::now() };
};

DEFINE FUNCTION fn::grant_resource_access($tenant_id, $subject_id, $resource_ref, $resource_type, $actions, $relationship, $scope_kind, $scope_ref, $constraints, $granted_by, $expires_at) {
  RETURN CREATE resource_access_grants CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, resource_ref: $resource_ref, resource_type: $resource_type, actions: $actions, relationship: $relationship, scope_kind: $scope_kind, scope_ref: $scope_ref, constraints: $constraints, status: 'active', granted_by: $granted_by, created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::revoke_resource_access($resource_access_grant_id, $actor_id, $reason) {
  LET $grant = SELECT * FROM $resource_access_grant_id;
  IF count($grant) = 0 THEN { THROW 'resource_access_grant_not_found'; };
  UPDATE $resource_access_grant_id SET status = 'revoked';
  CREATE audit_logs CONTENT { tenant_id: $grant[0].tenant_id, actor_id: $actor_id, action: 'resource_access_grant_revoked', resource_type: 'resource_access_grants', resource_id: string::concat($resource_access_grant_id), metadata: { reason: $reason }, semantic_id: rand::uuid(), jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:Action', 'agx:AuditEvent'], time: { observed_at: time::now() }, created_at: time::now() };
  RETURN SELECT * FROM $resource_access_grant_id;
};

DEFINE FUNCTION fn::evaluate_resource_access($tenant_id, $subject_id, $resource_ref, $resource_type, $action, $actor_id, $relationship_access_check_id, $policy_decision_result_id) {
  LET $label = SELECT * FROM resource_security_labels WHERE tenant_id = $tenant_id AND resource_ref = $resource_ref LIMIT 1;
  LET $profile = fn::get_user_experience_profile($tenant_id, $subject_id);
  LET $role_keys = $profile.roles[*].key;
  LET $grants = SELECT * FROM resource_access_grants WHERE tenant_id = $tenant_id AND subject_id = $subject_id AND resource_ref = $resource_ref AND status = 'active' AND $action INSIDE actions AND (expires_at = NONE OR expires_at > time::now());
  LET $policies = SELECT * FROM resource_access_policies WHERE (tenant_id = $tenant_id OR tenant_id = NONE) AND enabled = true AND table_name = $resource_type AND (action = $action OR action = '*') ORDER BY priority ASC;
  LET $deny_policy = SELECT * FROM $policies WHERE effect = 'deny' LIMIT 1;
  LET $allow_policy = SELECT * FROM $policies WHERE effect = 'allow' LIMIT 1;
  LET $role_denied = IF count($label) = 0 THEN false ELSE count(array::intersect($role_keys, $label[0].denied_role_keys)) > 0 END;
  LET $role_allowed = IF count($label) = 0 OR count($label[0].allowed_role_keys) = 0 THEN true ELSE count(array::intersect($role_keys, $label[0].allowed_role_keys)) > 0 END;
  LET $grant_allowed = count($grants) > 0;
  LET $relationship_allowed = IF count($label) = 0 OR !$label[0].require_relationship_access THEN true ELSE IF $relationship_access_check_id = NONE THEN false ELSE fn::require_relationship_access_allowed($relationship_access_check_id) END END;
  LET $policy_allowed = IF count($label) = 0 OR !$label[0].require_policy_allow THEN true ELSE IF $policy_decision_result_id = NONE THEN false ELSE fn::require_policy_allowed($policy_decision_result_id) END END;
  LET $explicit_required = IF count($label) = 0 THEN false ELSE $label[0].require_explicit_grant END;
  LET $allowed = count($deny_policy) = 0 AND !$role_denied AND $role_allowed AND $relationship_allowed AND $policy_allowed AND (IF $explicit_required THEN $grant_allowed ELSE ($grant_allowed OR count($allow_policy) > 0 OR $role_allowed) END);
  LET $reason = IF $allowed THEN 'resource_access_allowed' ELSE 'resource_access_denied_by_policy_label_grant_or_relationship' END;
  LET $decision_log = fn::log_decision_context($tenant_id, 'resource_record_access_decision', $subject_id, $actor_id, NONE, NONE, { resource_ref: $resource_ref, resource_type: $resource_type, action: $action }, {}, {}, {}, {}, {}, {}, { label: IF count($label) = 0 THEN NONE ELSE $label[0] END, role_keys: $role_keys, relationship_access_check_id: $relationship_access_check_id, policy_decision_result_id: $policy_decision_result_id }, [{ kind: 'record_level_access_control' }, { kind: 'resource_label_policy' }, { kind: 'explicit_grant_if_required' }], { role_denied: $role_denied, role_allowed: $role_allowed, grant_allowed: $grant_allowed, relationship_allowed: $relationship_allowed, policy_allowed: $policy_allowed, explicit_required: $explicit_required }, [{ decision: 'allow' }, { decision: 'deny' }], { decision: IF $allowed THEN 'allow' ELSE 'deny' END }, [], 'resource_record_access_evaluated', {}, array::concat($grants[*].id, $policies[*].id), NONE, [], false);
  RETURN CREATE resource_access_decisions CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, resource_ref: $resource_ref, resource_type: $resource_type, action: $action, allowed: $allowed, reason: $reason, matched_policy_ids: $policies[*].id, matched_grant_ids: $grants[*].id, relationship_access_check_id: $relationship_access_check_id, policy_decision_result_id: $policy_decision_result_id, decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::require_resource_access($tenant_id, $subject_id, $resource_ref, $resource_type, $action, $actor_id, $relationship_access_check_id, $policy_decision_result_id) {
  LET $decision = fn::evaluate_resource_access($tenant_id, $subject_id, $resource_ref, $resource_type, $action, $actor_id, $relationship_access_check_id, $policy_decision_result_id);
  IF !$decision.allowed THEN { THROW 'resource_record_access_denied'; };
  RETURN true;
};

DEFINE FUNCTION fn::record_level_filter_for_subject($tenant_id, $subject_id, $resource_type, $action) {
  LET $profile = fn::get_user_experience_profile($tenant_id, $subject_id);
  LET $grants = SELECT * FROM resource_access_grants WHERE tenant_id = $tenant_id AND subject_id = $subject_id AND resource_type = $resource_type AND status = 'active' AND $action INSIDE actions AND (expires_at = NONE OR expires_at > time::now());
  LET $labels = SELECT * FROM resource_security_labels WHERE tenant_id = $tenant_id AND resource_type = $resource_type;
  RETURN { subject_id: $subject_id, resource_type: $resource_type, action: $action, role_keys: $profile.roles[*].key, explicit_resource_refs: $grants[*].resource_ref, visible_unrestricted_resource_refs: (SELECT resource_ref FROM $labels WHERE require_explicit_grant = false AND count(array::intersect($profile.roles[*].key, denied_role_keys)) = 0 AND (count(allowed_role_keys) = 0 OR count(array::intersect($profile.roles[*].key, allowed_role_keys)) > 0))[*].resource_ref };
};

DEFINE FUNCTION fn::surrealdb_access_control_templates() {
  RETURN { note: 'Use these expressions inside DEFINE TABLE ... PERMISSIONS clauses where appropriate.', select_template: 'fn::require_resource_access($auth.tenant_id, $auth.subject_id, id, type::table($this), "select", $auth.subject_id, NONE, NONE)', create_template: 'fn::require_user_api_access($auth.tenant_id, $auth.subject_id, "record_create", type::table($this), "create", $auth.subject_id)', update_template: 'fn::require_resource_access($auth.tenant_id, $auth.subject_id, id, type::table($this), "update", $auth.subject_id, NONE, NONE)', delete_template: 'fn::require_resource_access($auth.tenant_id, $auth.subject_id, id, type::table($this), "delete", $auth.subject_id, NONE, NONE)' };
};
