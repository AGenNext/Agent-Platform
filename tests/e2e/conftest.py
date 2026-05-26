"""
Shared fixtures for e2e tests.

Set these env vars before running:
  E2E_API_URL      - base URL for agent-knowledge  (default: http://localhost:8001)
  E2E_DASHBOARD_URL - base URL for agent-dashboard (default: http://localhost:3000)
  E2E_API_KEY      - API key matching PLATFORM_API_KEYS  (default: empty = auth disabled)
"""
import os
import pytest
import pytest_asyncio
import httpx

API_BASE = os.getenv("E2E_API_URL", "http://localhost:8001")
DASHBOARD_BASE = os.getenv("E2E_DASHBOARD_URL", "http://localhost:3000")
API_KEY = os.getenv("E2E_API_KEY", "")


def auth_headers() -> dict:
    h = {}
    if API_KEY:
        h["X-API-Key"] = API_KEY
    return h


def bare_id(full_id: str) -> str:
    """Strip SurrealDB table prefix: 'agents:abc123' → 'abc123'."""
    return full_id.split(":", 1)[1] if ":" in full_id else full_id


@pytest_asyncio.fixture(scope="module")
async def api():
    """Async HTTP client aimed at agent-knowledge. Skips module if unreachable."""
    try:
        async with httpx.AsyncClient(base_url=API_BASE, timeout=5) as probe:
            await probe.get("/health")
    except (httpx.ConnectError, httpx.TimeoutException):
        pytest.skip(f"agent-knowledge not reachable at {API_BASE} — run ./scripts/dev.sh first")

    async with httpx.AsyncClient(
        base_url=API_BASE,
        headers=auth_headers(),
        timeout=15,
    ) as client:
        yield client


@pytest_asyncio.fixture(scope="module")
async def api_no_auth():
    """Client without auth headers — used to verify 401 behaviour."""
    try:
        async with httpx.AsyncClient(base_url=API_BASE, timeout=5) as probe:
            await probe.get("/health")
    except (httpx.ConnectError, httpx.TimeoutException):
        pytest.skip(f"agent-knowledge not reachable at {API_BASE}")

    async with httpx.AsyncClient(base_url=API_BASE, timeout=15) as client:
        yield client


@pytest_asyncio.fixture(scope="module")
async def dashboard():
    """Async HTTP client aimed at agent-dashboard. Skips module if unreachable."""
    try:
        async with httpx.AsyncClient(base_url=DASHBOARD_BASE, timeout=5) as probe:
            await probe.get("/health")
    except (httpx.ConnectError, httpx.TimeoutException):
        pytest.skip(f"agent-dashboard not reachable at {DASHBOARD_BASE} — run ./scripts/dev.sh first")

    async with httpx.AsyncClient(base_url=DASHBOARD_BASE, timeout=15) as client:
        yield client
