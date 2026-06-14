import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_dispatch_endpoints_exist():
    # Will throw 422 because body is missing, but it proves the route is there
    response = client.post("/dispatches", json={})
    assert response.status_code == 422
