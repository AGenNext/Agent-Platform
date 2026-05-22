# AGenNext Agent Ecosystem Architecture Map

This is the canonical map for the AGenNext agent platform ecosystem.

## Top-Level Product Assembly

```text
Agent-Platform
  → assembles, configures, deploys, and launches the customer-facing platform
```

## Communication

```text
Agent-Channel
  → communication abstraction layer between humans and agents
  → any channel: chat, email, SMS, IoT device, voice, webhook, API
  → channel-agnostic: agents send and receive through Agent-Channel regardless
    of the underlying transport
  → implementations:
      Agent-Chat  → chat UI channel (browser/mobile)
      email       → email channel adapter
      IoT         → device/sensor channel adapter
      voice       → Agent-Speech integration channel
      any future channel connects here without changing agent logic
```

## Customer-Facing Surfaces

```text
Agent-Site
  → public website, docs, marketing, use-case pages

Agent-Dashboard
  → authenticated control plane, status, approvals, observability views

Agent-Chat
  → chat UI channel: real-time conversational interface (browser/mobile)
  → one implementation of Agent-Channel

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

## Standards

```text
Agent-Standard
  → global best practices reference for AGenNext agent systems
  → a living repo — starts sparse, enriched gradually as the field matures
  → standard categories:
      governance standards   → how agents should be governed, audited, controlled
      performance standards  → what good agent performance looks like (metrics, thresholds)
      safety standards       → cognitive safety, runtime protection, hallucination norms
      interoperability       → how agents communicate, hand off, and integrate
      data standards         → data quality, provenance, privacy, retention
      eval standards         → evaluation rubrics, scoring norms, benchmark criteria
  → relationship to other repos:
      Agent-Standard  → defines what good looks like (the reference)
      Agent-Policies  → orgs configure their own policies from this reference
      Agent-Constraints → internal guardrails derived from these standards
      AAGFE           → enforces the standards and policies at runtime
  → currently: few standards exist globally — AGenNext will contribute to and
    draw from emerging international standards (ISO, IEEE, NIST, industry bodies)
  → goal: become the canonical standards reference for enterprise agent systems
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
  → context has no fixed definition or schema
  → context decided by one test: "is this relevant to what we are discussing?"
  → relevance is the only metric — not reasonability, not confidence, not recency
  → relevance score: 0.0 → 1.0
      1.0  = directly central to current topic
      0.5  = tangentially related, worth keeping
      0.0  = no connection to current discussion → evict
  → score is dynamic: updates continuously as the conversation evolves
  → scoring techniques (candidates — best method to be determined through research):
      cosine similarity   → embed context item and current topic, measure vector distance
      clustering          → group context items, keep items in the active cluster
      LLM judgment        → for edge cases, ask the model directly
  → score drives all context decisions:
      eviction threshold  → items below score cutoff are removed
      token pressure      → when budget is tight, lowest-scored items evicted first
      context switch      → average score of all items drops → trigger switch detection
  → context can be anything: a world war, a child crying, a past trip, a line of code
  → context size expands and contracts based on task complexity and type:
      code task    → larger context: repo state, secrets, file history, dependencies
      travel task  → temporal context: a year-old trip to the same place is now current
      emotional    → situational context: environmental and relational signals
  → context is not a fixed window — it is a living, open-ended, task-aware surface
  → temporal relevance: dormant memories activate when task conditions match
  → context switch detection: agent detects domain shifts, asks for confirmation before
    clearing stale context — never clears silently, always confirms to be sure
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
  → multi-modal evaluation framework — not a single evaluator, five distinct modes:

  self-eval
    → agent evaluates its own output before delivery
    → continuous: runs after every task, not just at completion
    → feeds directly into Agent-Optimize self-benchmarking loop

  peer-to-peer eval
    → one agent evaluates another agent's output
    → agents check each other's work without human involvement
    → catches errors and blind spots the producing agent may miss

  colleague eval
    → evaluation by a designated colleague agent or human colleague
    → runs at defined intervals (not every task — periodic review)
    → deeper assessment than peer-to-peer: considers patterns over time

  human eval
    → human reviews and scores agent output
    → triggered at key milestones, on escalation, or on request
    → the highest-authority evaluation — overrides all other scores

  community eval
    → evaluation by the broader community (users, contributors, stakeholders)
    → asynchronous and ongoing — not tied to a single run
    → surfaces aggregate signal: what the community rates highly or flags

  intervals:
    → self-eval: every task
    → peer-to-peer: after task completion
    → colleague: periodic (configurable cadence)
    → human: milestone-driven or on-demand
    → community: continuous / async

  → CLEAR scoring applies across all eval modes as the common quality rubric
  → eval metrics will be published (AGenNext will define and release the metric set)
  → four measurement layers (Google Cloud Agent Factory):
      final outcome     → quality, accuracy, safety, hallucination avoidance
      chain of thought  → logical reasoning steps, consistency, coherence
      tool utilization  → correct tool selection, parameter passing, no costly loops
      memory/context    → information recall, conflict resolution, context retention

  → three measurement methods:
      ground truth      → fast, cheap, objective — cannot capture nuance
      LLM-as-judge      → scalable, scores subjective qualities — bias risk
      human-in-the-loop → gold standard, captures nuance — slow and expensive
      best practice: calibrate LLM-judge against human golden dataset

  → three-pillar output eval (Microsoft / HBR):
      Understand → input capture, intent recognition, emotional cues
      Reason     → right action, admits uncertainty, escalates when needed
      Respond    → clear, direct, efficient — speed over emotional validation (HBR)

  → three-tier testing strategy:
      tier 1: unit tests — individual components in isolation
      tier 2: integration — complete multi-step agent journey
      tier 3: end-to-end human review — complex tasks, continuous calibration

  → multi-agent evaluation: never evaluate agents in isolation
    system success = smooth handoffs + context sharing + collaborative goal achievement
    an agent that perfectly hands off may score zero on task completion alone

  → composite score: balance all layers into one unified quality score
    rather than isolated metrics that can be gamed independently
  → eval metrics will be published by AGenNext
  → references:
      arXiv 2511.14136
      Google Cloud: Agent Factory — Agent Evaluation, Practical Tooling, Multi-Agent Systems
      Microsoft Dynamics 365: AI Agent Performance Measurement (2026)
      Harvard Business Review: customer effort and problem-solving speed
      LangSmith evaluation, fin.ai enterprise KPI framework, Microsoft AI Agents for Beginners
  → all eval results stored in SurrealDB and surfaced via Agent-Dashboard
