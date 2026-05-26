#!/usr/bin/env bash
# Run the end-to-end test suite against a live Docker Compose stack.
#
# Usage:
#   ./scripts/run-e2e.sh [--keep-up] [extra pytest args...]
#
# Options:
#   --keep-up     Don't docker compose down after tests (useful during dev)
#
# Environment:
#   E2E_API_KEY   Set to a key from PLATFORM_API_KEYS to test auth enforcement.
#                 Leave empty when PLATFORM_API_KEYS is not set (dev mode).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

KEEP_UP=false
PYTEST_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--keep-up" ]]; then
    KEEP_UP=true
  else
    PYTEST_ARGS+=("$arg")
  fi
done

# ── Compose command detection ────────────────────────────────────────────────
if command -v docker &>/dev/null && docker compose version &>/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  echo "ERROR: docker compose or docker-compose not found." >&2
  exit 1
fi

# ── Start stack if not already running ───────────────────────────────────────
cd "$ROOT"
echo "==> Starting services..."
$COMPOSE up -d --build surrealdb minio minio-init agent-knowledge agent-dashboard

# ── Wait for agent-knowledge ─────────────────────────────────────────────────
echo "==> Waiting for agent-knowledge..."
for i in $(seq 1 30); do
  if curl -sf "http://localhost:${AGENT_KNOWLEDGE_PORT:-8001}/health" >/dev/null 2>&1; then
    echo "    agent-knowledge is up"
    break
  fi
  if [[ $i -eq 30 ]]; then
    echo "ERROR: agent-knowledge did not start in time." >&2
    $COMPOSE logs agent-knowledge | tail -30
    exit 1
  fi
  sleep 2
done

# ── Wait for agent-dashboard ─────────────────────────────────────────────────
echo "==> Waiting for agent-dashboard..."
for i in $(seq 1 20); do
  if curl -sf "http://localhost:${AGENT_DASHBOARD_PORT:-3000}/health" >/dev/null 2>&1; then
    echo "    agent-dashboard is up"
    break
  fi
  sleep 2
done

# ── Install e2e deps if needed ────────────────────────────────────────────────
if ! python -c "import httpx, pytest" 2>/dev/null; then
  echo "==> Installing e2e test dependencies..."
  pip install -q -r "${ROOT}/tests/e2e/requirements.txt"
fi

# ── Run tests ─────────────────────────────────────────────────────────────────
echo "==> Running e2e tests..."
cd "${ROOT}/tests/e2e"
python -m pytest . -v "${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"}"
E2E_EXIT=$?

# ── Tear down (unless --keep-up) ─────────────────────────────────────────────
if [[ "$KEEP_UP" == false ]]; then
  echo "==> Stopping services..."
  cd "$ROOT"
  $COMPOSE down
fi

exit $E2E_EXIT
