from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class EmergencyLocationResponse(BaseModel):
    latitude: float
    longitude: float
    address: Optional[str] = None

class EmergencyResponse(BaseModel):
    id: str
    user_id: str
    status: str
    severity: str
    location: EmergencyLocationResponse
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
