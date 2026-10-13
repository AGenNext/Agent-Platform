#!/usr/bin/env bash
# Verifies the SurrealDB-served API: starts SurrealDB 3.x, applies the schema +
# seed, then asserts every dashboard endpoint returns HTTP 200 and JSON. This is
# the contract-compliant API surface — all logic lives in SurrealQL (DEFINE API +
# fn::…), no external backend service.
set -euo pipefail

SURREAL_VERSION="${SURREAL_VERSION:-v3.2.4}"
HERE="$(cd "$(dirname "$0")" && pwd)"
NS=agent_platform
DB=agent_platform
BASE="http://127.0.0.1:8000"
AUTH="-u root:root"

if ! command -v surreal >/dev/null 2>&1; then
  echo "Installing SurrealDB ${SURREAL_VERSION}…"
  url="https://github.com/surrealdb/surrealdb/releases/download/${SURREAL_VERSION}/surreal-${SURREAL_VERSION}.linux-amd64.tgz"
  tgz="$(mktemp --suffix=.tgz)"
  # Download to a file first: -f fails on an HTTP error (so a redirect/error page
  # is never piped to tar as a bogus "archive"), and --retry rides out transient
  # GitHub/CDN hiccups. Then verify it is actually gzip before extracting.
  curl -fSL --retry 5 --retry-all-errors --retry-delay 2 -o "$tgz" "$url"
  if ! gzip -t "$tgz" 2>/dev/null; then
    echo "ERROR: downloaded SurrealDB archive is not a valid gzip (download failed?)" >&2
    exit 1
  fi
  tar xzf "$tgz" -C /tmp
  rm -f "$tgz"
  sudo install -m0755 /tmp/surreal /usr/local/bin/surreal
fi
surreal version

surreal start --allow-all --user root --pass root --bind 127.0.0.1:8000 memory &
SRV=$!
trap 'kill $SRV 2>/dev/null || true' EXIT
for _ in $(seq 1 30); do curl -fsS "$BASE/health" >/dev/null 2>&1 && break; sleep 1; done

apply() {
  curl -sS $AUTH -H "surreal-ns: $NS" -H "surreal-db: $DB" \
    -H "Content-Type: text/plain" --data-binary @"$1" "$BASE/sql" \
    | python3 -c "import sys,json;d=json.load(sys.stdin);e=[r for r in d if r.get('status')=='ERR'];
print(f'  {len(d)-len(e)} ok, {len(e)} err in $1');
[print('  ERR:',r.get('result')) for r in e];
sys.exit(1 if e else 0)"
}

curl -sS $AUTH --data-binary "DEFINE NAMESPACE $NS; USE NS $NS; DEFINE DATABASE $DB;" "$BASE/sql" >/dev/null
echo "Applying schema + seed…"
apply "$HERE/app/schema.surql"
apply "$HERE/app/seed.surql"

API="$BASE/api/$NS/$DB"
fail=0
check() {  # method path expected
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' $AUTH -X "$1" ${3:+-H 'content-type: application/json' -d "$3"} "$API$2")
  if [ "$code" = "200" ]; then printf '  ok   %-6s %s\n' "$1" "$2"; else printf '  FAIL %-6s %s -> %s\n' "$1" "$2" "$code"; fail=1; fi
}
echo "Checking endpoints…"
for p in /health /objectives /artifacts /artifacts/hub /agents/roster /spaces /channels /milestones /learning/paths /model-router/routes /model-router/usage/summary /agents/run/run-1 /eval/artifacts/art_1 /trust/artifacts/art_1; do
  check GET "$p"
done
check POST /objectives '{"title":"CI objective","objective_type":"deck"}'
check POST /objectives/demo/run ''
check POST /agents '{"run_id":"run-ci","agent_role":"researcher"}'
check POST /model-router/select '{"task_type":"generic"}'
check POST /eval/evaluate '{"artifact_id":"art_1","dimension_scores":{"completeness":0.9,"logical":0.8,"evidence":0.8,"accuracy":0.9,"relevance":0.9},"threshold":0.7}'
check POST /trust/provenance '{"artifact_id":"art_1","evidence_links":[{"source_ref":"s1"},{"source_ref":"s2"}]}'

# ── Response-shape assertions ────────────────────────────────────────────────
# Status 200 is not enough: the dashboard crashes if these endpoints return the
# wrong JSON shape (missing fields, or an array where it expects one object).
echo "Checking response shapes…"
shape() {  # label path 'must-contain…' (one -e per needle); also asserts a JSON object
  local label="$1" path="$2"; shift 2
  local body; body=$(curl -s $AUTH "$API$path")
  case "$body" in
    "{"*) ;;  # must be a JSON object, not an array
    *) printf '  FAIL %-26s not a JSON object: %.60s\n' "$label" "$body"; fail=1; return;;
  esac
  local miss=0 n
  for n in "$@"; do case "$body" in *"\"$n\""*) ;; *) echo "  FAIL $label missing field: $n"; miss=1;; esac; done
  [ "$miss" = "0" ] && printf '  ok   %-26s %s\n' "$label" "$path" || fail=1
}
# usage summary: the exact fields HealthView reads (total_input_tokens.toLocaleString(), etc.)
shape usage-summary   "/model-router/usage/summary" total_calls total_input_tokens total_output_tokens total_cost_usd avg_cost_usd
# eval + trust: single normalized object with the nested field the UI iterates
shape eval-artifact   "/eval/artifacts/art_1"  artifact_id composite_score passed threshold dimension_scores
shape trust-artifact  "/trust/artifacts/art_1" artifact_id score evidence_count
# model-router budget enforcement: a rule with its daily budget exhausted must
# fall back to the free model rather than routing paid traffic.
curl -sS $AUTH -H "surreal-ns: $NS" -H "surreal-db: $DB" -H "Content-Type: text/plain" \
  --data-binary 'UPSERT routing_rules:capped SET task_type="capped", preferred_provider="anthropic", models=[{model_id:"claude-sonnet",provider:"anthropic",max_cost_per_call:0.05,priority:1}], max_cost_per_call=0.05, daily_budget=0.0, enabled=true;' \
  "$BASE/sql" >/dev/null
routed=$(curl -s $AUTH -X POST -H 'content-type: application/json' -d '{"task_type":"capped"}' "$API/model-router/select")
case "$routed" in
  *'daily_budget_exhausted'*) printf '  ok   %-26s %s\n' "budget-fallback" "/model-router/select";;
  *) printf '  FAIL %-26s expected daily_budget_exhausted, got: %.80s\n' "budget-fallback" "$routed"; fail=1;;
esac

[ "$fail" = "0" ] && echo "All API checks passed." || { echo "API checks FAILED"; exit 1; }
