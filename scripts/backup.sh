#!/usr/bin/env bash
# Backup SurrealDB data and MinIO buckets.
# Usage: ./scripts/backup.sh <overlay> [backup-dir]
# Backups are timestamped and stored in backup-dir (default: ./backups).

set -euo pipefail

OVERLAY="${1:-staging}"
BACKUP_DIR="${2:-./backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEST="${BACKUP_DIR}/${OVERLAY}/${TIMESTAMP}"

NAMESPACE="realgraph"
[[ "${OVERLAY}" == "dev"     ]] && NAMESPACE="realgraph-dev"
[[ "${OVERLAY}" == "staging" ]] && NAMESPACE="realgraph-staging"

mkdir -p "${DEST}"

echo "==> Backing up SurrealDB → ${DEST}/surrealdb.surql"
SURREAL_POD=$(kubectl get pod -n "${NAMESPACE}" -l app=surrealdb -o jsonpath='{.items[0].metadata.name}')
# SurrealDB export via HTTP API
SURREAL_USER=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.SURREALDB_USERNAME}' | base64 -d)
SURREAL_PASS=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.SURREALDB_PASSWORD}' | base64 -d)

kubectl exec "${SURREAL_POD}" -n "${NAMESPACE}" -- \
  surreal export \
    --conn http://localhost:8000 \
    --user "${SURREAL_USER}" \
    --pass "${SURREAL_PASS}" \
    --ns realgraph \
    --db platform \
    /tmp/backup.surql

kubectl cp "${NAMESPACE}/${SURREAL_POD}:/tmp/backup.surql" "${DEST}/surrealdb.surql"
echo "   SurrealDB backup: $(wc -l < "${DEST}/surrealdb.surql") lines"

echo "==> Backing up MinIO buckets → ${DEST}/minio/"
mkdir -p "${DEST}/minio"
MINIO_POD=$(kubectl get pod -n "${NAMESPACE}" -l app=minio -o jsonpath='{.items[0].metadata.name}')
MINIO_USER=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.MINIO_ROOT_USER}' | base64 -d)
MINIO_PASS=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.MINIO_ROOT_PASSWORD}' | base64 -d)

kubectl exec "${MINIO_POD}" -n "${NAMESPACE}" -- \
  mc alias set local http://localhost:9000 "${MINIO_USER}" "${MINIO_PASS}"

for bucket in agent-artifacts agent-sources agent-traces; do
  kubectl exec "${MINIO_POD}" -n "${NAMESPACE}" -- \
    mc mirror "local/${bucket}" "/tmp/minio-backup/${bucket}" 2>/dev/null || true
  mkdir -p "${DEST}/minio/${bucket}"
  kubectl cp "${NAMESPACE}/${MINIO_POD}:/tmp/minio-backup/${bucket}" "${DEST}/minio/${bucket}" 2>/dev/null || echo "   Bucket ${bucket}: empty or skipped"
done

echo ""
BACKUP_SIZE=$(du -sh "${DEST}" | cut -f1)
echo "✓ Backup complete: ${DEST} (${BACKUP_SIZE})"
echo "  Timestamp: ${TIMESTAMP}"
