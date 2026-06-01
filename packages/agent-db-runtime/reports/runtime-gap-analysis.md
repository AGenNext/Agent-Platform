# Agent DB Runtime Gap Analysis v0.1

Status: draft, implementation evidence pending.

Repository: `AGenNext/Agent-Platform`

Primary package: `packages/agent-db-runtime/`

## Purpose

This report compares the frozen Agent DB Runtime architecture against implementation status.

It distinguishes:

```txt
Defined
Designed
Implemented
Validated
```

## Source architecture

The runtime is now defined through:

```txt
docs/frozen-framework-v0.1.md
docs/meta-model.md
docs/runtime-ontology.jsonld
docs/runtime-erd.mmd
graphql/runtime.graphql
openapi/runtime-openapi.yaml
events/runtime-cloudevents.yaml
protocols/runtime-mcp.yaml
protocols/runtime-a2a.yaml
protocols/runtime-authzen.yaml
protocols/runtime-openfga.yaml
protocols/runtime-opa.yaml
schema/design/runtime-meta-model.surql
```

## Gap classes

### G0 — No gap

Defined, implemented, and validated.

### G1 — Validation gap

Implemented, but not validated.

### G2 — Implementation gap

Defined and designed, but not implemented.

### G3 — Runtime integration gap

Implemented as isolated schema or docs, but not wired into runtime flows.

### G4 — Evidence gap

Claim exists, but no evidence exists.

### G5 — Production gap

Works in local/demo form but lacks deployment, security, recovery, observability, or operational gates.

## Gap matrix

| Domain | Defined | Designed | Implemented | Validated | Gap |
|---|---:|---:|---:|---:|---|
| WorkDefinition / UnitOfWork | Yes | Yes | Unknown | No | G1/G2 |
| Project / Milestone / Task | Yes | Yes | Partial | No | G1/G3 |
| Card model | Yes | Yes | Partial | No | G1/G3 |
| Signed cards | Yes | Yes | No | No | G2 |
| Registry Platform issuer | Yes | Yes | Partial | No | G1/G3 |
| Verified capability | Yes | Yes | Partial | No | G1/G3 |
| Certification | Yes | Yes | No | No | G2 |
| Accreditation | Yes | Yes | No | No | G2 |
| Recognition | Yes | Yes | No | No | G2 |
| Discovery | Yes | Yes | No | No | G2 |
| Qualification | Yes | Yes | No | No | G2 |
| Eligibility | Yes | Yes | Partial | No | G1/G3 |
| Recommendation | Yes | Yes | No | No | G2 |
| Selection / Rejection | Yes | Yes | No | No | G2 |
| Tool model | Yes | Yes | Partial | No | G1/G3 |
| Skill model | Yes | Yes | Partial | No | G1/G3 |
| Operator model | Yes | Yes | Partial | No | G1/G3 |
| MCP mapping | Yes | Yes | No | No | G2 |
| A2A mapping | Yes | Yes | No | No | G2 |
| AuthZEN mapping | Yes | Yes | No | No | G2 |
| OpenFGA mapping | Yes | Yes | No | No | G2 |
| OPA mapping | Yes | Yes | No | No | G2 |
| Evidence logging | Yes | Yes | Partial | No | G1/G3 |
| Decision logging | Yes | Yes | Partial | No | G1/G3 |
| Evaluation / Trust | Yes | Yes | Partial | No | G1/G3 |
| Knowledge promotion | Yes | Yes | Partial | No | G1/G3 |
| Memory / RAG reconstruction | Yes | Yes | Partial | No | G1/G3 |
| Incident / SLA | Yes | Yes | Partial | No | G1/G3 |
| OpenAPI runtime surface | Yes | Yes | No | No | G2 |
| GraphQL runtime surface | Yes | Yes | No | No | G2 |
| CloudEvents publishing | Yes | Yes | No | No | G2 |
| SurrealQL design schema | Yes | Yes | Design only | No | G3 |

## Immediate critical gaps

### 1. Validation evidence missing

No current report proves:

```txt
npm ci
npm run typecheck
npm run db:validate
npm run db:apply
npm run db:seed
npm run db:smoke
make check
```

Gap class: `G4 Evidence gap`

### 2. Design schema not in runtime load order

`schema/design/runtime-meta-model.surql` exists as a design artifact but is intentionally not in runtime load order.

Gap class: `G3 Runtime integration gap`

### 3. Protocol mappings are contracts, not implementations

MCP, A2A, AuthZEN, OpenFGA, and OPA mappings are defined but not wired into executable runtime adapters.

Gap class: `G2 Implementation gap`

### 4. Card lifecycle not executable end-to-end

The chain is defined:

```txt
Draft Card
  -> Signed Card
    -> Verified Capability
      -> Certified Capability
        -> Discovery
          -> Qualification
            -> Eligibility
              -> Recommendation
                -> Selection / Rejection
```

but not proven executable.

Gap class: `G2/G3`

### 5. Knowledge promotion not enforced

The rule is defined:

```txt
Only documented, signed, governed, and verified artifacts can become Knowledge.
```

but enforcement is not proven.

Gap class: `G1/G3`

## Recommended execution order

### Phase 1 — Validation baseline

Run:

```bash
cd packages/agent-db-runtime
make check
```

Produce:

```txt
runtime-validation-report.md
```

### Phase 2 — Runtime load order reconciliation

Compare existing schema load order against:

```txt
schema/design/runtime-meta-model.surql
```

Decide which design elements should become runtime schema in v0.1.

### Phase 3 — Minimal executable card lifecycle

Implement only the smallest flow:

```txt
submit card
sign card
record evidence
verify capability
record decision
```

### Phase 4 — Minimal discovery flow

Implement:

```txt
discover cards
qualify candidate
check eligibility
recommend candidate
select/reject candidate
```

### Phase 5 — Protocol adapter backlog

Create separate issues for:

```txt
MCP adapter
A2A adapter
AuthZEN endpoint
OpenFGA model/check adapter
OPA policy bundle
CloudEvents publisher
```

## Current truth

The Agent DB Runtime is now comprehensively specified.

It is not yet comprehensively implemented.

It is not validated.

Do not claim deployment or production readiness until validation evidence exists.
