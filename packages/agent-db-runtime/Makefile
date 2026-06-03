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

.PHONY: up down restart logs ps apply seed smoke regression value-loop check clean

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

check: apply seed smoke regression

clean:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) down -v
