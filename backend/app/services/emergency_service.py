from typing import List, Optional
from datetime import datetime
from ..models.emergency import EmergencyModel, EmergencyLocation
from ..schemas.emergency_request import EmergencyRequestCreate
from ..repositories.emergency_repository import EmergencyRepository

class EmergencyService:
    def __init__(self, repository: EmergencyRepository):
        self.repository = repository

    async def create_emergency(self, request_data: EmergencyRequestCreate) -> EmergencyModel:
        # In a real app, validation logic would reside here or in a validator class
        now = datetime.utcnow()
        new_emergency = EmergencyModel(
            user_id=request_data.user_id,
            status="created",
            severity=request_data.severity.value,
            location=EmergencyLocation(
                latitude=request_data.location.latitude,
                longitude=request_data.location.longitude,
                address=request_data.location.address
            ),
            description=request_data.description,
            created_at=now,
            updated_at=now
        )
        return await self.repository.create(new_emergency)

    async def get_emergency(self, emergency_id: str) -> Optional[EmergencyModel]:
        return await self.repository.get_by_id(emergency_id)

    async def list_emergencies(self, skip: int = 0, limit: int = 100) -> List[EmergencyModel]:
        return await self.repository.get_all(skip=skip, limit=limit)

    async def cancel_emergency(self, emergency_id: str) -> Optional[EmergencyModel]:
        emergency = await self.get_emergency(emergency_id)
        if not emergency:
            raise ValueError("Emergency not found")

        if emergency.status in ["completed", "cancelled"]:
            raise ValueError(f"Cannot cancel emergency in status: {emergency.status}")

        update_data = {
            "status": "cancelled",
            "updated_at": datetime.utcnow()
        }
        return await self.repository.update(emergency_id, update_data)
