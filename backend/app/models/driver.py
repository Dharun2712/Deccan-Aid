from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class DriverModel(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    driverId: str
    fullName: str
    phoneNumber: str
    licenseNumber: str
    ambulanceId: str
    availabilityStatus: str
    currentStatus: str
    createdAt: datetime
    updatedAt: datetime
    
    class Config:
        populate_by_name = True
