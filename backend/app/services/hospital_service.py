from typing import List, Optional
from datetime import datetime
from ..models.hospital import HospitalModel
from ..schemas.hospital import HospitalCreate, HospitalStatusEnum, CapacityUpdate
from ..repositories.hospital_repository import HospitalRepository

class HospitalService:
    def __init__(self, repository: HospitalRepository):
        self.repository = repository

    async def create_hospital(self, data: HospitalCreate) -> HospitalModel:
        now = datetime.utcnow()
        new_hospital = HospitalModel(
            hospitalId=data.hospitalId,
            name=data.name,
            phoneNumber=data.phoneNumber,
            email=data.email,
            address=data.address,
            latitude=data.latitude,
            longitude=data.longitude,
            totalBeds=data.totalBeds,
            availableBeds=data.availableBeds,
            totalICUBeds=data.totalICUBeds,
            availableICUBeds=data.availableICUBeds,
            totalEmergencyBeds=data.totalEmergencyBeds,
            availableEmergencyBeds=data.availableEmergencyBeds,
            status=data.status.value,
            createdAt=now,
            updatedAt=now
        )
        return await self.repository.create(new_hospital)

    async def get_hospital(self, id: str) -> Optional[HospitalModel]:
        return await self.repository.get_by_id(id)

    async def get_all_hospitals(self) -> List[HospitalModel]:
        return await self.repository.get_all()

    async def update_capacity(self, id: str, capacity_data: CapacityUpdate) -> Optional[HospitalModel]:
        hospital = await self.get_hospital(id)
        if not hospital:
            raise ValueError("Hospital not found")

        beds = capacity_data.availableBeds if capacity_data.availableBeds is not None else hospital.availableBeds
        icu_beds = capacity_data.availableICUBeds if capacity_data.availableICUBeds is not None else hospital.availableICUBeds
        emergency_beds = capacity_data.availableEmergencyBeds if capacity_data.availableEmergencyBeds is not None else hospital.availableEmergencyBeds

        if beds < 0 or icu_beds < 0 or emergency_beds < 0:
            raise ValueError("Capacity cannot be negative")
        
        if beds > hospital.totalBeds or icu_beds > hospital.totalICUBeds or emergency_beds > hospital.totalEmergencyBeds:
            raise ValueError("Available beds cannot exceed total beds")

        return await self.repository.update_capacity(id, beds, icu_beds, emergency_beds)
