#!/usr/bin/env bash
#
# One-time GCP setup for deploying Agent-Platform to GKE via Helm.
#
# Run this once, locally, with an account that has Owner (or equivalent) on the
# target project. It is idempotent: safe to re-run. It provisions:
#   - Required GCP APIs
#   - An Artifact Registry Docker repository (for the dashboard image)
#   - A GKE Autopilot cluster
#   - A Workload Identity Federation pool + provider bound to this GitHub repo
#   - A deploy service account with the roles the pipeline needs
#
# It prints, at the end, the exact repository variables and secrets to set on
# GitHub so the deploy workflow (.github/workflows/deploy-gcp.yml) can run with
# NO long-lived service-account keys (keyless OIDC / Workload Identity).
#
# Nothing here is secret except the two application passwords you choose for
# SurrealDB and MinIO; set those as GitHub Actions secrets (see the README).
set -euo pipefail

# ---- Configuration (override via environment) -------------------------------
PROJECT_ID="${PROJECT_ID:?set PROJECT_ID to your GCP project id}"
REGION="${REGION:-us-central1}"
CLUSTER="${CLUSTER:-agent-platform}"
AR_REPO="${AR_REPO:-agent-platform}"
# owner/repo of THIS GitHub repository — WIF will only trust tokens from it.
GITHUB_REPO="${GITHUB_REPO:?set GITHUB_REPO to the owner/repo, e.g. AGenNext/Agent-Platform}"

POOL="github-pool"
PROVIDER="github-provider"
DEPLOY_SA="agent-platform-deploy"

echo "==> Using project=$PROJECT_ID region=$REGION cluster=$CLUSTER repo=$GITHUB_REPO"
gcloud config set project "$PROJECT_ID" >/dev/null

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
SA_EMAIL="${DEPLOY_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

# ---- 1. Enable APIs ---------------------------------------------------------
echo "==> Enabling APIs"
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  iam.googleapis.com \
  compute.googleapis.com

# ---- 2. Artifact Registry ---------------------------------------------------
echo "==> Ensuring Artifact Registry repo '$AR_REPO'"
if ! gcloud artifacts repositories describe "$AR_REPO" --location="$REGION" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$AR_REPO" \
    --repository-format=docker --location="$REGION" \
    --description="Agent Platform container images"
fi

# ---- 3. GKE Autopilot cluster ----------------------------------------------
echo "==> Ensuring GKE Autopilot cluster '$CLUSTER' (this can take ~10 min on first run)"
if ! gcloud container clusters describe "$CLUSTER" --region="$REGION" >/dev/null 2>&1; then
  gcloud container clusters create-auto "$CLUSTER" --region="$REGION"
fi

# ---- 4. Deploy service account ---------------------------------------------
echo "==> Ensuring deploy service account '$SA_EMAIL'"
if ! gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$DEPLOY_SA" \
    --display-name="Agent Platform CI deployer"
fi

echo "==> Granting roles to the deploy service account"
for ROLE in \
  roles/container.developer \
  roles/artifactregistry.writer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" --role="$ROLE" \
    --condition=None >/dev/null
done

# ---- 5. Workload Identity Federation ---------------------------------------
echo "==> Ensuring Workload Identity pool '$POOL'"
if ! gcloud iam workload-identity-pools describe "$POOL" \
      --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL" \
    --location=global --display-name="GitHub Actions pool"
fi

echo "==> Ensuring OIDC provider '$PROVIDER' (restricted to repo $GITHUB_REPO)"
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER" \
      --location=global --workload-identity-pool="$POOL" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
    --location=global --workload-identity-pool="$POOL" \
    --display-name="GitHub Actions provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository=='${GITHUB_REPO}'"
fi

# Allow tokens from THIS repo to impersonate the deploy service account.
POOL_ID="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}"
echo "==> Binding repo $GITHUB_REPO to service account impersonation"
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${GITHUB_REPO}" \
  >/dev/null

PROVIDER_RESOURCE="${POOL_ID}/providers/${PROVIDER}"

# ---- 6. Output --------------------------------------------------------------
cat <<EOF

============================================================================
 Setup complete. Configure GitHub -> Settings -> Secrets and variables ->
 Actions on ${GITHUB_REPO} with the following.

 Repository VARIABLES (not secret):
   GCP_PROJECT_ID       = ${PROJECT_ID}
   GCP_REGION           = ${REGION}
   GKE_CLUSTER          = ${CLUSTER}
   AR_REPO              = ${AR_REPO}
   WIF_PROVIDER         = ${PROVIDER_RESOURCE}
   WIF_SERVICE_ACCOUNT  = ${SA_EMAIL}
   PLATFORM_HOST        = platform.example.com   # <- your real DNS name

 Repository SECRETS (choose strong values; used by Helm --set):
   SURREALDB_PASSWORD   = <a strong password>
   MINIO_ROOT_PASSWORD  = <a strong password>

 After the first successful deploy, point PLATFORM_HOST's DNS A/AAAA record at
 the ingress external IP:
   kubectl get ingress agent-platform -n agent-platform \\
     -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
============================================================================
EOF
