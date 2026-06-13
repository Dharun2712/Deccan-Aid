from typing import Optional
from ..repositories.driver_repository import DriverRepository
from ..repositories.hospital_repository import HospitalRepository
from ..repositories.emergency_repository import EmergencyRepository

class AssignmentEngine:
    def __init__(
        self,
        driver_repository: DriverRepository,
        hospital_repository: HospitalRepository,
        emergency_repository: EmergencyRepository
    ):
        self.driver_repository = driver_repository
        self.hospital_repository = hospital_repository
        self.emergency_repository = emergency_repository

    async def validate_assignment(self, emergency_id: str, driver_id: str, hospital_id: str):
        # Validate Emergency
        emergency = await self.emergency_repository.get_by_id(emergency_id)
        if not emergency:
            raise ValueError("Emergency not found")
        if emergency.status in ["completed", "cancelled"]:
            raise ValueError("Cannot assign to an inactive emergency")

        # Validate Driver
        driver = await self.driver_repository.get_by_driver_id(driver_id)
        if not driver:
            raise ValueError("Driver not found")
        if driver.availabilityStatus != "AVAILABLE":
            raise ValueError("Driver is not available for dispatch")

        # Validate Hospital
        hospital = await self.hospital_repository.get_by_hospital_id(hospital_id)
        if not hospital:
            raise ValueError("Hospital not found")
        if hospital.status == "FULL" or hospital.availableBeds <= 0:
            raise ValueError("Hospital is full, cannot accept dispatch")
        
        return True
