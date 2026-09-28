// Agent Platform dashboard server: serves the built Vite SPA from ./public with
// a health endpoint and SPA history fallback. The /api routes are handled by
// the ingress (routed to agent-knowledge), not here.
const path = require("path");
const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;
const publicDir = path.join(__dirname, "public");

app.get("/health", (_req, res) => res.json({ status: "ok" }));

app.use(express.static(publicDir));

// SPA history fallback — every non-asset route serves index.html.
app.get("*", (_req, res) => res.sendFile(path.join(publicDir, "index.html")));

app.listen(PORT, () => console.log(`agent-dashboard listening on :${PORT}`));
