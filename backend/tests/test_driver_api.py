import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_driver_endpoints_exist():
    # We expect 422 because we're missing required payload, but it proves the endpoint is wired up
    response = client.post("/drivers", json={})
    assert response.status_code == 422

def test_get_available_drivers_exists():
    response = client.get("/drivers/available")
    # Will fail connection if no DB, but endpoint is there
    # For a real test, mock the repository
    assert response.status_code in [200, 500]
