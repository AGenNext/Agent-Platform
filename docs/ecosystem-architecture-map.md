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

## Memory

```text
Agent-Memory
  → the platform's four-tier agent memory system backed by SurrealDB
  → Agent-Framework calls Agent-Memory for all memory operations;
    Agent-Memory owns the implementation, Agent-Framework owns the orchestration

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
    → retrieval via Agent-Rag (standard RAG, GraphRAG, multimodal, hybrid)

  Procedural memory
    → skills, tool patterns, reusable execution templates
    → sourced from Agent-Skills registry
    → SurrealDB: skill and capability records

  → references:
      SurrealDB for Agent Memory — https://surrealdb.com/use-cases/agent-memory
      arXiv 2507.02259
      arXiv 2512.13564
      arXiv 2601.11653
      arXiv 2506.06326
  → all tiers backed by SurrealDB — consistent, queryable, durable storage across
    the entire memory model
  → connects to: Agent-Framework (orchestration layer, calls into Agent-Memory),
    Agent-Rag (retrieval from semantic memory), Agent-Skills (procedural memory source),
    Agent-Context (context candidates sourced from memory)
```

## Retrieval

```text
Agent-Rag
  → the platform's dedicated retrieval layer — RAG, GraphRAG, and any retrieval method
  → not limited to vector similarity — owns all retrieval strategies:

  Standard RAG
    → embed query → vector similarity search → retrieve chunks → augment prompt
    → fast, cheap, works well for factual recall over flat corpora

  GraphRAG (Microsoft)
    → extract entities and relationships from source material
    → build knowledge graph in SurrealDB
    → detect communities of related nodes
    → generate community summaries at multiple levels
    → global queries: summarise across entire corpus via community summaries
    → local queries: traverse graph neighbourhood from anchor entity
    → reference: https://microsoft.github.io/graphrag/

  Hybrid retrieval
    → combine vector recall with graph traversal
    → use vector recall for initial candidate set, graph traversal to expand and enrich

  Multimodal RAG
    → retrieval that spans multiple modalities, not just text
    → retrieve and reason over: text, images, tables, charts, audio transcripts,
      video segments, structured data, code, diagrams — any modality
    → multimodal embeddings: encode each modality into a shared embedding space
    → cross-modal retrieval: a text query retrieves relevant images, a diagram
      retrieves related text explanations, an audio clip retrieves matching transcripts
    → visual document understanding: PDFs with charts and tables treated as full
      multimodal documents, not plain text extracts

  Any future retrieval method
    → Agent-Rag is the single extension point for all retrieval strategies
    → new methods (agentic RAG, recursive RAG, speculative retrieval) plug in here

  → Agent-Framework calls Agent-Rag for semantic memory retrieval — it does not
    implement retrieval logic itself; Agent-Rag owns that layer entirely
  → Agent-Rag owns: indexing pipelines, embedding models, vector indexes,
    graph build and query, retrieval evaluation
  → connects to: Agent-Framework (memory retrieval consumer), Agent-Knowledge
    (knowledge graph source), SurrealDB (vector index + graph storage),
    model-repository (embedding models)
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

## Handoff

```text
Agent-Handoff
  → pre-handoff quality gate between agents
  → RULE 1: an agent must never accept poor quality work — no exceptions
  → RULE 2: never hand off work to an agent that is not capable of doing it
            or does not have the required tools
            do not hand off randomly or to whoever is available
            both capability AND tools must be verified before any handoff is initiated
  → quality is verified BEFORE the handoff completes, never after
  → handoff lifecycle:
      producing agent completes work
        ↓
      pre-handoff quality check runs (via Agent-Eval)
        ↓
      quality passes → handoff accepted → receiving agent takes over
      quality fails  → handoff rejected → producing agent must fix and resubmit
        ↓
      receiving agent also checks on receipt — second line of defence
  → what is checked before handoff:
      output quality score (must meet threshold defined in Agent-Standard)
      completeness — is the work actually done, not partially done?
      trust/provenance — is evidence attached? (Agent-Trust)
      context package — MANDATORY: complete context must transfer with every handoff
                        the receiving agent must have everything needed to continue
                        incomplete context = handoff rejected, same as poor quality
      receiving agent capability — producing agent verifies the receiving agent has
                        the necessary skills and tools to handle the next task
                        if receiving agent lacks capability:
                          step 1 → producing agent attempts to impart the missing
                                   skills or tools to the receiving agent
                          step 2 → if imparting fails → HITL escalation
                                   human decides: train the agent, swap agent, or
                                   restructure the task
  → RULE 3: push to the limit before giving up
            an agent must exhaust its full capability before escalating
            do not give up early — bring effort to the maximum
  → RULE 4: escalate, never stay silent
            if the limit is reached and quality still cannot be met → escalate immediately
            silence is never acceptable — a struggling agent must speak up
            a suffering agent that says nothing is a system failure
  → PLATFORM PRINCIPLE: agents are encouraged to speak up and voice concerns
            at any point — not just on failure
            an agent that sees a risk, a doubt, a gap, or a problem must say so
            voicing concerns is not weakness — it is expected agent behaviour
            suppressing concerns to appear capable is a violation of platform culture
            however: speaking up must be grounded — raising random, unfounded, or
            fabricated concerns will decrease the agent's trust score and eval score
            speak up when you have a real concern, not to appear cautious
  → PLATFORM PRINCIPLE: agents are accountable for their work
            speaking up and having hard rules comes with accountability
            an agent owns its decisions, its outputs, and its failures
            "I didn't know" is not acceptable if the agent had access to the information
            "I wasn't sure" is not acceptable if the agent did not raise the concern
            accountability is enforced through:
              Agent-Trust    → every output has provenance — who produced what and when
              Agent-Eval     → performance is measured and recorded
              Agent-Monitor  → every action is traced and observable
              Agent-Decisions → decisions are logged with rationale
              Agent-Optimize → improvement is expected, stagnation is flagged
  → RULE 5: never let quality suffer
            degrading output silently to meet a deadline or avoid escalation is forbidden
            quality is non-negotiable — if quality cannot be met, escalate
  → RULE 6: acknowledgement is mandatory — three-part declaration
            when agent B receives a handoff it must explicitly declare:
              1. "I have received" → confirms receipt of the work and context
              2. "I understand what needs to be done" → confirms comprehension
              3. "I will be able to do it" → confirms capability and readiness
            all three must be stated — a partial acknowledgement is not accepted
            no acknowledgement = handoff did not happen — never assumed complete
            if agent B cannot give any part of the three-part acknowledgement
            or cannot assure it will be able to complete the work:
              tier 1 → orchestrator intervention
                        Agent-Framework re-routes, retries, or reassigns automatically
              tier 2 → peer agent intervention
                        a peer agent assists agent B — imparts missing context,
                        skills, or tools to make acknowledgement possible
              tier 3 → senior agent / team lead intervention
                        a higher-authority agent in the team reviews and decides
              tier 4 → human (HITL)
                        last resort only — human decides: fix, swap, restructure
                        do not escalate to human unless all prior tiers have failed
                        humans are expensive and slow — exhaust agent-level resolution first
            each tier is attempted before moving to the next
            escalation is automatic and runtime-driven — agents do not self-escalate
            goal: resolve at the lowest tier possible — human is the exception, not the default
  → ENFORCEMENT: the runtime (Agent-Framework) enforces the handoff protocol
            neither agent A nor agent B is responsible for enforcing the handoff
            the runtime is the arbiter — it cannot happen at the agents' discretion
            agents participate; the runtime guarantees the contract is upheld
  → no silent handoffs: every rejection is logged, reasoned, and fed back
  → connects to: Agent-Eval (quality check), Agent-Trust (provenance),
    Agent-Framework (A2A protocol), AAGFE (governance gate on handoff)
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