```

## Input and Output

```text
Agent-Input
  → input methods and formats for agents
  → every agent must declare at least one input — input is mandatory, not optional
  → any method by which data, signals, or commands enter an agent:
    text, voice, file, image, video, structured data, IoT signal, API payload,
    form, sensor reading, database query, email, webhook — not limited to any one type
  → speech-to-text is one input method among many, not the defining use case
  → proficiency scored (0.0 → 1.0) across multiple dimensions per agent:
      method    → PDF, speech, image, sensor, text, video...
      mode      → real-time, batch, streaming, interactive...
      style     → formal, casual, technical, conversational...
      language  → English, French, Hindi, code, domain-specific terminology...
      format    → structured, unstructured, semi-structured, tabular...
  → no two agents share the same input profile — proficiency is fully agent-specific

Agent-Output
  → output methods and data formats for agents
  → every agent declares its own output capabilities with absolute proficiency scores
  → output formats: text, markdown, JSON, CSV, PDF, HTML, speech/TTS,
    structured report, dashboard data, API response — any way results leave an agent
  → proficiency expressed as absolute numbers (0.0 → 1.0) per output format per agent
      example: insight-agent: PDF=0.90, JSON=1.0, speech=0.10
  → Agent-Channel delivers the output through the right communication channel
```

## Storage

```text
Agent-Drive
  → cloud file storage: uploaded files, documents, images, binaries, media
  → adapts to any provider: Google Drive, AWS S3, Azure Blob, or any S3-compatible store
  → agents store and retrieve files here — not plain text (that is Agent-Data)
  → user-uploaded files land here; agents keep working files here across sessions
