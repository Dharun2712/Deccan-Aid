from typing import Optional
from bson import ObjectId
from .base_repository import BaseRepository
from ..models.location import GeoLocationModel, RouteInfoModel

class LocationRepository(BaseRepository[GeoLocationModel]):
    def __init__(self, db):
        super().__init__(db, "locations", GeoLocationModel)

    async def get_by_address(self, address: str) -> Optional[GeoLocationModel]:
        doc = await self.collection.find_one({"address": address})
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return self.model_class(**doc)
        return None

class RouteRepository(BaseRepository[RouteInfoModel]):
    def __init__(self, db):
        super().__init__(db, "routes", RouteInfoModel)

    # Simplified mock method to find an existing route
    async def find_route(self, origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float) -> Optional[RouteInfoModel]:
        doc = await self.collection.find_one({
            "origin.latitude": origin_lat,
            "origin.longitude": origin_lng,
            "destination.latitude": dest_lat,
            "destination.longitude": dest_lng
        })
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return self.model_class(**doc)
        return None
