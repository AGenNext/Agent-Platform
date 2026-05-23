from datetime import datetime
from enum import Enum
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field

SCHEMA_CONTEXT = "https://schema.org"


class ObjectiveStatus(str, Enum):
    pending = "pending"
    running = "running"
    completed = "completed"
    failed = "failed"


class ObjectiveRequest(BaseModel):
    goal: str = Field(..., description="The objective goal (schema:description of the Action)")
    context: dict[str, Any] = Field(default_factory=dict)
    priority: int = Field(default=1, ge=1, le=10)
    # Optional Schema.org type override — defaults to schema:Action
    schema_type: str = Field(default="Action")


class ObjectiveRecord(BaseModel):
    """Stored as JSON-LD in SurrealDB. Schema.org Action is the base type."""

    id: str = Field(default_factory=lambda: str(uuid4()))

    # JSON-LD fields
    json_ld_context: str = Field(default=SCHEMA_CONTEXT, alias="@context")
    json_ld_type: str = Field(default="Action", alias="@type")

    # schema:Action fields
    name: str = Field(default="")
    description: str = Field(default="")

    # Platform fields
    goal: str
    agent_context: dict[str, Any] = Field(default_factory=dict)
    priority: int = 1
    status: ObjectiveStatus = ObjectiveStatus.pending
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    result: dict[str, Any] | None = None
    error: str | None = None

    model_config = {"populate_by_name": True}

    @classmethod
    def from_request(cls, req: ObjectiveRequest) -> "ObjectiveRecord":
        return cls(
            goal=req.goal,
            name=req.goal[:80],
            description=req.goal,
            agent_context=req.context,
            priority=req.priority,
            **{"@type": req.schema_type},
        )

    def to_jsonld(self) -> dict[str, Any]:
        return {
            "@context": SCHEMA_CONTEXT,
            "@type": self.json_ld_type,
            "@id": f"urn:agent-platform:objective:{self.id}",
            "name": self.name,
            "description": self.description,
            "actionStatus": self.status.value,
            "startTime": self.created_at.isoformat(),
            "endTime": self.updated_at.isoformat(),
            "result": self.result,
            "_meta": {
                "id": self.id,
                "priority": self.priority,
                "context": self.agent_context,
            },
        }


class ObjectiveResponse(BaseModel):
    objective: ObjectiveRecord
    jsonld: dict[str, Any]
    message: str
