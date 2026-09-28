# Deploying Agent-Platform to Google Cloud (GKE)

This deploys the **functional** stack — a live URL backed by working data:

- **SurrealDB (3.x)** serves the platform API directly via `DEFINE API`
  (all business logic is SurrealQL, per the SurrealDB-First Engineering
  Contract — there is no Python service).
- **agent-dashboard** — the static Vite SPA, served by a thin Node process
  that reverse-proxies `/api/*` to SurrealDB with server-side credentials, so
  the browser never holds secrets and SurrealDB's `/sql` surface is never
  exposed.
- **MinIO** for object storage.
- **nginx ingress + cert-manager TLS**.
- A **schema loader** Helm hook applies `schema.surql` + `seed.surql` on every
  install/upgrade (idempotent).

Authentication to GCP is **keyless**: GitHub's OIDC token is exchanged for a
short-lived GCP access token via Workload Identity Federation. No
service-account key is ever stored.

The pipeline uses only the `gcloud`/`kubectl`/`docker`/`helm` CLIs and raw
HTTPS calls — **no third-party GitHub Actions** — to stay within a restrictive
org Actions allow-list.

## Prerequisites

- A GCP project where you have Owner (or equivalent).
- `gcloud` installed and logged in locally (`gcloud auth login`).
- The GitHub repository is `AGenNext/Agent-Platform`.

## 1. One-time setup (run locally)

```bash
export PROJECT_ID=your-gcp-project
export GITHUB_REPO=AGenNext/Agent-Platform
# optional overrides: REGION (default us-central1), CLUSTER, AR_REPO
bash deploy/gcp/setup.sh
```

This enables APIs, creates an Artifact Registry repo, a **GKE Autopilot**
cluster, a Workload Identity pool/provider locked to this repo, and a deploy
service account. It is idempotent. When it finishes it prints the exact
variables and secrets to set on GitHub.

## 2. Configure GitHub

In **Settings → Secrets and variables → Actions**:

**Repository variables** (not secret — copy the values `setup.sh` printed):

| Variable | Example |
|---|---|
| `GCP_PROJECT_ID` | `your-gcp-project` |
| `GCP_REGION` | `us-central1` |
| `GKE_CLUSTER` | `agent-platform` |
| `AR_REPO` | `agent-platform` |
| `WIF_PROVIDER` | `projects/123.../locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `WIF_SERVICE_ACCOUNT` | `agent-platform-deploy@your-gcp-project.iam.gserviceaccount.com` |
| `PLATFORM_HOST` | `platform.your-domain.com` |

**Repository secrets** (choose strong values):

| Secret | Purpose |
|---|---|
| `SURREALDB_PASSWORD` | SurrealDB root password |
| `MINIO_ROOT_PASSWORD` | MinIO root password |

## 3. Deploy

The `Deploy to GKE` workflow runs automatically on pushes to `main` that touch
the dashboard or chart, and can be run on demand from the **Actions** tab
(**Run workflow**). It builds and pushes the dashboard image, then
`helm upgrade --install`s the chart and waits for rollout.

## 4. Point DNS at the ingress

After the first successful deploy, get the external IP and create a DNS
`A`/`AAAA` record for `PLATFORM_HOST`:

```bash
gcloud container clusters get-credentials "$GKE_CLUSTER" --region "$GCP_REGION"
kubectl get ingress agent-platform -n agent-platform \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Once DNS resolves, cert-manager issues the TLS certificate and the platform is
live at `https://$PLATFORM_HOST`.

> **Note.** cert-manager and an nginx ingress controller must exist in the
> cluster. On a fresh Autopilot cluster, install them once:
> ```bash
> helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
> helm repo add jetstack https://charts.jetstack.io
> helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
> helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set crds.enabled=true
> ```
> and create a `letsencrypt-prod` `ClusterIssuer` (referenced by the chart's
> ingress annotations).

## Governance note

The SurrealDB-First Engineering Contract treats deployment topology as a
design change requiring quorum consensus. This pipeline was authored at the
repository owner's explicit direction; land it via the normal review/quorum
process before treating the deployment as sanctioned.
