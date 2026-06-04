# AgentQL Langium Decision

## Decision

AgentQL will use Langium for grammar-driven authoring, parser generation, typed AST generation, validation, editor tooling, and code generation.

Langium is accepted because it follows the Xtext language-engineering model while using the TypeScript/Node ecosystem.

## Runtime Boundary

AgentQL is not a runtime business-logic layer.

AgentQL compiles to SurrealDB and SurrealML artifacts:

- SurrealDB schema
- SurrealDB custom functions
- SurrealDB custom API endpoints
- SurrealDB events
- SurrealDB permissions
- SurrealDB seed records
- SurrealML inference bindings

## Quorum Record

The product owner approved using Langium for AgentQL in this thread.

This approval covers the initial AgentQL package, initial grammar, and initial example vocabulary.

Future grammar, vocabulary, ontology, taxonomy, naming, semantic-model, relation, entity-type, edge-type, JSON-LD context, generated SurrealQL, or SurrealML binding changes require quorum consensus.

## Final Rule

AgentQL may define language. SurrealDB and SurrealML execute the runtime.
