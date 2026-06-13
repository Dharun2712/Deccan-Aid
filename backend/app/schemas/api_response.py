from typing import Generic, TypeVar, Optional, Any
from pydantic import BaseModel

DataT = TypeVar('DataT')

class APIResponse(BaseModel, Generic[DataT]):
    error: bool = False
    message: str = "Success"
    data: Optional[DataT] = None

class APIErrorResponse(BaseModel):
    error: bool = True
    message: str
    data: Optional[Any] = None
