from typing import List, Optional
from bson import ObjectId
from .base_repository import BaseRepository
from ..models.emergency import EmergencyModel

class EmergencyRepository(BaseRepository[EmergencyModel]):
    def __init__(self, db):
        super().__init__(db, "emergencies", EmergencyModel)

    async def get_by_user_id(self, user_id: str, skip: int = 0, limit: int = 100) -> List[EmergencyModel]:
        cursor = self.collection.find({"user_id": user_id}).skip(skip).limit(limit)
        results = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            results.append(EmergencyModel(**doc))
        return results

    async def get_by_status(self, status: str, skip: int = 0, limit: int = 100) -> List[EmergencyModel]:
        cursor = self.collection.find({"status": status}).skip(skip).limit(limit)
        results = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            results.append(EmergencyModel(**doc))
        return results
