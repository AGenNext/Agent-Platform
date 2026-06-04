# Agent DB Runtime Taxonomy Model

Status: draft taxonomy layer.

## Purpose

Taxonomy sits between ontology and schema.

```txt
Ontology
  defines meaning and relationships

Taxonomy
  defines controlled categories, types, states, dimensions, and allowed values

Schema
  defines fields, records, constraints, indexes, and validation

Policy
  defines rules and enforcement

Evidence
  proves events and claims
```

## Core rule

```txt
Ontology explains what exists.
Taxonomy controls how things are classified.
Schema enforces how things are stored.
Policy enforces what is allowed.
Evidence proves what happened.
```

## Why taxonomy is required

Without taxonomy, schemas become loose data capture.

Examples:

```txt
Schema field: tool_type
Taxonomy values: api | database | cli | browser | mcp_server | a2a_endpoint

Schema field: evidence_type
Taxonomy values: command_output | signed_artifact | validation_report | audit_log | source_anchor

Schema field: value_type
Taxonomy values: financial | operational | compliance | trust | user | knowledge | risk_reduction
```

## Taxonomy principles

```txt
Controlled values must be versioned.
Taxonomies must have owners.
Taxonomies must support aliases and deprecation.
Taxonomies must be mappable to external standards when possible.
Taxonomies must be referenced by schema and policy.
Taxonomies must not silently change meaning.
```

## Recommended taxonomy file structure

```txt
packages/agent-db-runtime/taxonomies/runtime-taxonomy.v0.1.yaml
packages/agent-db-runtime/taxonomies/value-loop-taxonomy.v0.1.yaml
packages/agent-db-runtime/taxonomies/card-taxonomy.v0.1.yaml
packages/agent-db-runtime/taxonomies/governance-taxonomy.v0.1.yaml
```

## Required taxonomy domains

```txt
lifecycle_status
card_kind
entity_kind
identity_type
role_type
relationship_type
responsibility_role
operator_type
skill_type
tool_type
protocol_type
interface_type
api_type
evidence_type
artifact_type
knowledge_state
memory_type
risk_level
verification_state
certification_state
accreditation_state
recognition_state
qualification_state
eligibility_state
recommendation_state
selection_state
rejection_reason_type
output_type
outcome_type
value_type
learning_type
improvement_type
evaluation_type
score_dimension
rating_scale
review_state
incident_severity
sla_state
policy_type
control_type
obligation_type
assurance_type
insurance_type
```

## Taxonomy record shape

```yaml
id: lifecycle_status.active
value: active
displayName: Active
description: Object is active and available for use.
status: active
version: 0.1.0
owner: registry-platform
aliases: []
deprecated: false
replacedBy: null
externalMappings: []
```

## Relationship to cards

Taxonomies should have cards.

```txt
Taxonomy
  has TaxonomyCard

TaxonomyTerm
  has optional TermCard
```

## Relationship to schema

Schemas should reference taxonomies through either:

```txt
string field + validation rule
```

or:

```txt
record reference to taxonomy_term
```

The portable default is:

```txt
string field with documented taxonomy reference
```

The strict database-native option is:

```txt
record<taxonomy_term>
```

## Final rule

```txt
Do not add Phase 1 runtime schema until controlled taxonomy values exist for Output, Outcome, ValueRealization, Learning, Improvement, Evidence, Status, and Trust.
```
