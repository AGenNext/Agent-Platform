# Agent-Platform Engineering Contract

## SurrealDB-First Runtime Rule

SurrealDB is the only approved layer for platform data processing, storage, business logic, policy enforcement, runtime state, API endpoints, permissions, live queries, and deterministic decisioning.

SurrealML is the approved learned inference layer for model-backed scoring, classification, and prediction inside the runtime.

LLMs are tools for open-ended language work only: generation, extraction, semantic judgment, summarization, and reasoning over ambiguous user intent. LLM output must be written back into SurrealDB as governed state with provenance.

## Prohibited Without Quorum Consensus

Do not implement business logic in Python, JavaScript, TypeScript, shell scripts, YAML, external services, or frontend code.

This includes:

- scoring
- trust gates
- model routing decisions
- budget enforcement
- lifecycle transitions
- approval decisions
- permissions
- policy checks
- memory selection
- belief updates
- runtime state mutation
- public runtime API behavior

Any proposal to place business logic outside SurrealDB requires quorum consensus before implementation. The proposal must document:

- why SurrealDB or SurrealML cannot handle it
- the exact temporary boundary
- how state, provenance, permissions, and audit remain in SurrealDB
- the migration path back into SurrealDB
- the reviewers who approved the exception

No quorum, no exception.

## CI/CD Enforcement

Every repository must include a CI/CD governance check that fails when Python business logic is introduced.

Validation must run on the user's/client's system before artifacts, changes, deployment requests, grammar changes, vocabulary changes, ontology changes, or runtime changes are accepted by AGenNext servers.

Validation and authoring feedback must be fast and delivered at the edge. Checks that can run locally must run in the user's browser/client before server submission.

Outside SurrealDB, SurrealQL, SurrealML, and AgentQL, the only approved implementation language is browser-side TypeScript.

TypeScript is allowed for user/browser UI, browser-side AgentQL authoring, browser-side validation hints, browser-side editor tooling, and edge-delivered validation UX. It is not approved for backend business logic, server-side runtime logic, policy enforcement, product decisions, deployment decisions, or server-side validation ownership.

The check must reject Python-owned:

- HTTP business endpoints
- scoring
- routing decisions
- trust gates
- eval gates
- policy checks
- lifecycle transitions
- approval decisions
- runtime state mutation
- product/domain models

Agent-Platform enforces this with:

```bash
./scripts/check-no-python-business-logic.sh
```

The editable validation definitions live in:

```text
governance/no-python-business-logic.rules.tsv
```

The check is intentionally strict. Existing violations must be migrated to SurrealDB `DEFINE API`, SurrealQL custom functions, SurrealDB events/permissions, AgentQL-generated SurrealQL, or SurrealML bindings.

## Design Change Control

Any design change, architecture deviation, runtime-layer deviation, data-ownership change, policy-location change, business-logic placement change, API ownership change, or source-of-truth change requires quorum consensus before implementation.

This applies even when the change looks small, temporary, convenient, or faster.

Every approved design change must record:

- the current approved design
- the proposed deviation
- why the deviation is needed
- what alternatives were rejected
- impact on SurrealDB ownership
- impact on SurrealML ownership
- impact on provenance, audit, permissions, and runtime state
- rollback or migration path
- quorum approvers

No quorum, no design change.

## Language, Vocabulary, and Ontology Change Control

Any grammar, vocabulary, ontology, taxonomy, schema-language, naming, semantic-model, domain-term, relation, entity-type, record-type, edge-type, JSON-LD context, or meaning change requires quorum consensus before implementation.

This applies to:

- new terms
- renamed terms
- deleted terms
- changed definitions
- changed relationships
- changed status values
- changed enum values
- changed record/table names
- changed field names
- changed graph edge names
- changed API names
- changed capability names
- changed policy names
- changed agent role names
- changed memory, belief, mind, brain, or constitution concepts

Every approved language or ontology change must record:

- the current term or structure
- the proposed term or structure
- the exact semantic meaning
- affected SurrealDB tables, fields, functions, events, APIs, and permissions
- affected JSON-LD/context mappings
- affected docs and UI labels
- migration path for existing records
- compatibility impact
- quorum approvers

No quorum, no vocabulary change.

## Allowed Outside SurrealDB

Non-business presentation and packaging code is allowed outside SurrealDB only when it does not decide, score, route, approve, authorize, mutate runtime state, or enforce policy.

## Final Rule

If it changes what the platform believes, decides, permits, routes, scores, stores, exposes, or remembers, it belongs in SurrealDB or SurrealML.

If it changes the approved design, it requires quorum consensus first.

If it changes language, vocabulary, ontology, taxonomy, naming, grammar, or meaning, it requires quorum consensus first.
