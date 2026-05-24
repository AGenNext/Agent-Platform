#!/usr/bin/env bash
# Deploy RealGraph to MicroK8s using Kustomize overlays.
# Usage: ./scripts/deploy.sh <overlay>   # overlay: dev | staging | prod

set -euo pipefail

OVERLAY="${1:-staging}"
OVERLAY_DIR="k8s/overlays/${OVERLAY}"

if [[ ! -d "${OVERLAY_DIR}" ]]; then
  echo "ERROR: Unknown overlay '${OVERLAY}'. Choose: dev | staging | prod" >&2
  exit 1
fi

echo "==> Deploying overlay: ${OVERLAY}"

# Apply cert-manager issuers first (cluster-scoped)
kubectl apply -f k8s/base/letsencrypt-issuer.yaml || true

# Apply everything else via kustomize
kubectl apply -k "${OVERLAY_DIR}"

echo "==> Waiting for rollout: agent-knowledge"
NAMESPACE=$(kubectl get ns realgraph realgraph-staging realgraph-dev --no-headers -o name 2>/dev/null | grep -i "${OVERLAY}" | head -1 | cut -d/ -f2 || echo realgraph)
kubectl rollout status deployment/agent-knowledge -n "${NAMESPACE}" --timeout=300s

echo "==> Waiting for rollout: agent-dashboard"
kubectl rollout status deployment/agent-dashboard -n "${NAMESPACE}" --timeout=120s

echo ""
echo "==> Post-deploy health checks"
KNOWLEDGE_POD=$(kubectl get pod -n "${NAMESPACE}" -l app=agent-knowledge -o jsonpath='{.items[0].metadata.name}')
kubectl exec "${KNOWLEDGE_POD}" -n "${NAMESPACE}" -- \
  curl -sf http://localhost:8001/health | python3 -c "import sys,json; d=json.load(sys.stdin); print('API health:', d['status'], '| DB:', d['surrealdb'])"

echo ""
echo "✓ Deployment complete — overlay: ${OVERLAY}"
