# Final review authority

Agent-Platform owns the final review decision for AGenNext work.

## Decision

Only Agent-Platform can make the final accept/reject decision before work is committed, merged, deployed, or promoted.

Agent-Review may provide review mechanics, review signals, comments, findings, or recommendations, but it does not own the final platform decision.

## Boundary

| Component | Responsibility |
|---|---|
| Agent-Platform | Final review authority and platform-level accept/reject decision |
| Agent-Review | Review mechanics, review findings, review recommendations |
| Agent-Commit | Creates commits/branches/PRs after platform approval |
| Agent-Eval | Standards-based quality scores |
| Agent-Security | Security gates and vulnerability findings |
| Agent-Compliance | Compliance control/evidence status |
| Agent-Traces | Evidence and audit timeline |

## Final review inputs

Agent-Platform should consider:

- Agent-Standard requirements
- Agent-Eval scores
- Agent-Security gate results
- Agent-Compliance evidence
- Agent-Handoff validity if multi-agent work occurred
- Agent-Traces evidence
- Agent-Review findings
- deployment risk
- rollback readiness

## Flow

```txt
Agent work produced
  ↓
Agent-Eval scores quality
  ↓
Agent-Security checks risk
  ↓
Agent-Compliance maps evidence
  ↓
Agent-Review produces findings/recommendations
  ↓
Agent-Platform makes final decision
  ↓
Agent-Commit may create commit/PR only after approval
```

## Rule

No individual agent or team can self-approve final work.

Final review is a platform responsibility.
