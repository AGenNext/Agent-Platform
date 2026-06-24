#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "${ROOT_DIR}/platform/enterprise-app/crd/enterpriseapps.platform.agennext.io.yaml"

kubectl create namespace platform-apps --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "${ROOT_DIR}/platform/enterprise-app/catalog/whoami.yaml"

kubectl get enterpriseapps.platform.agennext.io -A