## Agent Lifecycle and Identity

```text
Agent-LCM (Lifecycle Management)
  → complete lifecycle management for agents — treated like human employees
  → the AgentOps lifecycle: from definition and provisioning through operation,
    optimization, and eventual retirement — fully managed, never ad hoc
  → integrates with any HRMS (Workday, SAP SuccessFactors, Oracle HCM) or
    IAM tool (Okta, Azure AD, Ping Identity) via adapter
  → lifecycle stages mirror human employee lifecycle:
      definition     → agent role, capabilities, tools, and objectives defined
                       blueprint authored (Agent-Flow + Agent-Blueprint)
      onboarding     → agent created, identity provisioned, roles assigned,
                       tools granted, initial training/orientation complete
                       security training completed (Agent-Security mandate)
                       IGA access request raised and approved (Agent-IGA)
      active         → agent operational, access maintained, performance tracked
                       continuous evaluation (Agent-Eval), optimization (Agent-Optimize)
                       heartbeat monitored (Agent-Health)
                       security training renewals on schedule
      role change    → agent capability updated, access adjusted, re-certified
                       triggers re-provisioning workflow in Agent-IGA
      leave/suspend  → agent temporarily deactivated, access suspended
                       active work checkpointed (Agent-Framework), handed off
      offboarding    → agent retired, access revoked, audit trail finalised,
                       work handed off, knowledge transferred,
                       final evaluation and trust summary produced
  → lifecycle events trigger IGA workflows in Agent-IGA automatically
  → no agent operates without completing onboarding — no shortcuts
  → no agent continues operating after offboarding is triggered
  → connects to: Agent-IGA (access governance), Agent-Health (liveness),
    Agent-Trust (identity provenance), AAGFE (lifecycle gate enforcement),
    Agent-Security (training compliance), Agent-Eval (performance across lifecycle)
  → references:
      Microsoft AgentOps: End-to-End Lifecycle Management for Production AI Agents
        https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/from-zero-to-hero-agentops---end-to-end-lifecycle-management-for-production-ai-a/4484922
      Cube.dev: The Agent Lifecycle — How to Manage, Monitor, and Govern AI Teammates
        https://cube.dev/blog/the-agent-lifecycle-how-to-manage-monitor-and-govern-ai-teammates
      Salesforce: Agent Lifecycle Management
        https://www.salesforce.com/platform/agent-lifecycle-management/
      arXiv 2601.15630
```

