# Agent DB Runtime Capability Model

Status: draft. This document defines the complete capability model for AGenNext.

## Purpose

The runtime must model capabilities without flattening everything into generic integrations.

Five core rules:

```txt
Project defines scope.
Milestone defines deadline.
Task measures progress.
Everything outside the kernel is a Tool.
Every agent is an Operator.
```

Meaning:

```txt
Project
  -> scope boundary, ownership boundary, delivery boundary, resource boundary

Milestone
  -> deadline, delivery checkpoint, acceptance checkpoint, schedule boundary

Task
  -> progress unit, execution unit, measurable work unit, status unit

External system, API, app, service, SaaS, database, file store, queue, webhook, email inbox, model provider, payment provider, browser, CLI, connector
  -> Tool

Agent, human delegate, worker, model runner, workflow runner, automation runner, database function runner
  -> Operator
```

The complete hierarchy is:

```txt
Project
  defines Scope
    contains Milestone
      defines Deadline
        contains Task
          measures Progress
            constrains Capability
              implemented through Skill
                uses Interface
                  exposed by API
                    governed by Protocol
                      packaged by Toolkit
                        exposes Tool
                          executed by Operator
```

Operationally:

```txt
Project
  scopes Skill / Task / Workflow / Tool / Operator
    Milestone sets deadline
      Task measures progress
        Operator executes Skill
          Skill uses Interface
            Interface exposed by API
              API speaks Protocol
                Toolkit contains Tool
                  Tool exposes operation surface
                    Operator performs operation
                      governed by Policy
                        authorized by Security
                          evaluated by Trust
```

## Delivery control primitives

### Project

A project is the primary delivery and scope boundary.

It defines:

```txt
scope
objectives
constraints
stakeholders
allowed tools
allowed operators
allowed skills
allowed protocols
allowed environments
budget
risk boundary
governance boundary
success criteria
```

A project answers:

```txt
What is included?
What is excluded?
Who owns it?
What constraints apply?
Which tools/operators/skills may be used?
```

### Milestone

A milestone is the primary deadline and delivery checkpoint.

It defines:

```txt
deadline
deliverables
acceptance criteria
required tasks
required evidence
release checkpoint
review checkpoint
dependency checkpoint
```

A milestone answers:

```txt
By when?
What must be delivered by then?
What evidence proves completion?
```

### Task

A task is the measurable unit of progress.

It defines:

```txt
status
assignee
owner
priority
risk
progress percentage
blocked state
dependencies
output
evidence
estimate
actual duration
cost
confidence
```

A task answers:

```txt
What work is being done?
Who is doing it?
How far has it progressed?
What blocks it?
What evidence proves it moved forward?
```

Progress is not guessed from conversation. Progress is derived from tasks.

```txt
Project Progress
  = aggregate(Task.status, Task.progress, Task.blockers, Task.evidence)

Milestone Progress
  = aggregate(Tasks linked to Milestone)

Workflow Progress
  = aggregate(Tasks and WorkflowSteps)
```

## Capability hierarchy

```txt
Capability
  ├── Skill
  ├── Interface
  ├── API
  ├── Protocol
  ├── MCP Server
  ├── Toolkit
  ├── Tool
  └── Operator
```

### Capability

A capability is something the platform, an operator, a workflow, a service, or a tool can enable.

Examples:

```txt
Create a task
Evaluate a policy
Authorize an action
Store memory
Verify knowledge
Publish an artifact
Open an issue
Settle a payment
Send a protocol message
Call an MCP tool
```

Capabilities are described, governed, registered, evaluated, and trusted.

### Skill

A skill is a reusable capability bundle.

It may combine interfaces, tools, operators, policies, prompts, knowledge, memory, and evaluations into a coherent unit that an agent, human, workflow, or runtime can execute.

Examples:

```txt
Incident Triage Skill
Policy Review Skill
Knowledge Verification Skill
Workflow Planning Skill
Payment Reconciliation Skill
GitHub Issue Management Skill
Agent Handoff Skill
Customer Support Skill
Research Summarization Skill
```

A skill defines:

```txt
name
version
description
category
required interfaces
required tools
required operators
required protocols
required credentials
required policies
required trust level
input schema
output schema
evaluation criteria
registry entry
```

A skill is not the same as a tool.

```txt
Skill = reusable capability bundle
Tool = outside or callable capability surface
Operator = executor that performs operations through tools or native runtime functions
```

### Interface

An interface is the logical contract a caller expects.

Examples:

```txt
TaskInterface
WorkflowInterface
DecisionInterface
PolicyInterface
AuthorizationInterface
MemoryInterface
KnowledgeInterface
TrustInterface
RegistryInterface
CommerceInterface
CollaborationInterface
ProtocolInterface
ArtifactInterface
IssueInterface
SkillInterface
ToolInterface
OperatorInterface
AgentOperatorInterface
McpToolInterface
ProjectInterface
MilestoneInterface
ProgressInterface
```

