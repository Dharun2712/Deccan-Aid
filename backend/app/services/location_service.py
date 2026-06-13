import math
from typing import Optional
from ..repositories.location_repository import LocationRepository, RouteRepository
from ..models.location import GeoLocationModel, RouteInfoModel
from ..schemas.location import GeoLocationSchema, RouteInfoSchema

class LocationService:
    def __init__(self, location_repo: LocationRepository, route_repo: RouteRepository):
        self.location_repo = location_repo
        self.route_repo = route_repo

    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        # Haversine formula
        R = 6371.0
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        
        a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        
        return R * c * 1000  # meters

    async def get_or_create_route(self, origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float) -> RouteInfoModel:
        # First check if route exists in DB
        route = await self.route_repo.find_route(origin_lat, origin_lng, dest_lat, dest_lng)
        if route:
            return route

        # If not, calculate distance and create a mock route (in production, call Google Maps Directions API)
        distance = self.calculate_distance(origin_lat, origin_lng, dest_lat, dest_lng)
        
        new_route = RouteInfoModel(
            origin={"latitude": origin_lat, "longitude": origin_lng},
            destination={"latitude": dest_lat, "longitude": dest_lng},
            distanceMeters=distance,
            durationSeconds=int((distance / 1000) * 120),  # rough estimate 2 mins per km
            polyline="mock_encoded_polyline",
            routeName="Generated Route"
        )
        return await self.route_repo.create(new_route)

    async def get_location_by_address(self, address: str) -> Optional[GeoLocationModel]:
        return await self.location_repo.get_by_address(address)