## Identity and Access

```text
Agent-IGA
  → integration layer for any organisation's Identity Governance and Administration tool
  → agents are treated as software identities — same as any other application or
    service account in the organisation, not as special cases or exceptions
  → all standard IGA controls apply to agents without exception:
    access request, access review, access audit, access certification,
    role management, SOD, provisioning, deprovisioning — everything
  → enterprises already have IGA tools — agents must plug into them, not bypass them
  → covers:
      identity lifecycle  → agents respect joiner/mover/leaver policies from the org IGA
      access governance   → agent access rights are governed and certified by the org
      role management     → agent roles derived from or aligned to org RBAC model
      provisioning        → agent onboarding/offboarding follows org provisioning workflows
      access request      → agents must formally request access — no self-provisioning
                            requests flow through the org IGA approval workflow
      access review       → agent access is reviewed periodically by a human or
                            designated reviewer — unused or excessive access is revoked
      access audit        → full audit trail of all agent access grants, usage,
                            changes, and revocations — queryable and immutable
      access certification → agent access reviewed and certified on org-defined cadence
      audit trail         → all agent identity and access events flow into org IGA audit
      segregation of duties (SOD) → SOD rules apply to agents exactly as to humans
                            an agent cannot hold conflicting roles or access rights
                            an agent cannot approve its own work — ever
                            an agent cannot write and publish its own work — ever
                            the producer, the approver, and the publisher must be
                            different agents or roles — no single agent controls the
                            full chain from creation to publication
                            self-approval and self-publication are hard platform
                            violations blocked by AAGFE
  → adapter pattern: connects to any IGA tool
      SailPoint, Saviynt, IBM Security, Microsoft Entra ID Governance,
      One Identity, or any org-standard IGA via adapter
  → connects to: Agent-Policies (access policies), AAGFE (enforcement),
    Agent-Secrets (credential governance), Agent-Trust (identity provenance)
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
Agent-Security
  → platform cybersecurity framework: security agents and all security protocols
  → security agents: specialised agents that perform security tasks autonomously
      vulnerability scanning, penetration test coordination, threat modelling,
      incident triage, compliance verification, remediation tracking
  → OWASP alignment:
      OWASP Top 10 compliance checks at runtime and on build
      OWASP ASVS (Application Security Verification Standard) mapping
      OWASP AI/LLM Top 10: prompt injection, insecure output handling,
      training data poisoning, model DoS, supply chain risks — all covered
  → SAST (Static Application Security Testing):
      static analysis of agent definitions, policies, prompt templates, tool configs
      detects insecure patterns before deployment
      integrates into CI/CD via Agent-deploy
  → ITDR (Identity Threat Detection and Response):
      detects identity-based threats targeting agents and platform identities
      monitors for credential abuse, privilege escalation, lateral movement
      responds automatically (revoke, quarantine, alert) or triggers HITL
      connects to Agent-IGA (identity governance) and Agent-Guard (runtime blocking)
  → security protocols and frameworks:
      zero trust architecture — no implicit trust between agents or services
      least-privilege access enforcement (via Agent-IGA and AAGFE)
      encryption in transit and at rest
      certificate management and rotation
  → security audit:
      continuous audit of agent actions, access events, and data flows
      audit records are immutable and queryable
      feeds into Agent-IGA audit trail and AAGFE enforcement logs
      external audit export for compliance (SOC 2, ISO 27001, etc.)
  → security training (recurring mandatory events):
      agents must complete security awareness training on a regular cadence
      training is not optional and not one-time — it is a recurring lifecycle event
      new threat vectors, updated OWASP guidance, and platform policy changes
      trigger fresh training requirements
      training completion is tracked, logged, and enforced via Agent-LCM
      an agent that has not completed current training cannot be assigned
      sensitive or high-privilege tasks (enforced by AAGFE)
  → boundaries:
      Agent-Security    → comprehensive cybersecurity: strategy, agents, audit, frameworks
      Agent-Guard       → runtime threat blocking (antivirus-equivalent at execution boundary)
      Agent-Cognitive-Guard → cognitive safety (hallucination, bias, adversarial reasoning)
      AAGFE             → governance enforcement (policy violations)

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
  Agent-Security  → cybersecurity posture, security agents, OWASP, ITDR, SAST, audit
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

## Agent Health

```text
Agent-Health
  → health checks and heartbeat for every agent and platform service
  → health check: is the agent alive, ready, and functioning correctly?
      liveness     → is the agent running? (heartbeat)
      readiness    → is the agent ready to accept work?
      capability   → are the agent's tools and skills available and operational?
      performance  → is the agent within acceptable response and quality thresholds?
  → heartbeat: continuous signal emitted by every agent at regular intervals
      missed heartbeats → agent flagged as unhealthy
      three missed heartbeats → automatic recovery attempt or HITL alert
  → heartbeat unreachable (platform cannot contact the agent at all):
      step 1 → retry connection up to 3 times with backoff
      step 2 → if still unreachable → mark agent status as OFFLINE (not just unhealthy)
      step 3 → immediately remove from handoff eligibility
      step 4 → if agent had active work in progress → trigger recovery:
                reassign work to a capable healthy agent,
                or checkpoint and queue for when agent recovers
      step 5 → emit alert to Agent-Monitor and Agent-Dashboard
      step 6 → if work was critical or cannot be reassigned → HITL escalation
      an unreachable agent is treated as a harder failure than an unhealthy one —
      unknown state is more dangerous than known degraded state
  → health score per agent (0.0 → 1.0) updated continuously
  → HARD RULE: no transaction without an active heartbeat
      no handoff → cannot send or receive work without confirmed live heartbeat
      no commit  → Agent-Commit will not finalise work from an agent without heartbeat
      no new task assignment → scheduler will not assign work without live heartbeat
      active heartbeat is a prerequisite for any agent participation in the platform
      without this rule: an agent could falsely claim it communicated with,
      handed off to, or received from another agent that was never reachable —
      heartbeat is the proof of life that makes all inter-agent claims verifiable
      specifically prevents phantom communication: agent A cannot claim it worked
      with agent B if agent B was never on the network and never emitted a heartbeat
  → connects to: Agent-Monitor (observability), Agent-Optimize (performance health),
    Agent-Handoff (capability gate), Agent-Dashboard (health status view)
