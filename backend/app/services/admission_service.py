from typing import Optional
from datetime import datetime
from ..models.admission import AdmissionModel
from ..schemas.admission import AdmissionCreate, AdmissionStatusEnum
from ..repositories.admission_repository import AdmissionRepository
from .hospital_service import HospitalService

class AdmissionService:
    def __init__(self, repository: AdmissionRepository, hospital_service: HospitalService):
        self.repository = repository
        self.hospital_service = hospital_service

    async def create_admission(self, data: AdmissionCreate) -> AdmissionModel:
        hospital = await self.hospital_service.get_hospital(data.hospitalId)
        if not hospital:
            raise ValueError("Hospital not found")

        if hospital.status == "FULL" or hospital.availableBeds <= 0:
            raise ValueError("Cannot admit to a full hospital")

        now = datetime.utcnow()
        new_admission = AdmissionModel(
            emergencyId=data.emergencyId,
            hospitalId=data.hospitalId,
            patientId=data.patientId,
            status=AdmissionStatusEnum.PENDING.value,
            admissionNotes=data.admissionNotes,
            createdAt=now,
            updatedAt=now
        )
        return await self.repository.create(new_admission)

    async def approve_admission(self, id: str) -> Optional[AdmissionModel]:
        admission = await self.repository.get_by_id(id)
        if not admission:
            raise ValueError("Admission not found")

        if admission.status == AdmissionStatusEnum.DISCHARGED.value:
            raise ValueError("Cannot approve a discharged admission")

        hospital = await self.hospital_service.get_hospital(admission.hospitalId)
        if hospital and hospital.availableBeds <= 0:
            raise ValueError("Cannot approve admission: no beds available")

        return await self.repository.update_status(id, AdmissionStatusEnum.APPROVED.value)

    async def reject_admission(self, id: str) -> Optional[AdmissionModel]:
        admission = await self.repository.get_by_id(id)
        if not admission:
            raise ValueError("Admission not found")

        if admission.status in [AdmissionStatusEnum.ADMITTED.value, AdmissionStatusEnum.DISCHARGED.value]:
            raise ValueError("Cannot reject already admitted/discharged patients")

        return await self.repository.update_status(id, AdmissionStatusEnum.REJECTED.value)
