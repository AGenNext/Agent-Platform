# Local Development

## Quick Start

```bash
cp .env.example .env
./scripts/bootstrap.sh
./scripts/dev.sh
./scripts/test-platform.sh
```

## Services

- SurrealDB: http://localhost:8000
- MinIO API: http://localhost:9000
- MinIO Console: http://localhost:9001
- Ollama (optional): http://localhost:11434

## Well-Known Discovery

Agent-Platform publishes host discovery manifests for agent runtimes and clients:

- Dashboard origin: http://localhost:3000/.well-known/agent-platform.json
- API origin: http://localhost:8001/.well-known/agent-platform.json
- Agent compatibility manifest: http://localhost:3000/.well-known/agent.json

Set `PUBLIC_PLATFORM_URL`, `PUBLIC_AGENT_KNOWLEDGE_URL`, `PUBLIC_AGENT_DASHBOARD_URL`, and `PUBLIC_AGENT_SITE_URL` per environment so the manifest advertises the public hostnames.

At startup, these values seed the SurrealDB `platform_hosts` registry. The `.well-known` manifests read from that registry first and fall back to environment values if SurrealDB is temporarily unavailable.

## Goal

This milestone proves that the platform workspace boots locally and the core infrastructure is healthy.
