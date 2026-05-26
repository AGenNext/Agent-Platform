#!/usr/bin/env bash
# One-shot cloud deploy: SurrealDB → API → Dashboard
# Prerequisites: flyctl (authenticated), netlify CLI (authenticated)
set -euo pipefail

REGION=${FLY_REGION:-iad}
SURREAL_APP=${SURREAL_APP:-agent-surrealdb}
API_APP=${API_APP:-agent-knowledge-api}
NETLIFY_SITE=${NETLIFY_SITE:-}   # set or pass as env var

echo "==> [1/4] Deploying SurrealDB on Fly.io"
flyctl apps create "$SURREAL_APP" --org personal 2>/dev/null || true
flyctl volumes create surrealdb_data \
  --app "$SURREAL_APP" --region "$REGION" --size 5 2>/dev/null || true
flyctl secrets set \
  SURREAL_ROOT_PASS="${SURREAL_ROOT_PASS:?set SURREAL_ROOT_PASS}" \
  --app "$SURREAL_APP"
flyctl deploy --config fly.surrealdb.toml --app "$SURREAL_APP"

SURREAL_URL="wss://${SURREAL_APP}.fly.dev/rpc"
echo "    SurrealDB: $SURREAL_URL"

echo "==> [2/4] Deploying API on Fly.io"
flyctl apps create "$API_APP" --org personal 2>/dev/null || true
flyctl secrets set \
  SURREALDB_URL="$SURREAL_URL" \
  SURREALDB_USERNAME=root \
  SURREALDB_PASSWORD="${SURREAL_ROOT_PASS}" \
  --app "$API_APP"
flyctl deploy --config fly.toml --app "$API_APP"

API_URL="https://${API_APP}.fly.dev"
echo "    API: $API_URL"

echo "==> [3/4] Building dashboard"
cd services/agent-dashboard
VITE_API_URL="$API_URL" npm run build
cd ../..

echo "==> [4/4] Deploying dashboard to Netlify"
if [[ -n "$NETLIFY_SITE" ]]; then
  netlify deploy --dir services/agent-dashboard/dist --prod --site "$NETLIFY_SITE"
else
  netlify deploy --dir services/agent-dashboard/dist --prod
fi

echo ""
echo "✓ Deploy complete"
echo "  API:       $API_URL"
echo "  Dashboard: $(netlify status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("siteUrl",""))' 2>/dev/null || echo 'see netlify output')"
