# AGenNext Agent Ecosystem Architecture Map

This is the canonical map for the AGenNext agent platform ecosystem.

## Top-Level Product Assembly

```text
Agent-Platform
  → assembles, configures, deploys, and launches the customer-facing platform
```

## Customer-Facing Surfaces

```text
Agent-Site
  → public website, docs, marketing, use-case pages

Agent-Dashboard
  → authenticated control plane, status, approvals, observability views

Agent-Chat
  → conversational chat UI: real-time agent interaction, multi-turn dialogue

Agent-Knowledge
  → enterprise source-to-artifact intelligence product API and domain logic

Agent-Insights
  → trusted, actionable business insights (Gartner-style intelligence output)
  → evidence-backed, evaluated, sourced intelligence reports and recommendations
```

## Agent Runtime and Execution

```text
Agent-Framework
  → AGenNext's core runtime framework
  → execution engine, memory system, state lifecycle, tool coordination
  → multi-tier memory: working, episodic, semantic (GraphRAG + RAG), procedural
  → A2A handoff protocol, human-in-the-loop gates, checkpointing

Agent-Frameworks
  → adapters to external frameworks (LangGraph, CrewAI, AutoGen, etc.)
  → Agent-Framework consumes these adapters; never depends on them directly

Agent-Kernel
  → native and low-level execution layer
  → sandboxed process management, kernel-level agent execution
  → Agent-Framework delegates native execution to Agent-Kernel

Agent-Team
  → multi-agent teams: reusable, goal-oriented, composable
  → team types: product team, project team, event team, domain-specific team
  → owns A2A handoff behavior and team composition contracts

Agent-Graph
  → artifact schemas and graph-shaped artifact contracts

```

## Governance and Operating Contracts

```text
Agent-Objective
  → objective contracts and completion policy

Agent-Blueprint
  → versioned team/system blueprints

Agent-Constraints
  → reusable policy constraint definitions and guardrail specifications

AAGFE (AGenNext Agent Governance and Framework Enforcement)
  → runtime governance enforcement engine
  → the most important governance component: nothing runs without passing AAGFE
  → evaluates Agent-Constraints (internal guardrails) and Agent-Policies (org policies)
  → writes enforcement decisions and audit trail to SurrealDB

Agent-Policies
  → OPA-compatible (Open Policy Agent / Rego) policy definitions
  → set by enterprise organizations for their own governance rules
  → current: evaluated by OPA engine, enforcement and audit records go to SurrealDB via AAGFE
  → planned migration: move policy evaluation to SurrealQL-native
    (SurrealDB DEFINE TABLE PERMISSIONS, DEFINE FUNCTION, native rule evaluation)
  → goal: all policy evaluation runs inside SurrealDB, eliminating OPA dependency

Agent-Secrets
  → secrets, keys, credential ownership, rotation, and environment-specific handling

Agent-Environment
  → dev/test/staging/prod environment contracts

Agent-Decisions
  → complete decision log: architectural and operational decisions with rationale

Agent-Maturity
  → maturity and production/enterprise readiness model
```

## Agent Cognition and Epistemic Systems

