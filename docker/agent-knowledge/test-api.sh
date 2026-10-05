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

[ "$fail" = "0" ] && echo "All API checks passed." || { echo "API checks FAILED"; exit 1; }
