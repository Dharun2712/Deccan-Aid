import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "SmartAid Backend"}

# NOTE: In a real integration test suite, you'd use a mock DB or test DB fixture.
# Here we just establish the test file structure as requested.

def test_create_emergency_validation():
    # Test creating an emergency with invalid data
    response = client.post("/emergencies", json={
        "user_id": "",
        "severity": "invalid",
        "location": {"latitude": 200.0, "longitude": 200.0} # Invalid coordinates
    })
    # FastAPI pydantic validation should catch this
    assert response.status_code == 422
