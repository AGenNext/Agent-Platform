#!/usr/bin/env bash
set -euo pipefail

# Backup Agent-Platform data: SurrealDB export + MinIO mirror
# Usage: ./scripts/backup.sh [backup-dir]
#
# Requires: curl, mc (MinIO client) in PATH
# Env: SURREALDB_HOST, SURREALDB_PORT, SURREALDB_USERNAME, SURREALDB_PASSWORD,
#      MINIO_API_PORT, MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, BACKUP_DIR

BACKUP_DIR="${1:-${BACKUP_DIR:-./backups}}"
TIMESTAMP=$(date +%Y%m%dT%H%M%S)
DEST="${BACKUP_DIR}/${TIMESTAMP}"

SURREALDB_HOST="${SURREALDB_HOST:-localhost}"
SURREALDB_PORT="${SURREALDB_PORT:-8000}"
SURREALDB_USERNAME="${SURREALDB_USERNAME:-root}"
SURREALDB_PASSWORD="${SURREALDB_PASSWORD:-root}"
SURREALDB_NAMESPACE="${SURREALDB_NAMESPACE:-agent_platform}"
SURREALDB_DATABASE="${SURREALDB_DATABASE:-agent_platform}"

MINIO_API_PORT="${MINIO_API_PORT:-9000}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minio}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minio123}"

mkdir -p "${DEST}/surrealdb" "${DEST}/minio"

echo "── Backup: ${TIMESTAMP} ────────────────────────────────────────────"

# SurrealDB export via HTTP API
echo "  Exporting SurrealDB..."
curl -sf \
  -u "${SURREALDB_USERNAME}:${SURREALDB_PASSWORD}" \
  -H "Surreal-NS: ${SURREALDB_NAMESPACE}" \
  -H "Surreal-DB: ${SURREALDB_DATABASE}" \
  -H "Accept: application/octet-stream" \
  "http://${SURREALDB_HOST}:${SURREALDB_PORT}/export" \
  -o "${DEST}/surrealdb/platform.surql" \
  && echo "  [ok] SurrealDB → ${DEST}/surrealdb/platform.surql" \
  || echo "  [WARN] SurrealDB export failed (is the service running?)"

# MinIO mirror
echo "  Mirroring MinIO buckets..."
if command -v mc &>/dev/null; then
  mc alias set backup-src "http://${SURREALDB_HOST}:${MINIO_API_PORT}" \
    "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" --quiet 2>/dev/null || true
  for bucket in agent-artifacts agent-sources agent-traces; do
    mc mirror --quiet "backup-src/${bucket}" "${DEST}/minio/${bucket}" 2>/dev/null \
      && echo "  [ok] MinIO ${bucket} → ${DEST}/minio/${bucket}" \
      || echo "  [WARN] MinIO ${bucket} mirror failed"
  done
else
  echo "  [WARN] mc not found; skipping MinIO backup"
fi

# Compress
echo "  Compressing..."
tar -czf "${BACKUP_DIR}/backup-${TIMESTAMP}.tar.gz" -C "${BACKUP_DIR}" "${TIMESTAMP}"
rm -rf "${DEST}"
echo "  [ok] ${BACKUP_DIR}/backup-${TIMESTAMP}.tar.gz"

echo ""
echo "Backup complete: ${BACKUP_DIR}/backup-${TIMESTAMP}.tar.gz"
