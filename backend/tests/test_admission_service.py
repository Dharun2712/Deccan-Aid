import pytest
from app.services.admission_service import AdmissionService
from app.models.hospital import HospitalModel
from app.schemas.admission import AdmissionCreate, AdmissionStatusEnum

class MockHospitalService:
    async def get_hospital(self, id: str):
        return HospitalModel(
            hospitalId="H-1",
            name="Test Hospital",
            phoneNumber="123",
            email="test@test.com",
            address="Test Addr",
            latitude=0.0,
            longitude=0.0,
            totalBeds=10,
            availableBeds=0, # Full!
            totalICUBeds=5,
            availableICUBeds=5,
            totalEmergencyBeds=5,
            availableEmergencyBeds=5,
            status="FULL",
            createdAt="2023-01-01T00:00:00Z",
            updatedAt="2023-01-01T00:00:00Z"
        )

class MockAdmissionRepo:
    async def create(self, admission):
        return admission

@pytest.mark.asyncio
async def test_create_admission_full_hospital():
    mock_hospital_svc = MockHospitalService()
    mock_repo = MockAdmissionRepo()
    service = AdmissionService(mock_repo, mock_hospital_svc)

    request = AdmissionCreate(
        emergencyId="E-1",
        hospitalId="H-1",
        patientId="P-1"
    )

    with pytest.raises(ValueError, match="Cannot admit to a full hospital"):
        await service.create_admission(request)
