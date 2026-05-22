import os
from pathlib import Path

from app.db.surrealdb import db

SCHEMAS_DIR = Path(__file__).parent.parent.parent / "schemas"


async def apply_schemas() -> list[str]:
    """Apply all .surql files from the schemas directory in sorted order.

    Drop-in compatible with Agent-Backend schemas — place any .surql file in
    services/agent-knowledge-api/schemas/ and it will be applied on startup.
    """
    applied: list[str] = []
    files = sorted(SCHEMAS_DIR.glob("*.surql"))
    for path in files:
        sql = path.read_text()
        try:
            await db.query(sql)
            applied.append(path.name)
        except Exception as exc:
            # Log but don't crash — some definitions may already exist
            print(f"[schema_loader] Warning: {path.name} — {exc}")
    return applied
