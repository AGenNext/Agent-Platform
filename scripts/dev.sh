#!/usr/bin/env bash
set -euo pipefail

docker compose up -d

echo "Local platform services started."
echo "SurrealDB: http://localhost:8000"
echo "MinIO API: http://localhost:9000"
echo "MinIO Console: http://localhost:9001"
