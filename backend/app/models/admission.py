from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class AdmissionModel(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    emergencyId: str
    hospitalId: str
    patientId: str
    status: str
    admissionNotes: Optional[str] = None
    createdAt: datetime
    updatedAt: datetime
    
    class Config:
        populate_by_name = True
