DEFINE TABLE users SCHEMAFULL;
DEFINE FIELD email ON users TYPE string;
DEFINE FIELD name ON users TYPE string;
DEFINE FIELD semantic_id ON users TYPE string;
DEFINE FIELD jsonld_context ON users TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON users TYPE array<string> DEFAULT ['schema:Person', 'agx:User'];
DEFINE FIELD active ON users TYPE bool DEFAULT true;
DEFINE FIELD created_at ON users TYPE datetime DEFAULT time::now();
DEFINE INDEX users_email_unique ON users FIELDS email UNIQUE;

DEFINE TABLE tenant_memberships SCHEMAFULL;
DEFINE FIELD tenant_id ON tenant_memberships TYPE record<tenants>;
DEFINE FIELD user_id ON tenant_memberships TYPE record<users>;
DEFINE FIELD status ON tenant_memberships TYPE string DEFAULT 'active';
DEFINE FIELD semantic_id ON tenant_memberships TYPE string;
DEFINE FIELD jsonld_context ON tenant_memberships TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON tenant_memberships TYPE array<string> DEFAULT ['schema:Role', 'agx:TenantMembership'];
DEFINE FIELD created_at ON tenant_memberships TYPE datetime DEFAULT time::now();
DEFINE INDEX tenant_memberships_unique ON tenant_memberships FIELDS tenant_id, user_id UNIQUE;

DEFINE TABLE roles SCHEMAFULL;
DEFINE FIELD tenant_id ON roles TYPE option<record<tenants>>;
DEFINE FIELD key ON roles TYPE string;
DEFINE FIELD name ON roles TYPE string;
DEFINE FIELD description ON roles TYPE string;
DEFINE FIELD jsonld_context ON roles TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON roles TYPE array<string> DEFAULT ['schema:Role', 'agx:Role'];
DEFINE FIELD created_at ON roles TYPE datetime DEFAULT time::now();
DEFINE INDEX roles_key_unique ON roles FIELDS tenant_id, key UNIQUE;

DEFINE TABLE permissions SCHEMAFULL;
DEFINE FIELD key ON permissions TYPE string;
DEFINE FIELD resource ON permissions TYPE string;
DEFINE FIELD action ON permissions TYPE string;
DEFINE FIELD description ON permissions TYPE string;
DEFINE FIELD jsonld_context ON permissions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON permissions TYPE array<string> DEFAULT ['schema:Action', 'agx:Permission'];
DEFINE FIELD created_at ON permissions TYPE datetime DEFAULT time::now();
DEFINE INDEX permissions_key_unique ON permissions FIELDS key UNIQUE;

DEFINE TABLE membership_roles SCHEMAFULL TYPE RELATION IN tenant_memberships OUT roles;
DEFINE FIELD tenant_id ON membership_roles TYPE record<tenants>;
DEFINE FIELD granted_by ON membership_roles TYPE option<string>;
DEFINE FIELD granted_at ON membership_roles TYPE datetime DEFAULT time::now();

DEFINE TABLE role_permissions SCHEMAFULL TYPE RELATION IN roles OUT permissions;
DEFINE FIELD tenant_id ON role_permissions TYPE option<record<tenants>>;
DEFINE FIELD effect ON role_permissions TYPE string DEFAULT 'allow';
DEFINE FIELD granted_at ON role_permissions TYPE datetime DEFAULT time::now();

UPSERT permissions:agent_create CONTENT { key: 'agent:create', resource: 'agent', action: 'create', description: 'Create agents' };
UPSERT permissions:agent_read CONTENT { key: 'agent:read', resource: 'agent', action: 'read', description: 'Read agents' };
UPSERT permissions:agent_execute CONTENT { key: 'agent:execute', resource: 'agent', action: 'execute', description: 'Execute agents' };
UPSERT permissions:schema_propose CONTENT { key: 'schema:propose', resource: 'schema', action: 'propose', description: 'Propose schema changes' };
UPSERT permissions:schema_vote CONTENT { key: 'schema:vote', resource: 'schema', action: 'vote', description: 'Vote on schema changes' };
UPSERT permissions:trust_compute CONTENT { key: 'trust:compute', resource: 'trust', action: 'compute', description: 'Compute trust' };

