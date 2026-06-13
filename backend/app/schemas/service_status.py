from pydantic import BaseModel
from typing import Dict, Any

class ServiceStatus(BaseModel):
    service: str
    status: str
    dependencies: Dict[str, str]
    timestamp: str
