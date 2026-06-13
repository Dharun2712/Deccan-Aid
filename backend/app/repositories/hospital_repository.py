from typing import Optional
from bson import ObjectId
from datetime import datetime
from .base_repository import BaseRepository
from ..models.hospital import HospitalModel

class HospitalRepository(BaseRepository[HospitalModel]):
    def __init__(self, db):
        super().__init__(db, "hospitals", HospitalModel)

    async def get_by_hospital_id(self, hospital_id: str) -> Optional[HospitalModel]:
        doc = await self.collection.find_one({"hospitalId": hospital_id})
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return self.model_class(**doc)
        return None

    async def update_capacity(self, id: str, beds: int, icu_beds: int, emergency_beds: int) -> Optional[HospitalModel]:
        update_data = {
            "availableBeds": beds,
            "availableICUBeds": icu_beds,
            "availableEmergencyBeds": emergency_beds,
            "updatedAt": datetime.utcnow()
        }
        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(id)},
            {"$set": update_data},
            return_document=True
        )
        if result:
            result["id"] = str(result.pop("_id"))
            return self.model_class(**result)
        return None
