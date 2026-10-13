// Agent Platform dashboard server.
//
// Serves the built Vite SPA from ./public and transparently proxies /api/* to
// the SurrealDB-served API (DEFINE API at /api/<ns>/<db>/*). The proxy is dumb
// transport: it forwards method/path/query/body verbatim, injects the SurrealDB
// namespace/database prefix, and authenticates as the unprivileged `public`
// record access (no root credentials live in this pod). All authority and
// permissions live in SurrealDB — that scoped identity can only read the
// dashboard data and perform the specific writes the table PERMISSIONS allow;
// it cannot run DDL, reach other databases, or manage users. This process makes
// no decisions and SurrealDB's /sql surface is never exposed to the browser.
const path = require("path");
const express = require("express");
const rateLimit = require("express-rate-limit");

const app = express();
const PORT = process.env.PORT || 3000;
const publicDir = path.join(__dirname, "public");

// Trust the ingress/proxy so the limiter keys off the real client IP.
app.set("trust proxy", 1);

// Global rate limit: every route handler below (the /api proxy, static assets,
// and the SPA fallback that reads index.html from disk) is throttled per client
// IP, bounding filesystem and upstream load from any single source.
const limiter = rateLimit({
  windowMs: 60 * 1000,
  limit: Number(process.env.RATE_LIMIT_PER_MINUTE || 300),
  standardHeaders: "draft-7",
  legacyHeaders: false,
  // Never throttle the liveness/readiness probe (no filesystem access anyway).
  skip: (req) => req.path === "/health",
});
app.use(limiter);

const SURREAL = process.env.SURREAL_URL || "http://surrealdb:8000";
const NS = process.env.SURREAL_NS || "agent_platform";
const DB = process.env.SURREAL_DB || "agent_platform";
const ACCESS = process.env.SURREAL_ACCESS || "public";

// Sign in to the credential-less `public` record access and cache the scoped
// token. No credentials are stored in this pod; SurrealDB mints a short-lived
// token for the unprivileged identity. Refreshed lazily and on a 401.
let tokenPromise = null;
function signIn() {
  tokenPromise = (async () => {
    const r = await fetch(`${SURREAL}/signin`, {
      method: "POST",
      headers: { "content-type": "application/json", accept: "application/json" },
      body: JSON.stringify({ ns: NS, db: DB, ac: ACCESS }),
    });
    if (!r.ok) throw new Error(`surreal signin failed: ${r.status}`);
    const j = await r.json();
    if (!j.token) throw new Error("surreal signin returned no token");
    return j.token;
  })();
  // Don't cache a rejected promise — next call retries the sign-in.
  tokenPromise.catch(() => { tokenPromise = null; });
  return tokenPromise;
}
function getToken() {
  return tokenPromise || signIn();
}

app.get("/health", (_req, res) => res.json({ status: "ok" }));

// Transparent reverse proxy: /api/<x> -> <SURREAL>/api/<ns>/<db>/<x>,
// authenticated as the scoped `public` identity via a bearer token.
app.use("/api", express.raw({ type: "*/*", limit: "5mb" }), async (req, res) => {
  const target = `${SURREAL}/api/${NS}/${DB}${req.url}`;
  const body = req.method === "GET" || req.method === "HEAD" ? undefined : req.body;
  const send = async (token) =>
    fetch(target, {
      method: req.method,
      headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
      body,
    });
  try {
    let upstream = await send(await getToken());
    if (upstream.status === 401) {
      // Token expired/invalid — re-sign in once and retry.
      tokenPromise = null;
      upstream = await send(await getToken());
    }
    const text = await upstream.text();
    res
      .status(upstream.status)
      .set("content-type", upstream.headers.get("content-type") || "application/json")
      .send(text);
  } catch (err) {
    res.status(502).json({ error: "upstream_unreachable", detail: String(err) });
  }
});

app.use(express.static(publicDir));

// SPA history fallback — every non-asset, non-api route serves index.html.
app.get("*", (_req, res) => res.sendFile(path.join(publicDir, "index.html")));

app.listen(PORT, () => console.log(`agent-dashboard listening on :${PORT} (api -> ${SURREAL})`));
