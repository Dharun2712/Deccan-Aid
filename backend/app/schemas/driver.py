from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import datetime

class DriverAvailabilityEnum(str, Enum):
    AVAILABLE = "AVAILABLE"
    BUSY = "BUSY"
    OFFLINE = "OFFLINE"

class DriverStatusEnum(str, Enum):
    IDLE = "IDLE"
    ASSIGNED = "ASSIGNED"
    EN_ROUTE = "EN_ROUTE"
    ON_SCENE = "ON_SCENE"
    COMPLETED = "COMPLETED"

class DriverCreate(BaseModel):
    driverId: str
    fullName: str
    phoneNumber: str
    licenseNumber: str
    ambulanceId: str

class DriverResponse(BaseModel):
    id: str
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
        from_attributes = True