UPSERT roles:platform_admin CONTENT { tenant_id: NONE, key: 'platform_admin', name: 'Platform Admin', description: 'Platform-wide administrator' };
UPSERT roles:tenant_admin CONTENT { tenant_id: NONE, key: 'tenant_admin', name: 'Tenant Admin', description: 'Tenant administrator' };
UPSERT roles:agent_operator CONTENT { tenant_id: NONE, key: 'agent_operator', name: 'Agent Operator', description: 'Agent operator' };
UPSERT roles:ontology_steward CONTENT { tenant_id: NONE, key: 'ontology_steward', name: 'Ontology Steward', description: 'Ontology governance steward' };

RELATE roles:platform_admin->role_permissions->permissions:agent_create SET tenant_id = NONE, effect = 'allow';
RELATE roles:platform_admin->role_permissions->permissions:agent_read SET tenant_id = NONE, effect = 'allow';
RELATE roles:platform_admin->role_permissions->permissions:agent_execute SET tenant_id = NONE, effect = 'allow';
RELATE roles:platform_admin->role_permissions->permissions:schema_propose SET tenant_id = NONE, effect = 'allow';
RELATE roles:platform_admin->role_permissions->permissions:schema_vote SET tenant_id = NONE, effect = 'allow';
RELATE roles:platform_admin->role_permissions->permissions:trust_compute SET tenant_id = NONE, effect = 'allow';
RELATE roles:tenant_admin->role_permissions->permissions:agent_create SET tenant_id = NONE, effect = 'allow';
RELATE roles:tenant_admin->role_permissions->permissions:agent_read SET tenant_id = NONE, effect = 'allow';
RELATE roles:tenant_admin->role_permissions->permissions:agent_execute SET tenant_id = NONE, effect = 'allow';
RELATE roles:agent_operator->role_permissions->permissions:agent_read SET tenant_id = NONE, effect = 'allow';
RELATE roles:agent_operator->role_permissions->permissions:agent_execute SET tenant_id = NONE, effect = 'allow';
RELATE roles:ontology_steward->role_permissions->permissions:schema_propose SET tenant_id = NONE, effect = 'allow';
RELATE roles:ontology_steward->role_permissions->permissions:schema_vote SET tenant_id = NONE, effect = 'allow';

DEFINE FUNCTION fn::upsert_user($email, $name) {
  LET $existing = SELECT * FROM users WHERE email = $email LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE users CONTENT { email: $email, name: $name, semantic_id: string::concat('mailto:', $email), active: true, created_at: time::now() };
};

DEFINE FUNCTION fn::add_tenant_member($tenant_id, $user_id) {
  LET $tenant = SELECT * FROM $tenant_id;
  LET $user = SELECT * FROM $user_id;
  IF count($tenant) = 0 THEN { THROW 'tenant_not_found'; };
  IF count($user) = 0 THEN { THROW 'user_not_found'; };

  LET $existing = SELECT * FROM tenant_memberships WHERE tenant_id = $tenant_id AND user_id = $user_id LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };

  RETURN CREATE tenant_memberships CONTENT {
    tenant_id: $tenant_id,
    user_id: $user_id,
    status: 'active',
    semantic_id: rand::uuid(),
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::grant_role($tenant_id, $membership_id, $role_id, $granted_by) {
  LET $membership = SELECT * FROM $membership_id;
  LET $role = SELECT * FROM $role_id;
  IF count($membership) = 0 THEN { THROW 'membership_not_found'; };
  IF count($role) = 0 THEN { THROW 'role_not_found'; };
  IF $membership[0].tenant_id != $tenant_id THEN { THROW 'cross_tenant_role_grant_rejected'; };

  RETURN RELATE $membership_id->membership_roles->$role_id SET tenant_id = $tenant_id, granted_by = $granted_by, granted_at = time::now();
};

DEFINE FUNCTION fn::has_permission($tenant_id, $user_id, $permission_key) {
  LET $membership = SELECT * FROM tenant_memberships WHERE tenant_id = $tenant_id AND user_id = $user_id AND status = 'active' LIMIT 1;
  IF count($membership) = 0 THEN { RETURN false; };

  LET $matches = SELECT * FROM $membership[0].id->membership_roles->roles->role_permissions->permissions WHERE key = $permission_key;
  RETURN count($matches) > 0;
};

DEFINE FUNCTION fn::require_permission($tenant_id, $user_id, $permission_key) {
  LET $allowed = fn::has_permission($tenant_id, $user_id, $permission_key);
  IF !$allowed THEN { THROW 'permission_denied'; };
  RETURN true;
};
