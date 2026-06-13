from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class HospitalModel(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    hospitalId: str
    name: str
    phoneNumber: str
    email: str
    address: str
    latitude: float
    longitude: float
    totalBeds: int
    availableBeds: int
    totalICUBeds: int
    availableICUBeds: int
    totalEmergencyBeds: int
    availableEmergencyBeds: int
    status: str
    createdAt: datetime
    updatedAt: datetime
    
    class Config:
        populate_by_name = True
