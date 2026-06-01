# Agent DB Runtime Capability Model

Status: draft. This document defines the complete capability model for AGenNext.

## Purpose

The runtime must model capabilities without flattening everything into generic tools.

The complete hierarchy is:

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

Operationally:

```txt
Skill
  uses Interface
    exposed by API
      implemented by Toolkit
        contains Tool
          executes Operator
            governed by Policy
              authorized by Security
                evaluated by Trust
```

## Definitions

### Capability

A capability is something the platform, an agent, a human, a workflow, or a service can do.

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

It may combine interfaces, tools, operators, policies, prompts, knowledge, memory, and evaluations into a coherent unit that an agent or human can use.

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
Tool = callable capability surface
Operator = smallest executable operation
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
McpToolInterface
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
MCP Resource   -> Artifact / Knowledge / Memory / Registry Entry
MCP Prompt     -> Artifact / Skill / Policy-governed template
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

A tool is a named capability surface inside a toolkit.

Examples:

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
```

### Operator

An operator is the smallest executable unit.

Examples:

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

Implemented by external systems.

Examples:

```txt
GitHub.create_issue
GitHub.create_pull_request
Slack.send_message
Email.send
Payment.capture
CRM.create_lead
Ticketing.create_ticket
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
```

## Suggested mapping to existing runtime schema

Do not add duplicate core tables immediately. Use existing primitives first.

```txt
Capability        -> entity + registry_entry + schema_definition
Skill             -> entity(entity_type = skill) + registry_entry
Interface         -> schema_definition(schema_kind = schema) or protocol binding
API               -> protocol + protocol_binding + registry_entry
Protocol          -> protocol
MCP Server        -> protocol + protocol_binding + registry_entry
Toolkit           -> entity(entity_type = integration/tool/runtime) + registry_entry
Tool              -> entity(entity_type = tool) + registry_entry + action
Operator          -> action + action_invocation
Tool Call         -> action_invocation + task + protocol_message
Skill Execution   -> task + workflow_run + decision + evaluation
```

## Example: MCP tool call

```txt
Skill: GitHub Issue Management Skill
  Interface: IssueInterface
    API: MCP Server API
      Protocol: MCP
        Toolkit: GitHub Toolkit
          Tool: GitHub Issue Tool
            Operator: github.issue.create
              ActionInvocation
                Task
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
            Operator: task.complete
              fn::complete_task
                TaskEvent
                  Evaluation
                    TrustAssessment
```

## Runtime readiness note

This capability model is design documentation. It does not make the runtime deployment-ready.

Deployment readiness still depends on:

```bash
cd packages/agent-db-runtime
make check
```

and the validation gates tracked in #14, #16, #17, and #18.
