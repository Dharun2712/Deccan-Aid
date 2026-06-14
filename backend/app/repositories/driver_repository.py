from typing import List, Optional
from bson import ObjectId
from .base_repository import BaseRepository
from ..models.driver import DriverModel

class DriverRepository(BaseRepository[DriverModel]):
    def __init__(self, db):
        super().__init__(db, "drivers", DriverModel)

    async def get_by_driver_id(self, driver_id: str) -> Optional[DriverModel]:
        doc = await self.collection.find_one({"driverId": driver_id})
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return self.model_class(**doc)
        return None

    async def get_available_drivers(self) -> List[DriverModel]:
        cursor = self.collection.find({"availabilityStatus": "AVAILABLE"})
        results = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            results.append(self.model_class(**doc))
        return results

    async def update_status(self, driver_id: str, new_status: str) -> Optional[DriverModel]:
        result = await self.collection.find_one_and_update(
            {"driverId": driver_id},
            {"$set": {"currentStatus": new_status, "updatedAt": datetime.utcnow()}},
            return_document=True
        )
        if result:
            result["id"] = str(result.pop("_id"))
            return self.model_class(**result)
        return None
