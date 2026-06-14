from typing import Optional, List
from bson import ObjectId
from datetime import datetime
from .base_repository import BaseRepository
from ..models.dispatch import DispatchModel

class DispatchRepository(BaseRepository[DispatchModel]):
    def __init__(self, db):
        super().__init__(db, "dispatches", DispatchModel)

    async def get_active_dispatch_for_emergency(self, emergency_id: str) -> Optional[DispatchModel]:
        doc = await self.collection.find_one({
            "emergencyId": emergency_id,
            "status": {"$nin": ["COMPLETED", "CANCELLED"]}
        })
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return self.model_class(**doc)
        return None

    async def get_active_dispatch_for_driver(self, driver_id: str) -> Optional[DispatchModel]:
        doc = await self.collection.find_one({
            "driverId": driver_id,
            "status": {"$nin": ["COMPLETED", "CANCELLED"]}
        })
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return self.model_class(**doc)
        return None

    async def update_status(self, id: str, status: str, timestamp_field: Optional[str] = None) -> Optional[DispatchModel]:
        update_data = {"status": status, "updatedAt": datetime.utcnow()}
        if timestamp_field:
            update_data[timestamp_field] = datetime.utcnow()

        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(id)},
            {"$set": update_data},
            return_document=True
        )
        if result:
            result["id"] = str(result.pop("_id"))
            return self.model_class(**result)
        return None
