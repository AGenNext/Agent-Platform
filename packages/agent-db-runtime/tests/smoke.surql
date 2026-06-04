-- Agent DB Runtime smoke assertions
-- Applied with: surreal import <conn> tests/smoke.surql
-- Requires core schema + schema/seed.surql to be applied first.
-- Uses THROW so `surreal import` exits non-zero when a bootstrap record is missing.

LET $tenant = (SELECT count() AS count FROM entity WHERE id = entity:default_tenant GROUP ALL)[0].count ?? 0;
IF $tenant < 1 { THROW "smoke: default tenant entity missing"; };

LET $admin = (SELECT count() AS count FROM identity WHERE id = identity:system_admin GROUP ALL)[0].count ?? 0;
IF $admin < 1 { THROW "smoke: system admin identity missing"; };

LET $registry = (SELECT count() AS count FROM registry WHERE id = registry:default_agent_registry GROUP ALL)[0].count ?? 0;
IF $registry < 1 { THROW "smoke: default agent registry missing"; };

LET $policy = (SELECT count() AS count FROM governance_object WHERE id = governance_object:default_runtime_policy GROUP ALL)[0].count ?? 0;
IF $policy < 1 { THROW "smoke: default runtime policy missing"; };

RETURN "smoke ok: tenant, admin, registry, policy present";
