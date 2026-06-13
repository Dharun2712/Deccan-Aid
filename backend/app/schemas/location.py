from pydantic import BaseModel, Field
from typing import Optional

class CoordinateSchema(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class GeoLocationSchema(BaseModel):
    id: Optional[str] = None
    coordinate: CoordinateSchema
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    postalCode: Optional[str] = None

class RouteInfoSchema(BaseModel):
    origin: CoordinateSchema
    destination: CoordinateSchema
    distanceMeters: float
    durationSeconds: int
    polyline: str
    routeName: Optional[str] = None