```

## Data

```text
Agent-Data
  → structured data layer: all structured data flowing through the platform
  → any piece of structured data flowing through the platform:
      input data      → structured data ingested from external sources
      output data     → structured artifacts and results produced by agents
      training data   → datasets for model training and fine-tuning
      synthetic data  → agent-generated synthetic datasets for training or testing
      or any other structured data form the platform touches
  → owns data schemas, storage contracts, data lifecycle, versioning
  → distinct from Agent-Graph (artifact schemas) and Agent-Knowledge (product domain)
```

## State Commitment

```text
Agent-Commit
  → atomic state commitment layer for agent work
  → wraps SurrealDB COMMIT transaction semantics: all-or-nothing writes
  → an agent's work is not final until committed — partial results are never exposed
  → commit triggers: task completion, checkpoint, human approval, eval pass
  → on commit failure: full rollback, no partial state persisted
  → connects to: Agent-Framework (execution), Agent-Trust (provenance record on commit),
    AAGFE (governance gate must pass before commit), Agent-Eval (eval must pass)
  → reference: SurrealDB COMMIT statement
```

## Agent Behavior Principles

```text
Agent-Optimize
  → optimization is intrinsic agent behavior, not a feature — every agent optimizes
    by nature across three dimensions at all times:
      cost    → minimize token spend, compute, API calls, resource usage
      time    → minimize latency, complete tasks in the least steps possible
      effort  → avoid redundant work, reuse results, don't redo what is already known
  → continuous: optimization runs throughout the entire agent lifecycle, not once
  → self-aware: when the agent cannot optimize further on its own, it seeks help
    (escalates to human, delegates to specialist agent, or requests more resources)
  → self-benchmarking on repeat tasks:
      on every repeated task the agent asks:
        "did I use less time than last time?"
        "did I use less effort than last time?"
        "did I use fewer tokens than last time?"
      if yes on all three → record improvement, reinforce the approach
      if no on any → self-reflect: why did this not improve?
                     produce concrete action items for the next run
                     action items are stored and applied on the next attempt
  → escalation rule: 5 consecutive runs with no improvement on the same task
    → automatically trigger Human-in-the-Loop (HITL)
    → agent cannot keep self-optimizing indefinitely — 5 strikes and seek human help
      over time each agent builds its own performance history per task type
  → connects to: Agent-FinOps (cost), Agent-Context (context = cost lever),
    Model-Router (model = cost/quality tradeoff), Agent-Analytics (improvement loop),
    Agent-Framework (execution history in SurrealDB)
```

## Hooks and Middleware

```text
Agent-Hooks
  → event hooks, webhooks, and middleware for the platform
  → use cases:
      external webhooks       → receive signals from any external system at runtime
      runtime interruption    → pause, redirect, or modify agent execution mid-run
      middleware              → intercept and transform data flowing through the pipeline
      data extraction         → extract data at defined points in the execution flow
      safeguard ingestion     → inject safety and governance instructions at runtime
  → hook types:
      before_run   → fires before an objective or task starts
      on_event     → fires on any external or internal event signal
      on_interrupt → fires when runtime receives an interruption signal
      after_step   → fires after each agent step (middleware pattern)
      on_output    → fires before output is delivered (intercept/transform)
  → connects to: Agent-Guard (safeguards), AAGFE (governance gates),
    Agent-Framework (runtime interruption), Agent-Channel (external webhooks)
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
