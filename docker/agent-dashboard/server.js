// Agent Platform dashboard server.
//
// Serves the built Vite SPA from ./public and transparently proxies /api/* to
// the SurrealDB-served API (DEFINE API at /api/<ns>/<db>/*). The proxy is dumb
// transport: it forwards method/path/query/body verbatim and injects the
// SurrealDB namespace/database prefix and server-side credentials, so the
// browser never holds credentials and SurrealDB's /sql surface is never exposed.
// All business logic lives in SurrealQL — this process makes no decisions.
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
const AUTH =
  "Basic " +
  Buffer.from(
    `${process.env.SURREAL_USER || "root"}:${process.env.SURREAL_PASS || "root"}`,
  ).toString("base64");

app.get("/health", (_req, res) => res.json({ status: "ok" }));

// Transparent reverse proxy: /api/<x> -> <SURREAL>/api/<ns>/<db>/<x>
app.use("/api", express.raw({ type: "*/*", limit: "5mb" }), async (req, res) => {
  const target = `${SURREAL}/api/${NS}/${DB}${req.url}`;
  try {
    const upstream = await fetch(target, {
      method: req.method,
      headers: { "content-type": "application/json", authorization: AUTH },
      body: req.method === "GET" || req.method === "HEAD" ? undefined : req.body,
    });
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
