export function renderMvpHtml(): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Autonomyx MVP</title>
  <style>
    :root { color-scheme: light dark; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    body { margin: 0; background: #f7f9fc; color: #101828; }
    header { padding: 28px 32px; background: #0f172a; color: white; }
    main { padding: 28px 32px; display: grid; gap: 20px; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); }
    h1 { margin: 0 0 8px; font-size: 28px; }
    h2 { margin-top: 0; }
    .card { background: white; border: 1px solid #e5e7eb; border-radius: 16px; padding: 20px; box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06); }
    code, pre { background: #0f172a; color: #d1e7ff; border-radius: 10px; padding: 12px; overflow: auto; }
    button { background: #0f172a; color: white; border: 0; border-radius: 10px; padding: 10px 14px; cursor: pointer; }
    input, textarea, select { width: 100%; box-sizing: border-box; border: 1px solid #d0d5dd; border-radius: 10px; padding: 10px; margin: 6px 0 12px; }
    .ok { color: #027a48; font-weight: 700; }
    .bad { color: #b42318; font-weight: 700; }
    @media (prefers-color-scheme: dark) { body { background: #020617; color: #e5e7eb; } .card { background: #0f172a; border-color: #1e293b; } }
  </style>
</head>
<body>
  <header>
    <h1>Autonomyx MVP Control Plane</h1>
    <div>Domain-bound · policy-governed · graph-backed · certified execution</div>
  </header>
  <main>
    <section class="card">
      <h2>Health</h2>
      <p id="health">Loading...</p>
      <button onclick="loadHealth()">Refresh</button>
    </section>
    <section class="card">
      <h2>Stack Apps</h2>
      <pre id="apps">Loading...</pre>
      <button onclick="loadApps()">Refresh</button>
    </section>
    <section class="card">
      <h2>Execute</h2>
      <label>Domain</label>
      <input id="domain" value="platform" />
      <label>Operation</label>
      <select id="op"><option>⊕</option><option>⊖</option><option>⊗</option><option>÷</option></select>
      <label>Payload JSON</label>
      <textarea id="payload" rows="8">{"@id":"publication:mvp","@type":"AutonomyxPublication","title":"MVP publication","immutable":true}</textarea>
      <button onclick="execute()">Run</button>
      <pre id="executeResult"></pre>
    </section>
    <section class="card">
      <h2>State</h2>
      <pre id="state">Loading...</pre>
      <button onclick="loadState()">Refresh</button>
    </section>
  </main>
<script>
async function getJson(path) { const res = await fetch(path); return res.json(); }
async function loadHealth() { const data = await getJson('/healthz'); document.getElementById('health').innerHTML = data.status === 'ok' ? '<span class="ok">ok</span>' : '<span class="bad">bad</span>'; }
async function loadApps() { document.getElementById('apps').textContent = JSON.stringify(await getJson('/api/apps'), null, 2); }
async function loadState() { document.getElementById('state').textContent = JSON.stringify(await getJson('/api/state'), null, 2); }
async function execute() {
  const payload = JSON.parse(document.getElementById('payload').value);
  const body = { domain: document.getElementById('domain').value, op: document.getElementById('op').value, payload };
  const res = await fetch('/api/execute', { method: 'POST', headers: { 'content-type': 'application/json', 'x-oidc-subject': 'mvp-operator' }, body: JSON.stringify(body) });
  document.getElementById('executeResult').textContent = JSON.stringify(await res.json(), null, 2);
  await loadState();
}
loadHealth(); loadApps(); loadState();
</script>
</body>
</html>`;
}