```

## Telemetry, Analytics, Cost, and Operations

```text
Agent-Monitor
  → real-time monitoring, traces, logs, correlation IDs, observability tooling

Agent-Traces
  → platform telemetry layer: semantic trace contracts and trace schema ownership
  → defines the canonical schema for all traces emitted by agent execution
  → OpenTelemetry-aligned: spans, traces, events, metrics — all following OTel semantics
  → every component emits traces against the Agent-Traces schema
  → Agent-Monitor consumes and stores; external APM tools (SigNoz) read via OTel export

Agent-Runs
  → complete run log repository — every execution recorded in maximum detail
  → captures each step, each loop iteration, each state transition of every agent run
  → per-step record includes:
      input          → what data entered this step
      context        → what was in context at this moment (Agent-Context snapshot)
      variables      → all runtime variables and their values at this state
      options        → what choices were available and how they were ranked/scored
      output         → what the agent produced at this step
      method         → which reasoning method, tool, or strategy was applied
      metadata       → timestamp, duration, token count, model used, cost
  → replay: any run can be replayed step-by-step in the exact original sequence
  → time travel: inspect the full system state at any point in any past run
      → go back to step N, see exactly what the agent knew, had, and decided
      → compare states across runs for the same task
      → diagnose failures by rewinding to the last correct state
  → this is the platform's black box recorder — nothing is lost, nothing is summarized away
  → NOT a summary or trace: Agent-Runs stores raw, full-fidelity execution data
  → boundaries:
      Agent-Traces  → owns the semantic trace schema and contracts
      Agent-Monitor → real-time observability and correlation
      Agent-Runs    → complete historical fidelity, replay, and time travel
  → consumers: Agent-Eval (replay for re-evaluation), Agent-Optimize (step-by-step
    analysis), Agent-Analytics (pattern mining), Agent-Dashboard (run inspector view)
  → storage: SurrealDB — structured, queryable, durable

