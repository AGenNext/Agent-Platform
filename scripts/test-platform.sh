#!/usr/bin/env bash
set -euo pipefail

curl -f http://localhost:8000/status >/dev/null
curl -f http://localhost:9000/minio/health/live >/dev/null

echo "Infrastructure smoke test passed."
