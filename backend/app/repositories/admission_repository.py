from typing import Optional
from bson import ObjectId
from datetime import datetime
from .base_repository import BaseRepository
from ..models.admission import AdmissionModel

class AdmissionRepository(BaseRepository[AdmissionModel]):
    def __init__(self, db):
        super().__init__(db, "admissions", AdmissionModel)

    async def update_status(self, id: str, new_status: str) -> Optional[AdmissionModel]:
        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(id)},
            {"$set": {"status": new_status, "updatedAt": datetime.utcnow()}},
            return_document=True
        )
        if result:
            result["id"] = str(result.pop("_id"))
            return self.model_class(**result)
        return None
