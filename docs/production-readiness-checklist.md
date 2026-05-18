# Production Readiness Checklist

A release is production-ready only if all sections below pass.

## Product

- Core workflow produces trusted artifacts.
- Required use cases are validated.
- Human review package is available.

## Quality

- Tests pass.
- Benchmarks pass.
- Evaluations pass.
- Regression suite shows no blocking failures.

## Trust

- Provenance is complete.
- Evidence links are available.
- Trust score meets threshold.

## Security

- Secrets are environment-scoped.
- No secrets are committed.
- Least privilege is enforced.
- Audit logging is enabled.

## Observability

- Traces, metrics, and logs are available.
- Alerts are configured.
- Dashboards are operational.

## FinOps

- Cost attribution is complete.
- Budgets are configured.
- Unit economics are visible.

## Operations

- Deployment pipeline passes.
- Smoke tests pass.
- Rollback procedure is validated.
- Backup and restore are tested.

## SaaS

- Tenant isolation is verified.
- RBAC is enforced.
- Billing and metering are functional when required.

## Final Rule

If any critical checklist item fails, the release is not production-ready.
