from ..models.dispatch import DispatchModel
from ..schemas.dispatch import DispatchStatusEnum

class DispatchValidationError(Exception):
    pass

class DispatchValidator:
    @staticmethod
    def validate_transition(dispatch: DispatchModel, new_status: str):
        if not dispatch:
            raise DispatchValidationError("Dispatch not found")

        current = dispatch.status
        if current in [DispatchStatusEnum.COMPLETED.value, DispatchStatusEnum.CANCELLED.value]:
            raise DispatchValidationError("Cannot transition from a completed or cancelled state")

        # Simplified valid flow: CREATED -> ACCEPTED -> EN_ROUTE -> ARRIVED -> COMPLETED
        # or CANCELLED from any non-completed state
        if new_status == DispatchStatusEnum.ACCEPTED.value and current != DispatchStatusEnum.CREATED.value:
            raise DispatchValidationError("Only CREATED dispatches can be ACCEPTED")
