import os
from typing import Any

from surrealdb import AsyncSurreal


class SurrealDB:
    def __init__(self) -> None:
        self._client: AsyncSurreal | None = None
        self._url = os.getenv("SURREALDB_URL", "ws://localhost:8000/rpc")
        self._ns = os.getenv("SURREALDB_NAMESPACE", "agent_platform")
        self._db = os.getenv("SURREALDB_DATABASE", "agent_platform")
        self._user = os.getenv("SURREALDB_USERNAME", "root")
        self._pass = os.getenv("SURREALDB_PASSWORD", "root")

    async def connect(self) -> None:
        self._client = AsyncSurreal(self._url)
        await self._client.connect()
        await self._client.signin({"username": self._user, "password": self._pass})
        await self._client.use(self._ns, self._db)

    async def close(self) -> None:
        if self._client:
            await self._client.close()

    async def create(self, table: str, data: dict[str, Any]) -> Any:
        assert self._client, "DB not connected"
        return await self._client.create(table, data)

    async def query(self, sql: str, vars: dict[str, Any] | None = None) -> Any:
        assert self._client, "DB not connected"
        return await self._client.query(sql, vars or {})

    @property
    def ready(self) -> bool:
        return self._client is not None


db = SurrealDB()
