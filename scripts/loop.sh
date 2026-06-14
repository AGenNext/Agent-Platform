#!/usr/bin/env bash
set -euo pipefail

echo "== Agent Platform Loop =="

bash scripts/doctor.sh
bash scripts/lint.sh
bash scripts/validate.sh
bash scripts/test.sh
bash scripts/build.sh

echo "== Loop complete =="
