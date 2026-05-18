# Bolt Frontend Bootstrap Decision

## Decision

Use Bolt-style/vibe-coded frontend generation to bootstrap the first Agent Platform frontend experience quickly.

The generated frontend may be used to accelerate:

- Agent-Dashboard screens
- Agent-Site pages
- run history UI
- trace explorer UI
- human approval UI
- blocked runs UI
- scheduled runs UI
- agent builder/admin surfaces

## Boundary

Bolt-generated UI is an accelerator, not the source of truth for platform architecture.

```text
Bolt / vibe-coded frontend
  → fast UI generation and iteration

Agent-Dashboard
  → hardened product control plane

Agent-Site
  → hardened public website/docs/marketing surface

Agent-Knowledge
  → product API and backend logic

Agent-Platform
  → platform assembly and deployment boundary
```

## What Bolt Can Own Initially

Bolt can help generate:

- React/Vite/Next.js screens
- dashboard layouts
- forms
- tables
- charts
- cards
- trace timelines
- approval flows
- admin panels
- responsive UI components

## What Bolt Must Not Own

Bolt must not own:

- runtime state
- agent orchestration
- A2A handoffs
- SurrealDB schema
- Agent-Traces contracts
- secrets management
- deployment logic
- tenant isolation
- billing/metering logic
- evaluation/trust/finops decisions
- canonical product data model

## Recommended Workflow

```text
1. Generate UI quickly with Bolt/vibe coding.
2. Move hardened code into Agent-Dashboard or Agent-Site.
3. Connect only to stable Agent-Knowledge APIs.
4. Keep API contracts in AGenNext repos.
5. Replace throwaway/generated code when it becomes core.
6. Keep product data canonical in AGenNext backend and SurrealDB.
```

## Integration Rule

Bolt frontend should consume APIs; it should not define backend contracts.

```text
Frontend consumes:
  GET /health
  POST /objectives/run
  GET /objectives/{task_id}/events
  POST /objectives/{task_id}/approval
  future run history / schedule / blocker APIs
```

## Final Rule

```text
Use Bolt for speed.
Use AGenNext repos for ownership.
Harden what matters.
Throw away what does not.
```
