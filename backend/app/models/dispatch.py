from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class DispatchModel(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
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
        populate_by_name = True
