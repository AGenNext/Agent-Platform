#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RULES_FILE="${RULES_FILE:-governance/no-python-business-logic.rules.tsv}"

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep is required for governance checks."
  exit 2
fi

if [[ ! -f "$RULES_FILE" ]]; then
  echo "Governance rules file not found: $RULES_FILE"
  exit 2
fi

PY_FILES="$(rg --files -g '*.py' \
  -g '!**/.venv/**' \
  -g '!**/venv/**' \
  -g '!**/__pycache__/**' \
  -g '!**/node_modules/**' || true)"

if [[ -z "$PY_FILES" ]]; then
  echo "No Python files found."
  exit 0
fi

FAIL=0

echo "Checking Python files for prohibited business logic..."
echo ""

check_content_pattern() {
  local label="$1"
  local pattern="$2"
  local matches

  matches="$(printf '%s\n' "$PY_FILES" | xargs rg -n "$pattern" 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    echo "[FAIL] $label"
    echo "$matches"
    echo ""
    FAIL=1
  fi
}

check_path_pattern() {
  local label="$1"
  local pattern="$2"
  local matches

  matches="$(printf '%s\n' "$PY_FILES" | rg "$pattern" || true)"
  if [[ -n "$matches" ]]; then
    echo "[FAIL] $label"
    echo "$matches"
    echo ""
    FAIL=1
  fi
}

while IFS=$'\t' read -r scope label pattern; do
  [[ -z "${scope:-}" || "$scope" == \#* ]] && continue

  case "$scope" in
    content)
      check_content_pattern "$label" "$pattern"
      ;;
    path)
      check_path_pattern "$label" "$pattern"
      ;;
    *)
      echo "[FAIL] Unknown governance rule scope '$scope' in $RULES_FILE"
      FAIL=1
      ;;
  esac
done < "$RULES_FILE"

if [[ "$FAIL" -ne 0 ]]; then
  cat <<'MSG'
Governance check failed.

Business logic must live in SurrealDB or SurrealML:
- SurrealDB schema
- SurrealQL custom functions
- SurrealDB DEFINE API endpoints
- SurrealDB events and permissions
- SurrealML inference bindings

Python business logic requires quorum consensus before implementation.
No quorum, no exception.

Edit validation definitions in:
  governance/no-python-business-logic.rules.tsv
MSG
  exit 1
fi

echo "No prohibited Python business logic detected."
