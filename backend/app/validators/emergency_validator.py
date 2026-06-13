from ..models.emergency import EmergencyModel
from ..schemas.emergency_request import EmergencyRequestCreate

class EmergencyValidationError(Exception):
    pass

class EmergencyValidator:
    @staticmethod
    def validate_creation(request_data: EmergencyRequestCreate):
        if not request_data.user_id:
            raise EmergencyValidationError("User ID is required to create an emergency.")
        if request_data.location.latitude == 0 and request_data.location.longitude == 0:
            raise EmergencyValidationError("Valid location coordinates are required.")

    @staticmethod
    def validate_cancellation(emergency: EmergencyModel):
        if not emergency:
            raise EmergencyValidationError("Emergency request does not exist.")
        if emergency.status == "completed":
            raise EmergencyValidationError("Cannot cancel a completed emergency.")
        if emergency.status == "cancelled":
            raise EmergencyValidationError("Emergency is already cancelled.")
