import pytest
import math
from app.services.location_service import LocationService

def test_haversine_distance():
    # Test distance between two known points (e.g., NY and London)
    # NY: 40.7128, -74.0060
    # London: 51.5074, -0.1278
    # Approximate distance: ~5570 km
    
    dist_meters = LocationService.calculate_distance(40.7128, -74.0060, 51.5074, -0.1278)
    dist_km = dist_meters / 1000
    
    assert math.isclose(dist_km, 5570, rel_tol=0.05) # 5% tolerance
