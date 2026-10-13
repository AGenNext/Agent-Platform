# 0001 — GKE deployment topology + SurrealDB-served API

- **Type:** Design change (`AGENTS.md` §Design Change Control)
- **Status:** PROPOSED — pending quorum
- **Affected PR:** making Agent-Platform live on GCP (GKE)

This record documents the design change for quorum review. It is a proposal, not
an approval.

## Current approved design

- The platform API was provided by a Python `agent-knowledge` service
  (FastAPI), with SurrealDB as the data layer behind it.
- No standing hosted deployment target; the platform ran via local
  docker-compose for development/testing.

## Proposed deviation

1. **API ownership moves into SurrealDB.** The HTTP API is served directly by
   SurrealDB via `DEFINE API` with business logic in SurrealQL (`fn::…`
   functions). The Python `agent-knowledge` service is disabled by default
   (`agentKnowledge.enabled=false`) and retained only for transition.
2. **Hosted runtime topology = GKE via Helm.** A GKE Autopilot cluster runs the
   Helm chart (SurrealDB StatefulSet, dashboard Deployment, MinIO, nginx
   ingress + cert-manager TLS). A schema-loader Helm hook applies schema+seed.
3. **Keyless CI/CD deploy.** A GitHub Actions workflow builds/pushes the
   dashboard image to Artifact Registry and runs `helm upgrade --install`,
   authenticating via Workload Identity Federation (no stored keys), and gated
   on required governance check evidence for the deployed commit SHA.

## Why the deviation is needed

- The contract requires business logic, API endpoints, and permissions to live
  in SurrealDB; moving the API off Python into `DEFINE API` brings the runtime
  into compliance (this part reduces, not increases, deviation).
- A hosted target (GKE) is required to deliver a live URL with working data.

## Alternatives rejected

- **Keep the Python API service.** Rejected: violates the SurrealDB-First rule
  (business logic / public runtime API behavior in Python).
- **Static-only hosting (e.g. Pages/CDN).** Rejected: cannot run SurrealDB, so
  it cannot serve a functional, data-backed API.
- **Managed SurrealDB (Surreal Cloud) + static dashboard.** Deferred: viable
  future option; GKE chosen to keep data, object storage, and ingress under one
  cluster the owner controls.

## Impact on SurrealDB ownership

Increased and clarified: SurrealDB now owns the API surface, business logic,
permissions, and runtime state. The Node dashboard process is dumb transport
only (serves static assets, reverse-proxies `/api`, holds no credentials, makes
no decisions).

## Impact on SurrealML ownership

None. No SurrealML models are added, moved, or removed by this change.

## Impact on provenance, audit, permissions, and runtime state

- **Permissions:** enforced in SurrealDB. Callers authenticate as the
  credential-less `public` record access, bound by per-table `PERMISSIONS`
  (reads open; writes limited to documented dashboard actions; deletes/DDL
  denied). root is confined to the SurrealDB StatefulSet and the schema-loader.
- **Runtime state & provenance:** unchanged in shape; eval/trust results and
  usage records remain SurrealDB records written by SurrealQL functions.
- **Audit:** deploys are gated on required check evidence for the commit SHA;
  the schema-loader fails closed on any SurrealQL statement error.

## Rollback or migration path

- Deployment is declarative: `helm uninstall agent-platform` removes the
  workloads; the cluster/registry/WIF created by `deploy/gcp/setup.sh` can be
  torn down with standard `gcloud` deletes.
- The Python service path is not deleted (guarded by `agentKnowledge.enabled`),
  so the prior API topology can be re-enabled if quorum reverses this decision.
- SurrealDB data persists on a PVC; snapshot/export before uninstall to retain
  state.

## Quorum approvers

- PENDING — _(to be completed by quorum reviewers; not the author/agent)_
