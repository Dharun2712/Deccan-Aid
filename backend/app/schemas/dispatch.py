from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import datetime

class DispatchStatusEnum(str, Enum):
    CREATED = "CREATED"
    ASSIGNED = "ASSIGNED"
    ACCEPTED = "ACCEPTED"
    EN_ROUTE = "EN_ROUTE"
    ARRIVED = "ARRIVED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"

class DispatchCreate(BaseModel):
    emergencyId: str
    driverId: str
    hospitalId: str

class DispatchResponse(BaseModel):
    id: str
    emergencyId: str
    driverId: str
    hospitalId: str
    status: str
    assignedAt: Optional[datetime] = None
    acceptedAt: Optional[datetime] = None
    completedAt: Optional[datetime] = None
    createdAt: datetime
    updatedAt: datetime

    class Config:
        from_attributes = True
