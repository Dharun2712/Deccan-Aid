from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import datetime

class HospitalStatusEnum(str, Enum):
    ACTIVE = "ACTIVE"
    BUSY = "BUSY"
    FULL = "FULL"
    OFFLINE = "OFFLINE"

class HospitalCreate(BaseModel):
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
    status: HospitalStatusEnum

class HospitalResponse(BaseModel):
    id: str
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
        from_attributes = True

class CapacityUpdate(BaseModel):
    availableBeds: Optional[int] = None
    availableICUBeds: Optional[int] = None
    availableEmergencyBeds: Optional[int] = None
