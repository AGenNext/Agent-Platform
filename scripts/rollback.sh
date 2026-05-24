#!/usr/bin/env bash
# Roll back deployments to the previous revision.
# Usage: ./scripts/rollback.sh <overlay> [deployment]
# If deployment is omitted, rolls back all platform deployments.

set -euo pipefail

OVERLAY="${1:-staging}"
TARGET="${2:-all}"

NAMESPACE="realgraph"
[[ "${OVERLAY}" == "dev"     ]] && NAMESPACE="realgraph-dev"
[[ "${OVERLAY}" == "staging" ]] && NAMESPACE="realgraph-staging"

DEPLOYMENTS=(agent-knowledge agent-dashboard)
[[ "${TARGET}" != "all" ]] && DEPLOYMENTS=("${TARGET}")

for dep in "${DEPLOYMENTS[@]}"; do
  echo "==> Rolling back deployment: ${dep} in ${NAMESPACE}"
  kubectl rollout history "deployment/${dep}" -n "${NAMESPACE}" | tail -5
  kubectl rollout undo "deployment/${dep}" -n "${NAMESPACE}"
  kubectl rollout status "deployment/${dep}" -n "${NAMESPACE}" --timeout=120s
  CURRENT=$(kubectl get deployment "${dep}" -n "${NAMESPACE}" \
    -o jsonpath='{.spec.template.spec.containers[0].image}')
  echo "   Now running: ${CURRENT}"
done

echo ""
echo "✓ Rollback complete."
echo "  Run ./scripts/deploy.sh ${OVERLAY} to re-deploy latest when ready."