```text
Agent-Belief
  → epistemic layer: the agent's maintained world model and belief state
  → based on BDI (Belief-Desire-Intention) architecture
  → agents form, hold, update, and revise beliefs based on evidence and observation
  → enables reasoning under uncertainty, not just reactive pattern matching
  → belief updating: Bayesian revision, evidence integration, conflict resolution
  → connects to Agent-Framework memory (semantic/episodic) and Agent-Trust (evidence)
  → theoretical foundations:
      - Rao & Georgeff: BDI Agents: From Theory to Practice (IEEE 565454)
      - arXiv 2412.07981
      - O'Reilly: The Next Leap for AI: Why Agents Need to Learn to Believe

Agent-Mind
  → agent cognitive architecture: the full mental model of an agent
  → integrates belief state (Agent-Belief), working memory, reasoning, and intent
  → the "mind" as a unified cognitive object: what the agent knows, thinks, and intends
  → mind-aware multi-agent coordination: agents model each other's minds
    to improve team-level decision-making (Meta M3RL)
  → minds as AI entities that reason over any connected data source (MindsDB Minds pattern)
  → supports real-world autonomous agent applications end-to-end
  → references:
      - arXiv 2508.00401
      - Agent Mind: Autonomous Real-World Applications (Amazon ebook)
      - MindsDB Minds: https://docs.mindsdb.com/minds
      - Meta M3RL: Mind-Aware Multi-Agent Management Reinforcement Learning
  → relationship to other repos:
      Agent-Belief → epistemic state (what the agent holds as true)
      Agent-Mind   → full cognitive architecture (belief + desire + intention + reasoning)
      Agent-Team   → consumes Agent-Mind's mind-aware coordination for multi-agent handoffs
      Agent-Fabric → Agent-Mind can reason over any data source via Agent-Fabric

Agent-Context  [CORE IP — proprietary to AGenNext]
  → dynamic, agent-driven context management
  → context has no fixed definition or schema — the agent decides entirely
  → context can be anything: a world war, a child crying, a smell, a past trip,
    a line of code, a market shift, an emotion — no predefined boundary
  → the agent autonomously determines what is relevant and what enters context
  → context size expands and contracts based on task complexity and type:
      code task    → larger context: repo state, secrets, file history, dependencies
      travel task  → temporal context: a year-old trip to the same place is now current
      emotional    → situational context: environmental and relational signals
  → context is not a fixed window — it is a living, open-ended, task-aware surface
  → temporal relevance: dormant memories activate when task conditions match
  → context switch detection: agent detects domain shifts and auto-clears stale context
  → cost-aware: context size is a cost lever integrated with Agent-FinOps
  → privacy boundary: context visible only to the agent and AGenNext (platform provider)
    not accessible to end users — this is core proprietary IP
  → connects to:
      Agent-Framework → context feeds the execution engine's working memory
      Agent-Belief    → belief state informs what the agent deems contextually relevant
      Agent-Mind      → the cognitive layer that decides context composition
      Agent-Memory    → retrieval source for context candidates

Agent-Cognitive-Guard
  → cognitive safety layer (see Security section)
```

## Capability, Model, and Research

```text
Agent-Skills
  → reusable skill/capability registry

Model-Router
  → model/provider routing under constraints and budgets

model-repository
  → model storage, versioning, and registry

Agent-Speech
  → speech-to-text and text-to-speech capability
  → voice input and output for any agent interaction surface

Agent-Research
  → evidence gathering and research-to-decision traceability

Agent-Bench
  → reproducible benchmark task definitions and benchmarking runs

Agent-Eval
  → evaluation rubrics, CLEAR scoring, and quality gates
```

## Integrations and Data Fabric

```text
Agent-Connect
  → integration layer: connects agents to any external system
  → CRMs, ERPs, databases, APIs, webhooks, data sources

Agent-Fabric
  → data fabric, identity fabric, skills and tools fabric
  → unified fabric layer: weaves data sources, identities, skills, and tools
    into a coherent surface agents can traverse
```

## Product Output Surfaces

```text
Agent-Letters
  → personalized newsletters: agent-generated, personalized content delivery

Agent-Insights
  → trusted, actionable business intelligence (Gartner-style)
  → evidence-backed, evaluated, sourced intelligence reports
```

## Security and Runtime Protection

```text
Agent-Guard
  → runtime protection layer: antivirus-equivalent for agent execution
  → prompt injection detection and blocking
  → malicious input scanning and sanitization
  → runtime threat detection (code execution, data exfiltration attempts)
  → active protection at the execution boundary, not just policy evaluation

Agent-Cognitive-Guard
  → cognitive safety layer: protects agent reasoning quality
  → hallucination detection and flagging
  → reasoning bias detection
  → adversarial prompt resistance
  → confidence threshold enforcement

AAGFE
  → governance enforcement (see Governance section)

Note on boundaries:
  Agent-Guard     → runtime threats from outside (what tries to harm the system)
  Agent-Cognitive-Guard → reasoning failures from inside (what degrades output quality)
  AAGFE           → governance violations (what breaks policy)
```

