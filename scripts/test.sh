#!/usr/bin/env bash
set -euo pipefail

echo "== Test =="
python3 runtime/deepagents/app/main.py --self-test
echo "test: ok"
