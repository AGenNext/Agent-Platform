#!/usr/bin/env bash
set -euo pipefail

echo "== Lint =="
find . -name '*.sh' -not -path './.git/*' -print0 | while IFS= read -r -d '' file; do bash -n "$file"; done
python3 -m py_compile runtime/deepagents/app/main.py
echo "lint: ok"
