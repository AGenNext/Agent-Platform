const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;
const KNOWLEDGE_URL = process.env.AGENT_KNOWLEDGE_URL || 'http://localhost:8001';
const PUBLIC_KNOWLEDGE_URL = process.env.PUBLIC_AGENT_KNOWLEDGE_URL || KNOWLEDGE_URL;

app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'agent-dashboard', version: '0.1.0' });
});

app.get('/', (_req, res) => {
  res.type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Agent Dashboard</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; }
    h1 { font-size: 1.5rem; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; background: #e0f2fe; color: #0369a1; }
    a { color: #0369a1; }
    pre { background: #f8fafc; padding: 12px; border-radius: 6px; font-size: 0.85rem; }
  </style>
</head>
<body>
  <h1>Agent Dashboard <span class="badge">stub</span></h1>
  <p>Platform environment: <strong>${process.env.PLATFORM_ENV || 'dev'}</strong></p>
  <h2>Service Links</h2>
  <ul>
    <li><a href="${PUBLIC_KNOWLEDGE_URL}/docs" target="_blank">Agent Knowledge API — Swagger UI</a></li>
    <li><a href="${PUBLIC_KNOWLEDGE_URL}/health" target="_blank">Agent Knowledge — Health</a></li>
  </ul>
  <h2>Quick Test</h2>
  <pre>curl ${PUBLIC_KNOWLEDGE_URL}/health
curl -X POST ${PUBLIC_KNOWLEDGE_URL}/objectives \\
  -H 'Content-Type: application/json' \\
  -d '{"title":"My first objective","objective_type":"generic"}'</pre>
  <p><em>This stub will be replaced by the Agent-Dashboard application.</em></p>
</body>
</html>`);
});

app.listen(PORT, () => {
  console.log(`Agent Dashboard stub running on port ${PORT}`);
  console.log(`Knowledge API (internal): ${KNOWLEDGE_URL}`);
  console.log(`Knowledge API (browser):  ${PUBLIC_KNOWLEDGE_URL}`);
});