### API

An API exposes one or more interfaces over a concrete access method.

Examples:

```txt
REST API
GraphQL API
gRPC API
WebSocket API
Webhook API
CLI API
SDK API
Internal Runtime API
SurrealDB Function API
MCP Server API
A2A API
```

### Protocol

A protocol defines interoperability rules.

Examples:

```txt
MCP
A2A
AuthZEN
OpenFGA
OPA
SCIM
OIDC
SAML
DID
Verifiable Credential
AP2
UCP
HTTP
gRPC
WebSocket
Webhook
Email
Slack
GitHub
BPMN
DMN
LangGraph
```

### MCP Server

An MCP server is an API exposure pattern that publishes tools and resources through the Model Context Protocol.

In this model:

```txt
MCP Server
  exposes MCP Tools
  exposes MCP Resources
  exposes MCP Prompts
  maps to Toolkit
  maps to Tool
  maps to Operator
  is governed by Protocol + Policy + Security
```

MCP is not the only tool model. It is one protocol/API surface for exposing tools to model-driven clients.

MCP objects should map to runtime concepts:

```txt
MCP Tool       -> Tool + Operator
MCP Resource   -> Tool-facing Resource backed by Artifact / Knowledge / Memory / Registry Entry
MCP Prompt     -> Tool-facing Prompt backed by Artifact / Skill / Policy-governed template
MCP Server     -> API + Protocol Binding + Toolkit
MCP Call       -> ActionInvocation / ProtocolMessage / Task
```

### Toolkit

A toolkit is a governed package of related tools.

Examples:

```txt
Kernel Toolkit
Database Toolkit
Governance Toolkit
Identity Toolkit
Memory Toolkit
Knowledge Toolkit
Commerce Toolkit
Collaboration Toolkit
GitHub Toolkit
Slack Toolkit
MCP Toolkit
A2A Toolkit
```

### Tool

A tool is any external, outside, callable, observable, or addressable capability surface.

The runtime rule is:

```txt
Everything outside the kernel is a Tool.
```

Examples of things treated as tools:

```txt
External API
SaaS application
Database
Object store
Message queue
Webhook endpoint
Email inbox
Slack workspace
GitHub repository
Browser
CLI command
File system
Search engine
Payment provider
CRM
ERP
Ticketing system
Model provider
Vector database
MCP server
A2A endpoint
Human-facing app surface
```

Tool examples:

```txt
SurrealDB Query Tool
Schema Apply Tool
Policy Evaluation Tool
Task Queue Tool
Workflow Runner Tool
Memory Store Tool
Knowledge Verify Tool
GitHub Issue Tool
Payment Settlement Tool
MCP Tool Adapter
Browser Tool
Email Tool
Search Tool
Calendar Tool
File Tool
Model Tool
```

A tool does not decide by itself in the runtime model. A tool exposes capability. An operator uses it.

### Operator

An operator is an executor.

The runtime rule is:

```txt
Every agent is an Operator.
```

Operators may be:

```txt
Agent Operator
Human Operator
Kernel Operator
Database Operator
Workflow Operator
Model Operator
Automation Operator
Service Operator
Policy Operator
Evaluation Operator
Trust Operator
Commerce Operator
```

An operator performs operations using native runtime capabilities or tools.

Examples:

```txt
agent.customer_support
agent.policy_reviewer
agent.workflow_planner
human.approver
kernel.task_runner
database.fn_runner
workflow.langgraph_runner
model.llm_runner
automation.scheduler
service.github_worker
policy.opa_runner
evaluation.llm_judge
trust.score_updater
commerce.settlement_runner
```

The smallest executable operation remains an operator action:

```txt
entity.create
entity.update
identity.verify
authentication.record
authorization.check
policy.evaluate
task.create
task.start
task.complete
workflow.start
decision.record
evaluation.record
trust.update
memory.store
knowledge.verify
artifact.publish
issue.open
claim.submit
payment.settle
registry.publish
protocol.message.send
mcp.tool.call
```

## Native capability classes

### Kernel-native capabilities

Implemented in the Agent DB Runtime service layer.

Examples:

```txt
create_entity
record_identity
authenticate
authorize_action
evaluate_policy
create_task
start_workflow
record_decision
record_evaluation
update_trust
store_memory
record_knowledge
record_artifact
open_issue
settle_transaction
```

### Database-native capabilities

Implemented directly in SurrealDB through functions, queries, events, schema constraints, and indexes.

Examples:

```txt
fn::record_task_event
fn::complete_task
fn::record_decision
fn::record_evaluation
fn::update_trust_score
fn::store_memory
fn::verify_knowledge
fn::publish_artifact
fn::record_authorization_decision
```

### Protocol-native capabilities

Implemented through protocols.

Examples:

