#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

if command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
  COMPOSE="podman compose"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  echo "Neither podman compose nor docker compose is available." >&2
  exit 1
fi

echo "Building images..."
$COMPOSE build

echo "Starting services..."
$COMPOSE up -d

echo ""
echo "Platform services started using: $COMPOSE"
echo ""
echo "  SurrealDB:            http://localhost:${SURREALDB_PORT:-8000}"
echo "  Agent Knowledge API:  http://localhost:${AGENT_KNOWLEDGE_PORT:-8001}"
echo "  Agent Knowledge docs: http://localhost:${AGENT_KNOWLEDGE_PORT:-8001}/docs"
echo "  Agent Dashboard:      http://localhost:${AGENT_DASHBOARD_PORT:-3000}"
echo "  MinIO API:            http://localhost:${MINIO_API_PORT:-9000}"
echo "  MinIO Console:        http://localhost:${MINIO_CONSOLE_PORT:-9001}"
echo ""
echo "Run ./scripts/test-platform.sh to verify all services are healthy."
