"""E2E: health and root endpoints."""
import pytest


pytestmark = pytest.mark.asyncio


async def test_knowledge_health(api):
    r = await api.get("/health")
    assert r.status_code in (200, 503), r.text
    body = r.json()
    assert body["service"] == "agent-knowledge"
    assert body["surrealdb"] in ("connected", "unreachable")


async def test_knowledge_health_ok_when_db_connected(api):
    r = await api.get("/health")
    body = r.json()
    if body["surrealdb"] == "connected":
        assert r.status_code == 200
        assert body["status"] == "ok"
    else:
        pytest.skip("SurrealDB not connected — skipping ok-status assertion")


async def test_root_lists_routes(api):
    r = await api.get("/")
    assert r.status_code == 200
    body = r.json()
    assert "routes" in body
    for expected in ("/agents", "/workflows", "/objectives", "/artifacts"):
        assert expected in body["routes"]


async def test_request_id_header(api):
    r = await api.get("/health")
    assert "x-request-id" in r.headers, "RequestLoggingMiddleware should add X-Request-Id"


async def test_dashboard_health(dashboard):
    r = await dashboard.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body.get("status") == "ok"
