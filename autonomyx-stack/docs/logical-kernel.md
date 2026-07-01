# Autonomyx Logical Kernel

The logical kernel turns an execution request into a deterministic, verifiable graph mutation.

## Pipeline

```text
Intent
  -> plan
  -> verify
  -> apply patches
  -> diff graph
  -> reconcile result
```

## Core modules

- `types.ts` — kernel intent, constraints, execution plans, graph patches, diffs, reconciliation results.
- `planner.ts` — deterministic planner for Autonomyx arithmetic operations.
- `verifier.ts` — domain and constraint verifier.
- `apply.ts` — graph patch application engine.
- `diff.ts` — before/after graph diff engine.
- `index.ts` — `reconcileIntent()` facade.

## Arithmetic mapping

| Operator | Meaning | Kernel behavior |
| --- | --- | --- |
| `⊕` | Add | Add a domain-bound node. |
| `⊖` | Remove | Remove a domain-bound node and dependent edges. |
| `⊗` | Transform | Apply graph weight transformation. |
| `÷` | Scope | Add an explicit domain-scope node. |

## Design law

Every execution is either:

- sequential: strict dependency chain
- parallel: independent transform set

The planner records this in `ExecutionStep.mode`.

## Verification rules

The first verifier includes:

- domain required
- step dependency existence
- node patch domain matching
- edge patch domain matching
- optional max-node-count constraint
- optional no-cross-domain-edges constraint

## Reconciliation result

`reconcileIntent()` returns:

```ts
{
  graph,
  diff,
  verification,
  plan
}
```

This is now bound into `runPlatform()`, so MVP execution goes through:

```text
gate -> logical kernel -> graph diff -> audit reason
```

## Current scope

This is a deterministic logical kernel MVP. It does not yet include:

- rollback journals
- multi-step dependency graphs
- conflict detection
- transaction isolation
- replay engine
- graph snapshots
- parallel execution worker pool
