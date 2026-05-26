import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, patch, MagicMock
from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest.fixture(autouse=True)
def mock_db(monkeypatch):
    """Patch get_db to avoid real SurrealDB calls."""
    mock_surreal = AsyncMock()
    mock_surreal.query = AsyncMock(return_value=[{"result": []}])
    mock_surreal.create = AsyncMock(return_value=[{"id": "test:1", "status": "ok"}])
    mock_surreal.select = AsyncMock(return_value={"id": "test:1", "status": "ok"})
    mock_surreal.merge = AsyncMock(return_value={"id": "test:1", "status": "updated"})
    mock_surreal.connect = AsyncMock()
    mock_surreal.signin = AsyncMock()
    mock_surreal.use = AsyncMock()
    mock_surreal.close = AsyncMock()

    from contextlib import asynccontextmanager

    @asynccontextmanager
    async def mock_get_db():
        yield mock_surreal

    monkeypatch.setattr("app.db.get_db", mock_get_db)
    monkeypatch.setattr("app.main.get_db", mock_get_db)
    # Patch db in all submodules
    for mod in ["app.agent_team", "app.eval", "app.trust", "app.model_router", "app.frameworks", "app.startup"]:
        try:
            monkeypatch.setattr(f"{mod}.get_db", mock_get_db)
        except AttributeError:
            pass
    return mock_surreal


@pytest.fixture(autouse=True)
def mock_ping(monkeypatch):
    monkeypatch.setattr("app.main.ping", AsyncMock(return_value=True))
    monkeypatch.setattr("app.db.ping", AsyncMock(return_value=True))
