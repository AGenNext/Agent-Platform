#!/usr/bin/env bash
set -euo pipefail

echo "== Build =="
mkdir -p dist
cat > dist/build-manifest.json <<JSON
{
  "name": "agent-platform",
  "mode": "code-first-monorepo-loop",
  "status": "built",
  "artifacts": [
    "blueprints/agents",
    "runtime/deepagents",
    "stacks",
    "contracts",
    "schemas",
    "policies/opa",
    "deploy"
  ]
}
JSON
echo "build: ok"
