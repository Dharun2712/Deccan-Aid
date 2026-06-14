from typing import Generic, TypeVar, List
from pydantic import BaseModel, Field

DataT = TypeVar('DataT')

class PaginationMetadata(BaseModel):
    total_items: int = Field(..., description="Total number of items available")
    total_pages: int = Field(..., description="Total number of pages available")
    current_page: int = Field(..., description="Current page number")
    per_page: int = Field(..., description="Number of items per page")
    has_next: bool = Field(..., description="Whether there is a next page")
    has_prev: bool = Field(..., description="Whether there is a previous page")

class PaginatedResponse(BaseModel, Generic[DataT]):
    items: List[DataT]
    metadata: PaginationMetadata
