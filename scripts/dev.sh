#!/usr/bin/env bash
set -euo pipefail

if command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
  COMPOSE="podman compose"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  echo "Neither podman compose nor docker compose is available." >&2
  exit 1
fi

$COMPOSE up -d

echo "Local platform services started using: $COMPOSE"
echo "SurrealDB: http://localhost:8000"
echo "Agent-Knowledge API: http://localhost:8001"
echo "MinIO API: http://localhost:9000"
echo "MinIO Console: http://localhost:9001"
