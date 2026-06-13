from typing import List, Optional
from datetime import datetime
from ..models.driver import DriverModel
from ..schemas.driver import DriverCreate, DriverAvailabilityEnum, DriverStatusEnum
from ..repositories.driver_repository import DriverRepository

class DriverService:
    def __init__(self, repository: DriverRepository):
        self.repository = repository

    async def create_driver(self, request_data: DriverCreate) -> DriverModel:
        now = datetime.utcnow()
        new_driver = DriverModel(
            driverId=request_data.driverId,
            fullName=request_data.fullName,
            phoneNumber=request_data.phoneNumber,
            licenseNumber=request_data.licenseNumber,
            ambulanceId=request_data.ambulanceId,
            availabilityStatus=DriverAvailabilityEnum.OFFLINE.value,
            currentStatus=DriverStatusEnum.IDLE.value,
            createdAt=now,
            updatedAt=now
        )
        return await self.repository.create(new_driver)

    async def get_driver(self, driver_id: str) -> Optional[DriverModel]:
        return await self.repository.get_by_driver_id(driver_id)

    async def get_available_drivers(self) -> List[DriverModel]:
        return await self.repository.get_available_drivers()

    async def update_availability(self, driver_id: str, availability: str) -> Optional[DriverModel]:
        driver = await self.get_driver(driver_id)
        if not driver:
            raise ValueError("Driver not found")

        if driver.currentStatus not in [DriverStatusEnum.IDLE.value, DriverStatusEnum.COMPLETED.value] and availability == DriverAvailabilityEnum.AVAILABLE.value:
            raise ValueError("Cannot set to available while on an active emergency")

        update_data = {
            "availabilityStatus": availability,
            "updatedAt": datetime.utcnow()
        }
        return await self.repository.update(driver.id, update_data)

    async def update_status(self, driver_id: str, new_status: str) -> Optional[DriverModel]:
        driver = await self.get_driver(driver_id)
        if not driver:
            raise ValueError("Driver not found")

        if driver.availabilityStatus == DriverAvailabilityEnum.OFFLINE.value:
            raise ValueError("Offline drivers cannot have status updates")

        return await self.repository.update_status(driver_id, new_status)
