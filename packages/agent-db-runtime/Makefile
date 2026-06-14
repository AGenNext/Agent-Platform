SHELL := /bin/sh

# Agent DB Runtime is SurrealDB-first: the only runtime tool is the SurrealDB
# CLI (`surreal`). No Node/npm/TypeScript tooling is used or permitted here.

COMPOSE_FILE ?= podman-compose.yml
PODMAN_COMPOSE ?= podman compose
SURREAL ?= surreal

SURREAL_ENDPOINT ?= http://127.0.0.1:8000
SURREAL_USER ?= root
SURREAL_PASS ?= root
SURREAL_NS ?= agennext
SURREAL_DB ?= agent_runtime

CONN := --endpoint $(SURREAL_ENDPOINT) --username $(SURREAL_USER) --password $(SURREAL_PASS) --namespace $(SURREAL_NS) --database $(SURREAL_DB)

LOAD_ORDER := schema/load-order.txt
BACKUP_FILE ?= backups/agent-runtime-backup.surql

.PHONY: up down restart logs ps apply seed smoke regression value-loop validate-value-loop backup restore-check check clean

up:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) up -d

down:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) down

restart: down up

logs:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) logs -f surrealdb

ps:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) ps

apply:
	@while read -r f; do \
		[ -z "$$f" ] && continue; \
		echo "apply $$f"; \
		$(SURREAL) import $(CONN) "$$f" || exit 1; \
	done < $(LOAD_ORDER)

seed:
	$(SURREAL) import $(CONN) schema/seed.surql

smoke:
	$(SURREAL) import $(CONN) tests/smoke.surql

regression:
	$(SURREAL) import $(CONN) tests/regression.surql

value-loop:
	$(SURREAL) import $(CONN) schema/design/runtime-meta-model.surql
	$(SURREAL) import $(CONN) schema/design/value-loop-phase1.surql
	$(SURREAL) import $(CONN) tests/value-loop-smoke.surql
	$(SURREAL) import $(CONN) tests/value-loop-asserts.surql

# Runtime validation gate for Phase 1 value-loop slice
# Expected behavior:
#   start/runtime connect -> apply base schema -> apply value-loop schema -> run smoke test -> query created records -> return non-zero on failure
validate-value-loop:
	@echo "=== Phase 1 Value Loop Runtime Validation ==="
	@echo "Starting SurrealDB in-memory instance..."
	$(SURREAL) start --user $(SURREAL_USER) --pass $(SURREAL_PASS) memory &
	@sleep 3
	@echo "Applying base runtime schema..."
	$(SURREAL) import $(CONN) schema/design/runtime-meta-model.surql || { echo "BASE_SCHEMA_MISSING: Failed to apply base runtime schema"; exit 1; }
	@echo "Applying value-loop phase 1 schema..."
	$(SURREAL) import $(CONN) schema/design/value-loop-phase1.surql || { echo "VALUE_LOOP_SCHEMA_APPLY_FAILURE: Failed to apply value-loop phase 1 schema"; exit 1; }
	@echo "Running value-loop smoke test..."
	$(SURREAL) import $(CONN) tests/value-loop-smoke.surql || { echo "SMOKE_TRANSACTION_FAILURE: Value-loop smoke test transaction failed"; exit 1; }
	@echo "Running value-loop assertions..."
	$(SURREAL) import $(CONN) tests/value-loop-asserts.surql || { echo "ASSERTION_FAILURE: Value-loop assertions failed"; exit 1; }
	@echo "Querying created records..."
	@echo "SELECT count() AS count FROM output;" | $(SURREAL) sql $(CONN) --json | grep -q '"count":' || { echo "QUERY_FAILURE: Failed to query output records"; exit 1; }
	@echo "SELECT count() AS count FROM outcome;" | $(SURREAL) sql $(CONN) --json | grep -q '"count":' || { echo "QUERY_FAILURE: Failed to query outcome records"; exit 1; }
	@echo "SELECT count() AS count FROM value_realization;" | $(SURREAL) sql $(CONN) --json | grep -q '"count":' || { echo "QUERY_FAILURE: Failed to query value_realization records"; exit 1; }
	@echo "SELECT count() AS count FROM learning;" | $(SURREAL) sql $(CONN) --json | grep -q '"count":' || { echo "QUERY_FAILURE: Failed to query learning records"; exit 1; }
	@echo "SELECT count() AS count FROM improvement;" | $(SURREAL) sql $(CONN) --json | grep -q '"count":' || { echo "QUERY_FAILURE: Failed to query improvement records"; exit 1; }
	@echo "=== Validation PASSED ==="
	@echo "All value-loop records created and queried successfully."

backup:
	@mkdir -p backups
	$(SURREAL) export $(CONN) $(BACKUP_FILE)
	@echo "backup written: $(BACKUP_FILE)"

# Disaster-recovery restore: schema from version control + data from the backup.
# Point CONN at a fresh database (e.g. SURREAL_DB=agent_runtime_dr) before running.
restore-check: apply
	@test -f $(BACKUP_FILE) || { echo "no backup at $(BACKUP_FILE); run 'make backup' first"; exit 1; }
	@mkdir -p backups
	@{ echo "OPTION IMPORT;"; grep -E '^(INSERT|RELATE)' $(BACKUP_FILE); } > backups/data-only.surql
	$(SURREAL) import $(CONN) backups/data-only.surql
	$(SURREAL) import $(CONN) tests/smoke.surql
	$(SURREAL) import $(CONN) tests/regression.surql

check: apply seed smoke regression

clean:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) down -v
