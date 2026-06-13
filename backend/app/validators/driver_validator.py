from ..models.driver import DriverModel
from ..schemas.driver import DriverAvailabilityEnum, DriverStatusEnum

class DriverValidationError(Exception):
    pass

class DriverValidator:
    @staticmethod
    def validate_availability_transition(driver: DriverModel, new_availability: str):
        if not driver:
            raise DriverValidationError("Driver not found")
        
        if new_availability == DriverAvailabilityEnum.AVAILABLE.value:
            if driver.currentStatus not in [DriverStatusEnum.IDLE.value, DriverStatusEnum.COMPLETED.value]:
                raise DriverValidationError("Cannot become available while actively assigned to an emergency")
