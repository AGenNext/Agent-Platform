import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from surrealdb import AsyncSurreal

_URL = os.getenv("SURREALDB_URL", "ws://localhost:8000/rpc")
_NS = os.getenv("SURREALDB_NAMESPACE", "agent_platform")
_DB = os.getenv("SURREALDB_DATABASE", "agent_platform")
_USER = os.getenv("SURREALDB_USERNAME", "root")
_PASS = os.getenv("SURREALDB_PASSWORD", "root")


@asynccontextmanager
async def get_db() -> AsyncGenerator[AsyncSurreal, None]:
    db = AsyncSurreal(_URL)
    await db.connect()
    await db.signin({"username": _USER, "password": _PASS})
    await db.use(_NS, _DB)
    try:
        yield db
    finally:
        await db.close()


async def ping() -> bool:
    try:
        async with get_db() as db:
            await db.query("RETURN true")
        return True
    except Exception:
        return False
