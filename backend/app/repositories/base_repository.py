from typing import Generic, TypeVar, List, Optional, Dict, Any
from bson import ObjectId
from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)

class BaseRepository(Generic[T]):
    def __init__(self, db, collection_name: str, model_class: type[T]):
        self.collection = db[collection_name]
        self.model_class = model_class

    async def get_by_id(self, id: str) -> Optional[T]:
        doc = await self.collection.find_one({"_id": ObjectId(id)})
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return self.model_class(**doc)
        return None

    async def get_all(self, skip: int = 0, limit: int = 100) -> List[T]:
        cursor = self.collection.find().skip(skip).limit(limit)
        results = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            results.append(self.model_class(**doc))
        return results

    async def create(self, item: T) -> T:
        item_dict = item.model_dump(exclude={"id"}, exclude_unset=True)
        result = await self.collection.insert_one(item_dict)
        item_dict["id"] = str(result.inserted_id)
        return self.model_class(**item_dict)

    async def update(self, id: str, item_data: Dict[str, Any]) -> Optional[T]:
        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(id)},
            {"$set": item_data},
            return_document=True
        )
        if result:
            result["id"] = str(result.pop("_id"))
            return self.model_class(**result)
        return None

    async def delete(self, id: str) -> bool:
        result = await self.collection.delete_one({"_id": ObjectId(id)})
        return result.deleted_count > 0
