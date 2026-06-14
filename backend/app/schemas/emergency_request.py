from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum

class EmergencySeverityEnum(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class EmergencyLocationCreate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address: Optional[str] = None

class EmergencyRequestCreate(BaseModel):
    user_id: str
    severity: EmergencySeverityEnum
    location: EmergencyLocationCreate
    description: Optional[str] = None
