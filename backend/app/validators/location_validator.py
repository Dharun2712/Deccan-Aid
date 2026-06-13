from ..schemas.location import CoordinateSchema

class LocationValidationError(Exception):
    pass

class LocationValidator:
    @staticmethod
    def validate_coordinate(coord: CoordinateSchema):
        if not (-90 <= coord.latitude <= 90):
            raise LocationValidationError("Latitude must be between -90 and 90")
        if not (-180 <= coord.longitude <= 180):
            raise LocationValidationError("Longitude must be between -180 and 180")
