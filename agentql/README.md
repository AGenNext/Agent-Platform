# AgentQL

AgentQL is the AGenNext language for declaring agent runtime vocabulary, ontology, policies, APIs, beliefs, mind state, constitution rules, and SurrealDB-owned business behavior.

AgentQL uses Langium for grammar, parser, typed AST, validation, editor tooling, and code generation. Langium follows the Xtext language-engineering model while using the TypeScript/Node ecosystem.

## Runtime Rule

AgentQL is an authoring language. The runtime target is SurrealDB and SurrealML.

AgentQL definitions must compile into SurrealDB schema, functions, events, permissions, APIs, records, or SurrealML inference bindings. AgentQL must not create a second business-logic layer.

## Quorum Approval

Initial AgentQL/Langium adoption is quorum-approved by the product owner in this thread.

Future changes to AgentQL grammar, vocabulary, ontology, taxonomy, naming, semantic meaning, generated SurrealQL, or SurrealML bindings require quorum consensus before implementation.

## Files

- `src/language/agentql.langium` - AgentQL grammar.
- `examples/platform.agentql` - initial platform vocabulary sample.
- `langium-config.json` - Langium generation config.

## Commands

Install dependencies before running commands:

```bash
npm install
npm run langium:generate
npm run typecheck
```
