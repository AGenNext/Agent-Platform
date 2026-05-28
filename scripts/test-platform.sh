#!/usr/bin/env bash
set -euo pipefail

SURREALDB_PORT=${SURREALDB_PORT:-8000}
MINIO_API_PORT=${MINIO_API_PORT:-9000}
AGENT_KNOWLEDGE_PORT=${AGENT_KNOWLEDGE_PORT:-8001}
AGENT_DASHBOARD_PORT=${AGENT_DASHBOARD_PORT:-3000}

PASS=0
FAIL=0

check() {
  local name="$1"
  local url="$2"
  if curl -sf "$url" >/dev/null; then
    echo "  [ok]  $name — $url"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $name — $url"
    FAIL=$((FAIL + 1))
  fi
}

check_json_field() {
  local name="$1"
  local url="$2"
  local field="$3"
  if curl -sf "$url" | python3 -c "import json, sys; data=json.load(sys.stdin); assert data.get('${field}')"; then
    echo "  [ok]  $name — $url has ${field}"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $name — $url missing ${field}"
    FAIL=$((FAIL + 1))
  fi
}

echo "── Infrastructure ──────────────────────────────────────────────"
check "SurrealDB health"  "http://localhost:${SURREALDB_PORT}/health"
check "MinIO health"      "http://localhost:${MINIO_API_PORT}/minio/health/live"

echo "── Platform services ───────────────────────────────────────────"
check "Agent Knowledge health"    "http://localhost:${AGENT_KNOWLEDGE_PORT}/health"
check "Agent Knowledge root"      "http://localhost:${AGENT_KNOWLEDGE_PORT}/"
check "Agent Knowledge discovery" "http://localhost:${AGENT_KNOWLEDGE_PORT}/.well-known/agent-platform.json"
check_json_field "Agent Knowledge discovery contract" "http://localhost:${AGENT_KNOWLEDGE_PORT}/.well-known/agent-platform.json" "hosts"
check "Agent Dashboard health"    "http://localhost:${AGENT_DASHBOARD_PORT}/health"
check "Agent Dashboard discovery" "http://localhost:${AGENT_DASHBOARD_PORT}/.well-known/agent-platform.json"
check_json_field "Agent Dashboard discovery contract" "http://localhost:${AGENT_DASHBOARD_PORT}/.well-known/agent-platform.json" "endpoints"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "Some checks failed. Check logs with: docker compose logs"
  exit 1
fi

echo "All checks passed."
