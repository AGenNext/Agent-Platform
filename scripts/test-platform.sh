#!/usr/bin/env bash
set -euo pipefail

echo "Running platform smoke tests…"

# SurrealDB
curl -sf http://localhost:8000/status >/dev/null
echo "  ✓ SurrealDB"

# MinIO
curl -sf http://localhost:9000/minio/health/live >/dev/null
echo "  ✓ MinIO"

# Agent Knowledge API health
HEALTH=$(curl -sf http://localhost:8001/health)
echo "  ✓ Agent Knowledge API — $HEALTH"

# Run a test objective
RESULT=$(curl -sf -X POST http://localhost:8001/objectives/run \
  -H "Content-Type: application/json" \
  -d '{"goal": "smoke test objective", "priority": 1}')
STATUS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['objective']['status'])")
echo "  ✓ Objective run — status: $STATUS"

echo ""
echo "All platform smoke tests passed."
