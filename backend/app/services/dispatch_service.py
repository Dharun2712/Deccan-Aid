from typing import Optional
from datetime import datetime
from ..models.dispatch import DispatchModel
from ..schemas.dispatch import DispatchCreate, DispatchStatusEnum
from ..repositories.dispatch_repository import DispatchRepository
from .assignment_engine import AssignmentEngine
from ..services.driver_service import DriverService

class DispatchService:
    def __init__(self, repository: DispatchRepository, engine: AssignmentEngine, driver_service: DriverService):
        self.repository = repository
        self.engine = engine
        self.driver_service = driver_service

    async def create_dispatch(self, data: DispatchCreate) -> DispatchModel:
        # Check if already active dispatch
        active_emergency = await self.repository.get_active_dispatch_for_emergency(data.emergencyId)
        if active_emergency:
            raise ValueError("Emergency already has an active dispatch")

        active_driver = await self.repository.get_active_dispatch_for_driver(data.driverId)
        if active_driver:
            raise ValueError("Driver already has an active dispatch")

        # Validate eligibility through Engine
        await self.engine.validate_assignment(data.emergencyId, data.driverId, data.hospitalId)

        now = datetime.utcnow()
        new_dispatch = DispatchModel(
            emergencyId=data.emergencyId,
            driverId=data.driverId,
            hospitalId=data.hospitalId,
            status=DispatchStatusEnum.CREATED.value,
            createdAt=now,
            updatedAt=now
        )

        dispatch = await self.repository.create(new_dispatch)
        
        # Optionally reserve driver immediately
        await self.driver_service.update_status(data.driverId, "ASSIGNED")
        return dispatch

    async def accept_dispatch(self, id: str) -> Optional[DispatchModel]:
        dispatch = await self.repository.get_by_id(id)
        if not dispatch:
            raise ValueError("Dispatch not found")
        if dispatch.status != DispatchStatusEnum.CREATED.value:
            raise ValueError("Can only accept CREATED dispatches")

        return await self.repository.update_status(id, DispatchStatusEnum.ACCEPTED.value, timestamp_field="acceptedAt")

    async def complete_dispatch(self, id: str) -> Optional[DispatchModel]:
        dispatch = await self.repository.get_by_id(id)
        if not dispatch:
            raise ValueError("Dispatch not found")

        result = await self.repository.update_status(id, DispatchStatusEnum.COMPLETED.value, timestamp_field="completedAt")
        
        # Free up the driver
        await self.driver_service.update_status(dispatch.driverId, "COMPLETED")
        return result

    async def cancel_dispatch(self, id: str) -> Optional[DispatchModel]:
        dispatch = await self.repository.get_by_id(id)
        if not dispatch:
            raise ValueError("Dispatch not found")
        if dispatch.status in [DispatchStatusEnum.COMPLETED.value, DispatchStatusEnum.CANCELLED.value]:
            raise ValueError("Cannot cancel completed or already cancelled dispatch")

        result = await self.repository.update_status(id, DispatchStatusEnum.CANCELLED.value)
        
        # Free up the driver
        await self.driver_service.update_status(dispatch.driverId, "IDLE")
        return result
