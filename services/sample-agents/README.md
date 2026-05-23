# Sample Agents

Three production-pattern agents wired to the AGenNext platform API.

## Setup

```bash
cd services/sample-agents
pip install -r requirements.txt
cp .env.example .env
# Fill in ANTHROPIC_API_KEY and PLATFORM_API_URL
```

Make sure the platform stack is running:
```bash
cd ../..
docker compose up -d
```

## Agents

### Researcher Agent
LangGraph ReAct loop — plans queries, searches, synthesizes, writes artifact, self-evaluates via CLEAR.

```bash
python src/researcher_agent.py "What are the main use cases for SurrealDB in AI systems?"
```

**Flow:** plan → research (tool loop) → synthesize → write artifact → store memory → CLEAR evaluate

### Orchestrator Agent
LangGraph supervisor — decomposes goal into subtasks, dispatches to workers, aggregates results.

```bash
python src/orchestrator_agent.py "Build a competitive analysis for enterprise AI platforms"
```

**Flow:** plan tasks → dispatch (parallel workers) → finalize (aggregate) → artifact → CLEAR evaluate

### Memory Agent
Interactive LangChain agent with persistent episodic + semantic memory via platform API.

```bash
python src/memory_agent.py
```

**Memory tiers:**
- `working` — current session (in-process, cleared on restart)
- `episodic` — per-turn observations (importance 0.4-0.6, stored after each turn)
- `semantic` — distilled facts from notable statements (importance 0.7-1.0, persists)

## What each agent does on the platform

All three agents:
1. **Register** — `POST /agents/register` with all 8 required capabilities
2. **Create objective** — `POST /objectives/run`
3. **Store memory** — `POST /memory/` (episodic and semantic)
4. **Create artifact** — `POST /artifacts/`
5. **Evaluate (CLEAR)** — `POST /trust/evaluate`
6. **Log traces** — `POST /traces/` at each step
7. **Log usage** — `POST /billing/usage` with token counts and cost

All data appears in the dashboard immediately (Agents, Memory, Artifacts, Trace Logs, Billing, Workflow Runs).

## Platform client

`src/platform_client.py` is a standalone HTTP client for the platform API. Copy it into any agent project:

```python
from platform_client import PlatformClient

with PlatformClient() as client:
    agent = client.register_agent(name="MyAgent", description="...", ...)
    client.store_memory(agent_id=..., content="...", memory_type="episodic")
    client.trace(objective_id=..., event_type="llm.call", payload={...})
```
