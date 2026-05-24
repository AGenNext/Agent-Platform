#!/usr/bin/env bash
# Restore SurrealDB and MinIO from a backup created by backup.sh.
# Usage: ./scripts/restore.sh <overlay> <backup-dir>
# Example: ./scripts/restore.sh staging ./backups/staging/20240101-120000

set -euo pipefail

OVERLAY="${1:?Usage: restore.sh <overlay> <backup-dir>}"
BACKUP="${2:?Usage: restore.sh <overlay> <backup-dir>}"

NAMESPACE="realgraph"
[[ "${OVERLAY}" == "dev"     ]] && NAMESPACE="realgraph-dev"
[[ "${OVERLAY}" == "staging" ]] && NAMESPACE="realgraph-staging"

if [[ ! -d "${BACKUP}" ]]; then
  echo "ERROR: Backup directory not found: ${BACKUP}" >&2
  exit 1
fi

echo "WARNING: This will overwrite all data in namespace '${NAMESPACE}'."
read -rp "Type 'yes' to confirm: " CONFIRM
[[ "${CONFIRM}" != "yes" ]] && { echo "Aborted."; exit 1; }

SURREAL_POD=$(kubectl get pod -n "${NAMESPACE}" -l app=surrealdb -o jsonpath='{.items[0].metadata.name}')
SURREAL_USER=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.SURREALDB_USERNAME}' | base64 -d)
SURREAL_PASS=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.SURREALDB_PASSWORD}' | base64 -d)

if [[ -f "${BACKUP}/surrealdb.surql" ]]; then
  echo "==> Restoring SurrealDB from ${BACKUP}/surrealdb.surql"
  kubectl cp "${BACKUP}/surrealdb.surql" "${NAMESPACE}/${SURREAL_POD}:/tmp/restore.surql"
  kubectl exec "${SURREAL_POD}" -n "${NAMESPACE}" -- \
    surreal import \
      --conn http://localhost:8000 \
      --user "${SURREAL_USER}" \
      --pass "${SURREAL_PASS}" \
      --ns realgraph \
      --db platform \
      /tmp/restore.surql
  echo "   SurrealDB restored."
fi

MINIO_POD=$(kubectl get pod -n "${NAMESPACE}" -l app=minio -o jsonpath='{.items[0].metadata.name}')
MINIO_USER=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.MINIO_ROOT_USER}' | base64 -d)
MINIO_PASS=$(kubectl get secret platform-secrets -n "${NAMESPACE}" -o jsonpath='{.data.MINIO_ROOT_PASSWORD}' | base64 -d)

if [[ -d "${BACKUP}/minio" ]]; then
  echo "==> Restoring MinIO buckets"
  kubectl exec "${MINIO_POD}" -n "${NAMESPACE}" -- \
    mc alias set local http://localhost:9000 "${MINIO_USER}" "${MINIO_PASS}"
  for bucket in agent-artifacts agent-sources agent-traces; do
    if [[ -d "${BACKUP}/minio/${bucket}" ]]; then
      kubectl cp "${BACKUP}/minio/${bucket}" "${NAMESPACE}/${MINIO_POD}:/tmp/minio-restore/${bucket}"
      kubectl exec "${MINIO_POD}" -n "${NAMESPACE}" -- \
        mc mirror "/tmp/minio-restore/${bucket}" "local/${bucket}" --overwrite
      echo "   Restored bucket: ${bucket}"
    fi
  done
fi

echo ""
echo "✓ Restore complete from: ${BACKUP}"
