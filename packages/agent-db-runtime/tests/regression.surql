-- Agent DB Runtime regression tests
-- Applied with: surreal import <conn> tests/regression.surql
-- Requires core schema + schema/seed.surql to be applied first.
-- Uses THROW so `surreal import` exits non-zero if any previously-fixed bug regresses.
--
-- Covers:
--   1. Seed idempotency (UPSERT-based bootstrap stays singleton).
--   2. Referential integrity of seeded record links.
--   3. ascii full-text analyzer + SEARCH index (regression: analyzer was undefined).
--   4. Handoff lifecycle + metadata merge (regression: object::extend did not exist,
--      and a bare object literal in UPDATE SET collapsed to {} ).

-- 1. Idempotency: bootstrap records are singletons.
LET $tenant = (SELECT count() AS count FROM entity WHERE id = entity:default_tenant GROUP ALL)[0].count ?? 0;
IF $tenant != 1 { THROW "regression: expected exactly 1 default tenant, found " + <string>$tenant; };

LET $admins = (SELECT count() AS count FROM identity WHERE id = identity:system_admin GROUP ALL)[0].count ?? 0;
IF $admins != 1 { THROW "regression: expected exactly 1 system admin identity, found " + <string>$admins; };

-- 1b. FLEXIBLE object persistence: SCHEMAFULL tables strip object keys unless the
-- field is declared FLEXIBLE. The seed writes metadata.bootstrap = true; assert it
-- survived the round-trip (regression: freeform object fields were not FLEXIBLE).
IF entity:default_tenant.metadata.bootstrap != true { THROW "regression: seed metadata.bootstrap not persisted (FLEXIBLE object field regression)"; };

-- 2. Referential integrity: seeded links resolve to real records.
IF identity:system_admin.entity = NONE { THROW "regression: system admin identity has no entity link"; };
LET $entity_ok = (SELECT count() AS count FROM entity WHERE id = identity:system_admin.entity GROUP ALL)[0].count ?? 0;
IF $entity_ok < 1 { THROW "regression: system admin entity link does not resolve"; };
IF registry:default_agent_registry.owner != identity:system_admin { THROW "regression: registry owner link incorrect"; };
IF governance_object:default_runtime_policy.owner != identity:system_admin { THROW "regression: policy owner link incorrect"; };

-- 3. ascii analyzer + SEARCH index must exist and match.
LET $search = (SELECT name FROM registry WHERE name @@ "registry");
IF array::len($search) < 1 { THROW "regression: ascii SEARCH index on registry returned no match"; };

-- 4. Handoff lifecycle + metadata merge.
LET $e1 = (CREATE entity CONTENT { entity_type: "agent", name: "Regression Source Agent", status: "active" })[0];
LET $e2 = (CREATE entity CONTENT { entity_type: "agent", name: "Regression Target Agent", status: "active" })[0];
LET $from = (CREATE identity CONTENT { entity: $e1.id, identity_type: "agent", subject: "regression:from" })[0];
LET $to = (CREATE identity CONTENT { entity: $e2.id, identity_type: "agent", subject: "regression:to" })[0];

LET $h = fn::request_handoff($e1.id, $from.id, $to.id, "task_handoff", NONE, NONE, {}, NONE);
LET $hid = $h[0].id;
IF $hid = NONE { THROW "regression: request_handoff returned no record"; };

fn::accept_handoff($hid, $to.id);
IF (SELECT VALUE status FROM $hid)[0] != "accepted" { THROW "regression: accept_handoff did not set status=accepted"; };
IF (SELECT VALUE metadata.accepted_by FROM $hid)[0] != $to.id { THROW "regression: accept_handoff did not record metadata.accepted_by"; };

fn::complete_handoff($hid, $to.id, NONE);
IF (SELECT VALUE status FROM $hid)[0] != "completed" { THROW "regression: complete_handoff did not set status=completed"; };
IF (SELECT VALUE metadata.completed_by FROM $hid)[0] != $to.id { THROW "regression: complete_handoff did not record metadata.completed_by"; };
-- the merge must preserve the earlier key, not overwrite the object
IF (SELECT VALUE metadata.accepted_by FROM $hid)[0] != $to.id { THROW "regression: complete_handoff overwrote metadata.accepted_by (object merge regression)"; };

-- Clean up the records created above so this test is side-effect-free and
-- re-runnable against the same database (identity.subject is uniquely indexed).
-- Delete in dependency order: handoff, then identities, then entities.
DELETE $hid;
DELETE $from.id;
DELETE $to.id;
DELETE $e1.id;
DELETE $e2.id;

RETURN "regression ok: idempotency, referential integrity, ascii search, handoff lifecycle + metadata merge";
