# Agent Platform MVP

## Product Definition

Agent Platform MVP is the smallest product surface that proves a composable agent can be defined, executed, observed, and improved.

It is not the full enterprise platform.
It is not the registry.
It is not the marketplace.
It is not the Kubernetes operator.
It is not the deployment system.

## One-Line MVP

**A composable identity-bound agent loop that turns context into an action and leaves a trace.**

## Core Model

An agent is not a prompt.
An agent is not a chatbot.
An agent is not a container.
An agent is a composition.

```text
Agent
  = Identity
  + Objective
  + Context
  + Capability
  + Decision
  + Action
  + Trace
```

## MVP Primitives

### 1. Identity

Who or what the agent is.

```yaml
identity:
  id: agent:hello-agent
  name: Hello Agent
```

### 2. Objective

What the agent is trying to achieve.

```yaml
objective:
  description: Respond to one user message clearly.
```

### 3. Context

What the agent currently knows.

```yaml
context:
  input: user-message
```

### 4. Capability

What the agent can use.

```yaml
capabilities:
  - name: respond
    type: builtin
```

### 5. Decision

How the agent chooses the next step.

```yaml
decision:
  strategy: simple
```

### 6. Action

What the agent does.

```yaml
actions:
  - name: reply
    type: message-response
```

### 7. Trace

What happened and why.

```yaml
trace:
  enabled: true
  store: local
```

## Minimal Agent Contract

```yaml
apiVersion: agent.agennext.io/v1alpha1
kind: Agent
metadata:
  name: hello-agent
spec:
  identity:
    id: agent:hello-agent
    name: Hello Agent

  objective:
    description: Respond to one user message clearly.

  context:
    input: user-message

  capabilities:
    - name: respond
      type: builtin

  decision:
    strategy: simple

  actions:
    - name: reply
      type: message-response

  trace:
    enabled: true
    store: local
```

## Minimal Runtime Loop

```text
load agent contract
  -> read context
  -> evaluate objective
  -> select capability
  -> make decision
  -> execute action
  -> write trace
```

## MVP Product Test

Input:

```text
Hello agent
```

Expected response:

```text
hello-agent responded
```

Expected trace:

```json
{
  "agent": "agent:hello-agent",
  "objective": "Respond to one user message clearly.",
  "context": "Hello agent",
  "decision": "reply",
  "action": "message-response",
  "result": "hello-agent responded"
}
```

## MVP Scope

The MVP includes only:

- one agent definition
- one runtime loop
- one built-in response capability
- one local trace
- one status output

## Explicit Non-Goals

The MVP does not include:

- full enterprise platform
- CLI as product
- Kubernetes deployment
- OCI packaging
- DID or verifiable credentials
- OpenFGA
- AuthZEN
- OpenFeature
- OPA
- Harbor
- Zot
- GitOps
- multi-agent orchestration
- marketplace
- registry
- enterprise identity lifecycle
- evaluation engine
- distributed network

## Success Criterion

The MVP is successful when a user can define one composable agent, run one message through it, receive one response, and inspect one trace.

## Next Layer After MVP

After this works, Agent Forge can package the agent.

```text
Agent MVP
  -> Agent Forge
  -> Agent Registry
  -> Agent Identity
  -> Agent Network
```
