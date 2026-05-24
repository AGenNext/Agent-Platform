#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu 22.04/24.04 VPS for RealGraph on MicroK8s.
# Run as root or a sudo-capable user.
# Usage: ./scripts/bootstrap-vps.sh

set -euo pipefail

MICROK8S_CHANNEL="${MICROK8S_CHANNEL:-1.31/stable}"

echo "==> Installing MicroK8s ${MICROK8S_CHANNEL}"
snap install microk8s --classic --channel="${MICROK8S_CHANNEL}"
usermod -aG microk8s "${USER:-ubuntu}"
mkdir -p ~/.kube
microk8s config > ~/.kube/config
chmod 600 ~/.kube/config

echo "==> Waiting for MicroK8s to be ready"
microk8s status --wait-ready --timeout=120

echo "==> Enabling core add-ons"
microk8s enable dns
microk8s enable hostpath-storage
microk8s enable ingress
microk8s enable metrics-server
microk8s enable cert-manager

echo "==> Enabling local registry (port 32000)"
microk8s enable registry

echo "==> Aliasing kubectl and helm"
snap alias microk8s.kubectl kubectl
snap alias microk8s.helm helm

echo "==> Installing Docker (for image builds)"
if ! command -v docker &>/dev/null; then
  apt-get update -qq
  apt-get install -y --no-install-recommends docker.io
  usermod -aG docker "${USER:-ubuntu}"
fi

echo "==> Configuring Docker to trust local registry"
cat > /etc/docker/daemon.json <<'EOF'
{
  "insecure-registries": ["localhost:32000"]
}
EOF
systemctl restart docker

echo "==> Setting up firewall"
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo ""
echo "✓ MicroK8s bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Log out and back in for group membership to take effect"
echo "  2. Edit k8s/base/secrets.yaml with real credentials"
echo "  3. Edit k8s/base/ingress.yaml with your domain"
echo "  4. Run: ./scripts/deploy.sh staging"
