#!/usr/bin/env bash
set -euo pipefail

echo "== Doctor =="
command -v python3 >/dev/null || { echo "python3 missing"; exit 1; }
if command -v docker >/dev/null; then echo "docker: ok"; else echo "docker: missing, skipping container checks"; fi
echo "doctor: ok"
