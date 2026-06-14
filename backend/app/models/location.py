from typing import Optional
from pydantic import BaseModel, Field

class CoordinateModel(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class GeoLocationModel(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    coordinate: CoordinateModel
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    postalCode: Optional[str] = None

    class Config:
        populate_by_name = True

class RouteInfoModel(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    origin: CoordinateModel
    destination: CoordinateModel
    distanceMeters: float
    durationSeconds: int
    polyline: str
    routeName: Optional[str] = None

    class Config:
        populate_by_name = True
