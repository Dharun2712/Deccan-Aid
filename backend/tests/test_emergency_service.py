import pytest
from app.services.emergency_service import EmergencyService
from app.models.emergency import EmergencyModel
from app.schemas.emergency_request import EmergencyRequestCreate, EmergencyLocationCreate, EmergencySeverityEnum

class MockRepository:
    async def create(self, emergency: EmergencyModel):
        emergency.id = "mock_id"
        return emergency
        
    async def get_by_id(self, id: str):
        pass

@pytest.mark.asyncio
async def test_create_emergency_service():
    mock_repo = MockRepository()
    service = EmergencyService(mock_repo)
    
    request = EmergencyRequestCreate(
        user_id="user123",
        severity=EmergencySeverityEnum.HIGH,
        location=EmergencyLocationCreate(latitude=12.9716, longitude=77.5946, address="Bangalore"),
        description="Medical emergency"
    )
    
    result = await service.create_emergency(request)
    assert result.user_id == "user123"
    assert result.status == "created"
    assert result.severity == "high"
    assert result.id == "mock_id"