```txt
MCP tool call
A2A handoff
AuthZEN authorization request
OpenFGA relationship check
OPA policy evaluation
SCIM user provisioning
OIDC authentication
AP2 payment authorization
UCP commerce interaction
```

### External capabilities

External capabilities are represented as tools.

Examples:

```txt
GitHub.create_issue        -> GitHub Tool
GitHub.create_pull_request -> GitHub Tool
Slack.send_message         -> Slack Tool
Email.send                 -> Email Tool
Payment.capture            -> Payment Provider Tool
CRM.create_lead            -> CRM Tool
Ticketing.create_ticket    -> Ticketing Tool
Search.query               -> Search Tool
Browser.open               -> Browser Tool
Calendar.create_event      -> Calendar Tool
File.read                  -> File Tool
```

## Agent as operator model

An agent is an identity, but when it executes, it is an operator.

```txt
Agent Identity
  has Credential
  has TrustAssessment
  has RegistryEntry
  becomes Agent Operator during execution
```

Execution model:

```txt
Agent Operator
  receives Task
  selects Skill
  uses Interface
  calls Tool
  executes Operator Action
  records Decision
  emits Evidence
  receives Evaluation
  updates Trust
```

This prevents agent modeling from drifting into a separate abstraction.

```txt
Agent as identity = who/what it is
Agent as operator = what executes
Tool = outside capability surface used by the operator
Skill = governed capability bundle the operator can perform
Project = scope boundary
Milestone = deadline boundary
Task = progress unit
```

## Governance requirements

Every capability should be governable.

Minimum governance fields:

```txt
owner
publisher
provider
version
status
input schema
output schema
risk level
approval required
credential requirements
policy refs
trust score
evaluation criteria
evidence requirements
registry entry
project scope
milestone deadline
task progress
```

## Suggested mapping to existing runtime schema

Do not add duplicate core tables immediately. Use existing primitives first.

```txt
Project           -> entity(entity_type = project) + registry_entry + governance_object
Milestone         -> entity(entity_type = milestone) + task/workflow due dates + governance_object
Progress          -> task.progress + task.status + task_event + workflow_run
Capability        -> entity + registry_entry + schema_definition
Skill             -> entity(entity_type = skill) + registry_entry
Interface         -> schema_definition(schema_kind = schema) or protocol binding
API               -> protocol + protocol_binding + registry_entry
Protocol          -> protocol
MCP Server        -> protocol + protocol_binding + registry_entry
Toolkit           -> entity(entity_type = integration/tool/runtime) + registry_entry
Tool              -> entity(entity_type = tool) + registry_entry + action
Operator          -> identity + entity(entity_type = agent/human/runtime) + action_invocation
Agent Operator    -> identity(identity_type = agent) + action_invocation + task
External Thing    -> entity(entity_type = tool) + registry_entry + protocol_binding
Tool Call         -> action_invocation + task + protocol_message
Skill Execution   -> task + workflow_run + decision + evaluation
```

## Example: project scoped milestone progress

```txt
Project: Agent DB Runtime Validation
  Scope: packages/agent-db-runtime
    Milestone: Runtime Validation v0.1
      Deadline: milestone due date
        Tasks:
          make install
          make validate
          make apply
          make seed
          make smoke
        Progress:
          aggregate task status + evidence
```

## Example: MCP tool call

```txt
Skill: GitHub Issue Management Skill
  Project: Platform Runtime Validation
    Milestone: Runtime Validation v0.1
      Task: Create validation issue
        Interface: IssueInterface
          API: MCP Server API
            Protocol: MCP
              Toolkit: GitHub Toolkit
                Tool: GitHub Issue Tool
                  Operator: agent.issue_operator
                    Operation: github.issue.create
                      ActionInvocation
                        Decision
                          Artifact / Issue
                            Evaluation
                              TrustAssessment
```

## Example: database-native operator

```txt
Skill: Task Completion Skill
  Interface: TaskInterface
    API: SurrealDB Function API
      Protocol: Internal
        Toolkit: Database Toolkit
          Tool: Task Tool
            Operator: database.fn_runner
              Operation: task.complete
                fn::complete_task
                  TaskEvent
                    Evaluation
                      TrustAssessment
```

## Example: outside thing as tool

```txt
Outside Thing: GitHub Repository
  represented as Tool: GitHub Repository Tool
    belongs to Toolkit: GitHub Toolkit
      exposed through API: GitHub REST / GraphQL / MCP
        used by Operator: agent.code_operator
          executes Operation: github.pull_request.create
            records ActionInvocation
              creates Artifact: Pull Request
                records Evaluation
                  updates TrustAssessment
```

## Runtime readiness note

This capability model is design documentation. It does not make the runtime deployment-ready.

Deployment readiness still depends on:

```bash
cd packages/agent-db-runtime
make check
```

and the validation gates tracked in #14, #16, #17, and #18.
