from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ObjectiveCreate(BaseModel):
    title: str
    objective_type: str = "generic"
    workspace_id: Optional[str] = None
    payload: dict = Field(default_factory=dict)


class ObjectiveRecord(BaseModel):
    id: Optional[str] = None
    title: str
    objective_type: str
    workspace_id: Optional[str] = None
    payload: dict = Field(default_factory=dict)
    status: str = "pending"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class ArtifactCreate(BaseModel):
    objective_id: str
    artifact_type: str
    title: str
    content_ref: str
    payload: dict = Field(default_factory=dict)


class ArtifactRecord(BaseModel):
    id: Optional[str] = None
    objective_id: str
    artifact_type: str
    title: str
    content_ref: str
    payload: dict = Field(default_factory=dict)
    status: str = "draft"
    eval_status: Optional[str] = None
    trust_status: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
