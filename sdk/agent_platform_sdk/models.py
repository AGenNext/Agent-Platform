from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class HealthStatus(BaseModel):
    status: str
    service: str
    version: str
    surrealdb: str
    env: Optional[str] = None


class ObjectiveCreate(BaseModel):
    title: str
    objective_type: str = "generic"
    workspace_id: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)


class ObjectiveRecord(BaseModel):
    id: Optional[str] = None
    title: str
    objective_type: str
    workspace_id: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)
    status: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ArtifactCreate(BaseModel):
    objective_id: str
    artifact_type: str
    title: str
    content_ref: str
    payload: Dict[str, Any] = Field(default_factory=dict)


class ArtifactRecord(BaseModel):
    id: Optional[str] = None
    objective_id: str
    artifact_type: str
    title: str
    content_ref: str
    payload: Dict[str, Any] = Field(default_factory=dict)
    status: str
    eval_status: Optional[str] = None
    trust_status: Optional[str] = None
    created_at: Optional[datetime] = None


class RunResult(BaseModel):
    objective_id: str
    status: str
    message: str
