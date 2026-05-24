#!/usr/bin/env bash
# Build and push Docker images to the local MicroK8s registry.
# Usage: ./scripts/build-images.sh [TAG]
# TAG defaults to git short SHA.

set -euo pipefail

REGISTRY="${REGISTRY:-localhost:32000}"
TAG="${1:-$(git rev-parse --short HEAD)}"

echo "==> Building images (tag: ${TAG})"

docker build \
  -t "${REGISTRY}/realgraph/agent-knowledge:${TAG}" \
  -t "${REGISTRY}/realgraph/agent-knowledge:latest" \
  docker/agent-knowledge/

docker build \
  -t "${REGISTRY}/realgraph/agent-dashboard:${TAG}" \
  -t "${REGISTRY}/realgraph/agent-dashboard:latest" \
  docker/agent-dashboard/

echo "==> Pushing to local registry"
docker push "${REGISTRY}/realgraph/agent-knowledge:${TAG}"
docker push "${REGISTRY}/realgraph/agent-knowledge:latest"
docker push "${REGISTRY}/realgraph/agent-dashboard:${TAG}"
docker push "${REGISTRY}/realgraph/agent-dashboard:latest"

echo "✓ Images pushed: agent-knowledge:${TAG}, agent-dashboard:${TAG}"
