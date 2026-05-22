# Agent-Framework Specification

Agent-Framework is AGenNext's core runtime framework. It owns the execution engine, memory system, state lifecycle, tool coordination, and A2A handoff model. It is not a wrapper around any external framework — it is the platform brain.

Agent-Frameworks (separate repo) provides optional adapters to external frameworks (LangGraph, CrewAI, AutoGen). Agent-Framework may consume those adapters but does not depend on any external framework directly.

## Responsibilities

```text
Execution engine
  → objective and task lifecycle
  → agent orchestration
  → parallel and sequential execution

Memory system
  → working memory, episodic memory, semantic memory, procedural memory
  → SurrealDB-backed persistence for all durable memory tiers

Knowledge retrieval
  → standard RAG (vector similarity)
  → GraphRAG (knowledge graph + community summaries)
  → hybrid retrieval combining both

Tool coordination
  → tool registration, invocation, result integration
  → error handling and retry policy

A2A handoffs
  → agent-to-agent context passing and handoff contracts
  → result aggregation across agent team

Human-in-the-loop
  → approval gates
  → intervention and escalation points
  → pause/resume lifecycle

State management
  → SurrealDB checkpointing
  → run history and recovery
  → durable execution state

Observability hooks
  → span and trace emission (Agent-Monitor)
  → event hooks for Agent-Analytics
  → cost attribution hooks for Agent-FinOps

Adapter interface
  → consumes Agent-Frameworks adapters
  → isolates external framework dependencies behind adapter boundary
```

## Memory Architecture

Agent-Framework implements a four-tier memory model backed by SurrealDB.

```text
Working memory
  → in-context state during active task execution
  → short-lived, scoped to a single run
  → stored in SurrealDB run record while active

Episodic memory
  → task history, conversation history, prior run outcomes
  → durable, queryable across runs
  → SurrealDB: objective records, task records, A2A handoff records

Semantic memory
  → knowledge, facts, extracted entities and relationships
  → vector embeddings for similarity search
  → knowledge graph for relationship traversal (GraphRAG)
  → SurrealDB: vector index + graph relations

Procedural memory
  → skills, tool patterns, reusable execution templates
  → sourced from Agent-Skills registry
  → SurrealDB: skill/capability records
```

### Memory Retrieval

```text
Standard RAG
  → embed query → vector similarity search → retrieve chunks → augment prompt

GraphRAG
  → extract entities and relationships from source material
  → build knowledge graph in SurrealDB
  → detect communities of related nodes
  → generate community summaries at multiple levels
  → global queries: summarize across entire corpus via community summaries
  → local queries: traverse graph neighborhood from anchor entity
  → hybrid: combine vector recall with graph traversal

Memory lookup on each agent step
  → working memory: direct state access
  → episodic: query recent runs and prior outcomes
  → semantic: vector + graph retrieval against knowledge base
  → procedural: retrieve relevant skills from Agent-Skills
```

## Execution Model

```text
Objective received
  → parse objective contract (Agent-Objective)
  → load blueprint if applicable (Agent-Blueprint)
  → apply constraints (Agent-Constraints)
  → decompose into tasks
  → assign tasks to agents (Agent-Team)
  → execute tasks (parallel or sequential per blueprint)
  → coordinate tool use on each step
  → persist state to SurrealDB on each checkpoint
  → collect results
  → trigger evaluation hook (Agent-Eval)
  → trigger trust hook (Agent-Trust)
  → emit cost attribution event (Agent-FinOps)
  → emit trace spans (Agent-Monitor)
  → return result package
```

## A2A Handoff Model

```text
Agent produces output
  → validate output against handoff contract
  → package context: result, trace ID, confidence, source references
  → emit handoff event to Agent-Monitor
  → pass to next agent or return to orchestrator

Receiving agent
  → load handoff package into working memory
  → query episodic memory for prior context from same objective
  → proceed with task
```

## Human-in-the-Loop Gates

```text
Pre-execution approval
  → objective flagged as requiring human approval before start
  → pause execution, notify Agent-Dashboard
  → resume on approval or abort on rejection

Mid-execution intervention
  → agent signals low confidence or policy conflict
  → escalate to Agent-Dashboard for human decision
  → pause affected task branch, continue independent branches

Post-execution approval
  → result package surfaced to Agent-Dashboard
  → human approves artifact before delivery
  → approval record written to SurrealDB and Agent-Trust
```

## State and Checkpointing

```text
On every task completion
  → write task record to SurrealDB
  → update objective progress record

On agent error or timeout
  → write failure record with reason
  → load last checkpoint
  → retry from checkpoint or escalate

On objective completion
  → finalize run record
  → write evaluation, trust, and FinOps summary references
  → mark objective terminal state
```

## Observability Contract

Agent-Framework emits the following to Agent-Monitor on every run:

```text
objective_started
  → objective ID, blueprint ID, agent team composition, timestamp

task_started / task_completed / task_failed
  → task ID, agent ID, duration, tool calls, token usage

memory_read / memory_write
  → memory tier, query, result count, latency

handoff_emitted
  → from agent, to agent, context size, confidence

approval_requested / approval_received
  → gate type, requestor, approver, decision, duration

objective_completed / objective_failed
  → final status, duration, cost, evaluation reference, trust reference
```

## Adapter Interface (Agent-Frameworks)

Agent-Framework does not import LangGraph, CrewAI, or AutoGen directly. It exposes an adapter interface that Agent-Frameworks implements.

```text
AgentFrameworkAdapter interface
  → execute_graph(graph_definition, state) → result
  → stream_events(graph_definition, state) → event_stream
  → checkpoint_state(run_id, state) → checkpoint_id
  → restore_state(checkpoint_id) → state
```

Adapters available through Agent-Frameworks:

```text
LangGraphAdapter  → wraps LangGraph StateGraph execution
CrewAIAdapter     → wraps CrewAI crew execution
AutoGenAdapter    → wraps AutoGen conversation execution
```

## What Agent-Framework Does Not Own

```text
Agent-Team     → agent definitions, roles, and A2A behavior contracts
Agent-Skills   → skill/capability registry content
Agent-Graph    → artifact schemas
Agent-Eval     → evaluation rubrics and scoring
Agent-Trust    → provenance and trust records
Agent-FinOps   → cost governance and billing
Agent-Monitor  → trace storage and observability tooling
Agent-Kernel   → native/low-level execution and sandboxing
```

Agent-Framework calls into these systems via contracts; it does not own them.

## Current Status

Agent-Framework is incomplete. Required features not yet built:

- [ ] Memory system (all four tiers)
- [ ] SurrealDB memory persistence
- [ ] GraphRAG pipeline (entity extraction, graph build, community detection, query)
- [ ] Standard RAG pipeline (vector embed, search, retrieval)
- [ ] Objective execution engine
- [ ] Task decomposition
- [ ] A2A handoff protocol
- [ ] Human-in-the-loop gate mechanics
- [ ] Checkpointing and recovery
- [ ] Observability hook emissions
- [ ] Adapter interface definition
- [ ] Agent-Frameworks adapter consumption
- [ ] Agent-Kernel integration for native execution
