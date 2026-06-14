from ..models.hospital import HospitalModel
from ..schemas.hospital import CapacityUpdate

class HospitalValidationError(Exception):
    pass

class HospitalValidator:
    @staticmethod
    def validate_capacity_update(hospital: HospitalModel, capacity: CapacityUpdate):
        if not hospital:
            raise HospitalValidationError("Hospital not found")

        beds = capacity.availableBeds if capacity.availableBeds is not None else hospital.availableBeds
        icu_beds = capacity.availableICUBeds if capacity.availableICUBeds is not None else hospital.availableICUBeds
        emergency_beds = capacity.availableEmergencyBeds if capacity.availableEmergencyBeds is not None else hospital.availableEmergencyBeds

        if beds < 0 or icu_beds < 0 or emergency_beds < 0:
            raise HospitalValidationError("Available beds cannot be negative")

        if beds > hospital.totalBeds or icu_beds > hospital.totalICUBeds or emergency_beds > hospital.totalEmergencyBeds:
            raise HospitalValidationError("Available beds cannot exceed total beds")
