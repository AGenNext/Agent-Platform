# Autonomyx OAM Mapping

Autonomyx is pinned to the Open Application Model concept described in the CNCF article, with Autonomyx extensions for governance, certification, re-base, and graph state.

## Canonical mapping

| OAM primitive | Autonomyx primitive | Meaning |
| --- | --- | --- |
| Component | Publication | A deployable, immutable application capability. |
| Trait | Policy | Operational behavior and governance controls. |
| Scope | Domain | Execution, trust, and visibility boundary. |
| Workflow | Execution Chain | Ordered or parallel runtime path. |
| ApplicationConfiguration | autonomyx.manifest | Executable contract binding domain, identity, policy, graph, and certification. |

## Build rule

Every Autonomyx component is itself an OAM-style application. Each application is a gate: it exposes capabilities only through domain-bound, policy-governed, audited execution.

## Stack tiers

1. Foundation: domain, identity, policy, graph.
2. Governance: trust, certification, audit.
3. Runtime: execution, publication, discovery.
4. OAM: OAM renderer and manifest contract.
5. Experience: AutoDesk and centers for builder, graph, trust, policy, publish, certify.

## Invariant

No application bypasses domain, identity, policy, graph, audit, or certification. If it cannot be represented in `autonomyx.manifest`, it is not part of the platform.
