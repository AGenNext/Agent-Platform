# Upstream SDK Tooling Plan

## Purpose

Agent Platform will use upstream tools and SDKs through adapter boundaries while keeping the core runtime, platform backend, canonical run model, and product data model owned by AGenNext.

## Required Upstream Tool Integrations

| Tool | Purpose | Owning Repo |
|---|---|---|
| Bolt + local LLM | frontend/vibe coding instance | Agent-Site / Agent-Dashboard / Agent-Platform |
| Metabase SDK/API | BI and analytics dashboard tool | Agent-Analytics / Agent-Dashboard |
| Teable SDK/API | agent builder/admin tables | Agent-Skills / Agent-Team / Agent-Dashboard |
| Lago SDK/API | billing and metering | Agent-FinOps / Agent-Knowledge |
| GitTip SDK/API | funding/tipping/sponsor workflows if applicable | Agent-FinOps / Agent-Site |
| Uptime Kuma API | uptime checks and status monitoring | Agent-deploy |
| SigNoz API/OpenTelemetry | APM, infra traces, logs, metrics | Agent-deploy / Agent-Traces |
| Infisical SDK/API | secrets management | Agent-Secrets / Agent-Environment / Agent-deploy |

## Core Rule

```text
Use upstream SDKs only behind adapters.
Do not make upstream schemas the canonical product model.
```

## Adapter Pattern

```text
AGenNext domain contract
  → adapter interface
  → upstream SDK/API
  → external tool
```

Example:

```text
Agent-Secrets SecretProvider
  → InfisicalSecretProvider
  → Infisical SDK/API
```

## Repository Ownership

### Agent-Secrets

Owns:

- Infisical integration contract
- secret provider abstraction
- environment secret mapping
- rotation and expiration policy

### Agent-deploy

Owns:

- Uptime Kuma integration contract
- SigNoz/OpenTelemetry deployment contract
- monitoring/alerting adapters
- post-production checks

### Agent-FinOps

Owns:

- Lago billing integration contract
- GitTip/funding integration contract if used
- usage metering model
- cost-to-billing mapping

### Agent-Analytics

Owns:

- Metabase integration contract
- reporting data marts/views
- analytics export policy

### Agent-Skills / Agent-Team

Owns:

- Teable-backed builder/admin registry contracts
- agent/skill catalog mapping

### Agent-Site / Agent-Dashboard

Owns:

- Bolt-generated frontend outputs after hardening
- UI integration with backend APIs

## Required Contracts To Add

1. `Agent-Secrets/contracts/infisical-provider.md`
2. `Agent-deploy/contracts/uptime-kuma-monitoring.md`
3. `Agent-deploy/contracts/signoz-otel-apm.md`
4. `Agent-FinOps/contracts/lago-billing.md`
5. `Agent-FinOps/contracts/gittip-funding.md`
6. `Agent-Analytics/contracts/metabase-reporting.md`
7. `Agent-Skills/contracts/teable-builder.md`
8. `Agent-Platform/docs/bolt-local-llm-instance.md`

## Local Deployment Expectation

Local platform should eventually support optional profiles:

```text
core
  → SurrealDB, MinIO, Agent-Knowledge, Agent-Dashboard

builder
  → Teable, Langflow

analytics
  → Metabase

observability
  → Langfuse, SigNoz, Uptime Kuma

secrets
  → Infisical

billing
  → Lago

frontend-ai
  → Bolt/local LLM instance if self-hostable/practical
```

## Final Rule

```text
Core platform stays custom.
Upstream tools are pluggable accelerators.
Adapters isolate SDKs.
Agent-Traces, Agent-Secrets, Agent-FinOps, Agent-deploy, and Agent-Analytics own the contracts.
```
