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

echo "── Infrastructure ──────────────────────────────────────────────"
check "SurrealDB health"  "http://localhost:${SURREALDB_PORT}/health"
check "MinIO health"      "http://localhost:${MINIO_API_PORT}/minio/health/live"

echo "── Platform services ───────────────────────────────────────────"
check "Agent Knowledge health"    "http://localhost:${AGENT_KNOWLEDGE_PORT}/health"
check "Agent Knowledge root"      "http://localhost:${AGENT_KNOWLEDGE_PORT}/"
check "Agent Dashboard health"    "http://localhost:${AGENT_DASHBOARD_PORT}/health"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "Some checks failed. Check logs with: docker compose logs"
  exit 1
fi

echo "All checks passed."