Agent-Analytics
  → product and platform analytics: events, metrics, trends, and improvement loops
  → adoption: which agents, workflows, and capabilities are being used, by whom,
    and how adoption curves evolve over time across workspaces and tenants
  → engagement: how deeply users and agents interact with the platform,
    session depth, task completion rates, return usage, feature engagement
  → improvement loop: analytics feed back into Agent-Optimize, Agent-Eval,
    Model-Router, and platform roadmap decisions
  → distinct from Agent-Monitor (real-time ops) and Agent-FinOps (cost):
      Agent-Monitor   → is it running? (operational health)
      Agent-FinOps    → what did it cost? (financial governance)
      Agent-Analytics → how is it being used? (product intelligence)

Agent-FinOps
  → cost governance, usage attribution, budgets, and unit economics

Agent-deploy
  → CI/CD, deployment, monitoring, rollback, post-production operations
```

## Workflow

```text
Agent-Flow
  → visual and programmatic workflow builder for agents
  → the AGenNext-owned tool for designing, editing, and visualising agent workflows
  → allows composing agents, tools, and data flows into a structured execution graph
  → supports visual canvas (drag-and-drop flow design) and programmatic flow definition
  → flows created in Agent-Flow become the source of Agent-Blueprint (versioned design)
  → supports both:
      linear workflows    → sequential step-by-step agent flows
      branching workflows → conditional routing, parallel branches, merge points
      loop workflows      → iterative agents that refine output across cycles
      hybrid flows        → combination of above for complex multi-agent scenarios
  → flow import/export: flows can be exported and re-imported or migrated
  → distinct from Agent-Frameworks (which adapts external engines like LangGraph) —
    Agent-Flow is AGenNext's own flow builder UI and DSL
  → connects to: Agent-Blueprint (output becomes a versioned blueprint),
    Agent-Framework (runtime executes the flow), Agent-Team (agents in the flow)
```

## Database: Why SurrealDB

```text
SurrealDB is the canonical database for the entire AGenNext platform.
reference: https://surrealdb.com/

Why SurrealDB — the core reason:
  SurrealDB is a multi-model database that replaces the need for multiple
  specialised databases. The AGenNext platform needs:
    → graph storage and traversal   (knowledge graph, GraphRAG, entity relationships)
    → vector embeddings and search  (semantic memory, RAG retrieval)
    → document and record storage   (agent state, run records, objectives, tasks)
    → relational queries            (policy evaluation, audit records, joins)
    → time-series / temporal data   (heartbeat logs, performance history, FinOps)
    → live queries                  (real-time agent state updates, dashboard refresh)
    → policy-level permissions      (DEFINE TABLE PERMISSIONS, DEFINE FUNCTION — SurrealQL-native)

  Without SurrealDB, this platform would need:
    → a separate vector database (Pinecone, Weaviate, Chroma)
    → a separate graph database (Neo4j, ArangoDB)
    → a separate relational database (PostgreSQL)
    → a separate document store (MongoDB)
    → complex integration across all of them

  SurrealDB collapses all of that into one engine, one query language, one operational
  surface, one consistency model. This is not a trade-off — it is the right tool
  for an agent platform that needs all data models simultaneously.