## Review, Trust, and Community

```text
Agent-Review
  → review mechanics, findings, and recommendations
  → does not own final platform accept/reject (Agent-Platform owns that)

Agent-Trust
  → provenance, evidence, traceability, and trust contracts

Agent-Community
  → community influence: open source community, contributor workflows,
    community signals, feedback loops
```

## Telemetry, Analytics, Cost, and Operations

```text
Agent-Monitor
  → real-time monitoring, traces, logs, correlation IDs, observability tooling

Agent-Traces
  → semantic trace contracts and trace schema ownership

Agent-Analytics
  → events, metrics, trends, and improvement loops

Agent-FinOps
  → cost governance, usage attribution, budgets, and unit economics

Agent-deploy
  → CI/CD, deployment, monitoring, rollback, post-production operations
```

## Deployment Stack

```text
Local development
  → Podman Compose preferred
  → Docker Compose compatible fallback

First always-on environment
  → VPS + MicroK8s

Later scale path
  → managed Kubernetes or larger MicroK8s cluster
```

## Runtime Flow

```text
User / Agent-Chat / Agent-Dashboard
  → Agent-Knowledge API
  → Agent-Framework (execution engine + memory)
  → Agent-Kernel (native execution where needed)
  → Agent-Team (agents)
  → Agent-Frameworks (external runtime adapters if used)
  → SurrealDB runtime state
  → Agent-Monitor / Agent-Traces / Agent-Trust / Agent-FinOps
  → Agent-Dashboard / Agent-Chat visibility
  → Human approval
```

## Source-to-Artifact Product Flow

```text
source material
  → ingestion / freshness check
  → lossless storage in SurrealDB where possible
  → extraction and indexing
  → GraphRAG: entity/relationship extraction, knowledge graph build
  → objective creation
  → agent team execution (Agent-Framework orchestrates)
  → model routing under constraints and budgets (Model-Router)
  → artifact generation
  → evaluation (Agent-Eval)
  → trust/provenance report (Agent-Trust)
  → analytics and FinOps attribution
  → Agent-Insights: distill into actionable intelligence
  → dashboard review (Agent-Dashboard)
  → human approval
```

## Core Principles

```text
Agent-Platform assembles.
Agent-Knowledge delivers product value.
Agent-Insights delivers trusted intelligence.
Agent-Team executes objectives.
Agent-Framework runs the core runtime and memory.
Agent-Kernel handles native execution.
Agent-Frameworks adapts to external frameworks.
AAGFE enforces governance at runtime.
Agent-Constraints defines the policies.
Agent-Environment defines where.
Agent-Secrets protects credentials.
Agent-deploy deploys and operates.
Agent-Monitor observes in real time.
Agent-Traces owns the semantic trace model.
Agent-FinOps controls cost.
Agent-Trust proves evidence.
Agent-Eval proves quality.
Agent-Review provides review findings.
Agent-Decisions records all decisions.
Agent-Analytics improves over time.
Agent-Community connects the ecosystem.
Agent-Speech enables voice interaction.
Agent-Connect integrates everything external.
Agent-Fabric unifies data, identity, skills, and tools.
```

## Research and Future Repos (Not Currently Part of Platform)

```text
Agent-World
  → autonomous multi-agent evolution for open-ended discovery
  → based on Microsoft Research CORAL theory
  → agents evolve, self-organize, and discover emergent knowledge without
    predefined objectives
  → status: research — not integrated into Agent-Platform
  → reference: CORAL: Towards Autonomous Multi-Agent Evolution for Open-Ended Discovery
```

## Final Rule

Each repository owns exactly one major responsibility.

If a responsibility is shared, define the boundary explicitly before implementation.
