#!/usr/bin/env bash
set -euo pipefail

echo "== Validate =="

required_stacks=(core runtime agents data events workflow governance observability security deployment ui docs)
for stack in "${required_stacks[@]}"; do
  test -f "stacks/$stack/README.md"
  test -f "stacks/$stack/stack.yaml"
done

for dir in blueprints/agents/*-agent; do
  test -f "$dir/agent.yaml"
  test -f "$dir/system.md"
  test -f "$dir/tools.yaml"
  test -f "$dir/policy.md"
  test -f "$dir/runbook.md"
  test -f "$dir/examples/example-run.json"
done

for forbidden in agent-book agent-data-model agent-data-flow agent-event-bus agent-stream agent-storm agent-cyclone syborg; do
  if [ -d "blueprints/agents/$forbidden" ]; then
    echo "Forbidden pseudo-agent blueprint found: $forbidden"
    exit 1
  fi
done

find . -name '*.json' -not -path './.git/*' -print0 | xargs -0 -n1 python3 -m json.tool >/dev/null

echo "validate: ok"
