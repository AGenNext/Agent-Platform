SHELL := /bin/sh

COMPOSE_FILE ?= podman-compose.yml
NPM ?= npm
PODMAN_COMPOSE ?= podman compose

.PHONY: install up down restart logs ps validate apply seed smoke check clean

install:
	$(NPM) ci

up:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) up -d

down:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) down

restart: down up

logs:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) logs -f surrealdb

ps:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) ps

validate:
	$(NPM) run db:validate

apply:
	$(NPM) run db:apply

seed:
	$(NPM) run db:seed

smoke:
	$(NPM) run db:smoke

check: install validate apply seed smoke

clean:
	$(PODMAN_COMPOSE) -f $(COMPOSE_FILE) down -v
