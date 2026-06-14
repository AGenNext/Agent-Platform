import sys
import yaml
from pathlib import Path
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

APP_ROOT = Path(__file__).resolve().parents[3]
BLUEPRINT_ROOT = APP_ROOT / "blueprints" / "agents"

app = FastAPI(title="AGenNext Agent Runtime", version="0.1.0")


class AgentRunRequest(BaseModel):
    agent_id: str
    objective: str
    dry_run: bool = True


def load_agents():
    agents = []
    for path in BLUEPRINT_ROOT.glob("*-agent/agent.yaml"):
        with open(path, "r", encoding="utf-8") as f:
            agents.append(yaml.safe_load(f))
    return agents


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/agents")
def list_agents():
    return {"agents": load_agents()}


@app.post("/runs")
def run_agent(req: AgentRunRequest):
    spec_path = BLUEPRINT_ROOT / req.agent_id / "agent.yaml"
    if not spec_path.exists():
        raise HTTPException(status_code=404, detail="agent blueprint not found")
    with open(spec_path, "r", encoding="utf-8") as f:
        spec = yaml.safe_load(f)
    return {
        "agent_id": req.agent_id,
        "objective": req.objective,
        "dry_run": req.dry_run,
        "runtime_loop": spec["runtime"]["loop"],
        "status": "plan_generated",
        "approval_required": False,
        "evidence_required": True
    }


def self_test():
    agents = load_agents()
    assert len(agents) >= 9
    assert all(agent["type"] == "real-agent" for agent in agents)
    print("runtime self-test: ok")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
