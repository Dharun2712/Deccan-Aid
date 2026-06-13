from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class EmergencyLocation(BaseModel):
    latitude: float
    longitude: float
    address: Optional[str] = None

class EmergencyModel(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    status: str
    severity: str
    location: EmergencyLocation
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        populate_by_name = True