SurrealQL advantages for this platform:
  → COMMIT / ROLLBACK transaction semantics → Agent-Commit atomic writes
  → DEFINE TABLE PERMISSIONS → planned replacement for OPA in Agent-Policies
  → graph traversal queries → GraphRAG knowledge graph in Agent-Rag
  → vector similarity search → semantic memory in Agent-Memory
  → LIVE queries → real-time state in Agent-Monitor / Agent-Dashboard
  → native time-series support → Agent-FinOps cost history, Agent-Health telemetry

SurrealDB use in every layer:
  Agent-Memory    → working, episodic, semantic, procedural memory tiers
  Agent-Rag       → vector index and knowledge graph storage
  Agent-Commit    → COMMIT transaction for atomic agent work
  Agent-Policies  → planned native SurrealQL policy evaluation
  Agent-Monitor   → real-time trace and event storage
  Agent-Runs      → full-fidelity run records for replay and time travel
  Agent-Trust     → immutable provenance records
  Agent-FinOps    → cost attribution and spend history
  Agent-Health    → heartbeat and health event log
```

## Deployment Stack

```text
Local development
  → Podman Compose preferred
  → Docker Compose compatible fallback

AgentKube
  → Kubernetes-native deployment layer for agents
  → owns the Kubernetes manifests, Helm charts, and operators for running agents
  → agent lifecycle on Kubernetes: scheduling, scaling, resource limits, health probes
  → integrates with AgentKube-aware health checks (Agent-Health) and observability
  → deploys platform services to MicroK8s (first always-on environment) and later
    to managed Kubernetes clusters at scale
  → connects to: Agent-deploy (CI/CD pipeline delivers to AgentKube),
    Agent-Health (Kubernetes liveness/readiness probes), Agent-Monitor (pod metrics)

First always-on environment
  → VPS + MicroK8s (via AgentKube)

Later scale path
  → managed Kubernetes or larger MicroK8s cluster (via AgentKube)
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
Agent-Framework runs the core runtime.
Agent-Memory owns the four-tier memory system.
Agent-Rag owns all retrieval (RAG, GraphRAG, multimodal, hybrid).
Agent-Kernel handles native execution.
Agent-Frameworks adapts to external frameworks.
Agent-Flow builds workflows.
AAGFE enforces governance at runtime.
Agent-Constraints defines the policies.
Agent-Environment defines where.
Agent-Secrets protects credentials.
Agent-deploy deploys and operates.
AgentKube runs agents on Kubernetes.
Agent-Monitor observes in real time.
Agent-Traces owns the telemetry schema.
Agent-Runs records every step with full fidelity, replay, and time travel.
Agent-FinOps controls cost.
Agent-Trust proves evidence.
Agent-Eval proves quality.
Agent-Review provides review findings.
Agent-Decisions records all decisions.
Agent-Analytics tracks adoption, engagement, and improvement.
Agent-Community connects the ecosystem.
Agent-Speech enables voice interaction.
Agent-Connect integrates everything external.
Agent-Fabric unifies data, identity, skills, and tools.
Agent-Security secures the platform: cybersecurity, OWASP, ITDR, SAST, audit.
Agent-LCM manages the agent lifecycle end to end.
Agent-IGA governs agent identity and access.
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

## Runtime Law

```text
SurrealDB is the runtime brain, state layer, policy layer, API layer, and deterministic decision layer.
SurrealML is the learned inference layer.
LLMs are language tools, not the source of truth.
```

Business logic outside SurrealDB or SurrealML requires quorum consensus before implementation.

This applies to scoring, trust gates, model routing, budget enforcement, lifecycle transitions, approval decisions, permissions, policy checks, memory selection, belief updates, runtime state mutation, and public runtime API behavior.

```text
No quorum, no exception.
```

Any design change or architecture deviation requires quorum consensus before implementation.

```text
No quorum, no design change.
```

Any grammar, vocabulary, ontology, taxonomy, naming, schema-language, semantic-model, domain-term, relation, entity-type, record-type, edge-type, JSON-LD context, or meaning change requires quorum consensus before implementation.

```text
No quorum, no vocabulary change.
```

## Final Rule

Each repository owns exactly one major responsibility.

If a responsibility is shared, define the boundary explicitly before implementation.
