from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import datetime

class AdmissionStatusEnum(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    ADMITTED = "ADMITTED"
    DISCHARGED = "DISCHARGED"

class AdmissionCreate(BaseModel):
    emergencyId: str
    hospitalId: str
    patientId: str
    admissionNotes: Optional[str] = None

class AdmissionResponse(BaseModel):
    id: str
    emergencyId: str
    hospitalId: str
    patientId: str
    status: str
    admissionNotes: Optional[str] = None
    createdAt: datetime
    updatedAt: datetime

    class Config:
        from_attributes = True
