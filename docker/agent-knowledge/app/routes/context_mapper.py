from typing import List, Optional
from fastapi import APIRouter
from pydantic import BaseModel

from ..context_mapper import map_context

router = APIRouter(prefix="/context-map", tags=["context-mapper"])


class ContextMapRequest(BaseModel):
    query: str
    workspace_id: Optional[str] = None
    top_kbs: int = 10


@router.post("")
async def api_map_context(body: ContextMapRequest):
    return await map_context(body.query, body.workspace_id, body.top_kbs)
