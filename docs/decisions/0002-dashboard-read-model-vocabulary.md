# 0002 — Dashboard read-model record types

- **Type:** Language / vocabulary / ontology change (`AGENTS.md` §Language,
  Vocabulary, and Ontology Change Control)
- **Status:** PROPOSED — pending quorum
- **Affected PR:** making Agent-Platform live on GCP (GKE)

This record documents new record-type (table) names introduced for the
dashboard read models, for quorum review. It is a proposal, not an approval.

## Current term or structure

No tables existed for the dashboard's collaboration / learning / routing read
models. The dashboard had no SurrealDB-owned vocabulary for these concepts.

## Proposed term or structure

Six new `SCHEMALESS` record types (tables):

| Record type | Meaning |
|-------------|---------|
| `spaces` | A top-level workspace grouping collaboration channels and work. |
| `channels` | A conversation/work stream within a space. |
| `milestones` | A dated delivery checkpoint shown on the dashboard. |
| `learning_paths` | An ordered set of learning modules surfaced in the UI. |
| `agent_profiles` | The displayed roster entry for an agent role (name, role, status). |
| `model_routes` | A model-routing read model (provider, model, share, health) for the router view. |

## Exact semantic meaning

These are **read-model / presentation** record types that back dashboard views.
They describe displayed state; they are not new decision or policy concepts.
Routing *decisions* remain owned by `fn::model_router::select` over
`routing_rules`; `model_routes` is a read-only projection for display only.

## Affected SurrealDB tables, fields, functions, events, APIs, permissions

- **Tables:** the six above (added via `DEFINE TABLE OVERWRITE … PERMISSIONS …`).
- **APIs:** `GET /spaces`, `/channels`, `/milestones`, `/learning/paths`,
  `/agents/roster` (reads `agent_profiles`), `/model-router/routes` (reads
  `model_routes`).
- **Permissions:** all six are caller-read-only (`FOR select FULL`, writes
  `NONE`); only root/loader seeds them.
- **Functions/events:** none added for these tables; no events defined.

## Affected JSON-LD / context mappings

None currently defined. If/when a JSON-LD context is published for the platform
vocabulary, these six terms must be added to it; tracked as a follow-up.

## Affected docs and UI labels

- UI: `docker/agent-dashboard/ui/src/api.ts` types (`Space`, `Channel`,
  `Milestone`, `LearningPath`, `AgentProfile`, `ModelRoute`) and the views that
  render them.
- Docs: this record; the PR description.

## Migration path for existing records

Additive only — no existing records are renamed, re-typed, or deleted. Seed data
(`seed.surql`) populates demo rows. No backfill or data migration required.

## Compatibility impact

- Backward compatible: purely additive table names; no existing term changes
  meaning, so no consumer breaks.
- Forward: these are read models; if the underlying concepts later gain
  authoritative/decisioning semantics, that would be a further change requiring
  its own record.

## Quorum approvers

- PENDING — _(to be completed by quorum reviewers; not the author/agent)_
