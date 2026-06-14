import '../domain/entities/emergency_request.dart';
import '../domain/enums/emergency_status.dart';

class EmergencyValidator {
  static String? validateRequest(EmergencyRequest request) {
    if (request.userId.isEmpty) {
      return 'User ID is required';
    }
    // Location validation (already strongly typed as non-nullable, but can check logical coordinates if needed)
    if (request.location.latitude == 0 && request.location.longitude == 0) {
      // In a real app, 0,0 might be valid (Null Island), but typically indicates failure to fetch
      return 'Valid location coordinates are required';
    }
    return null;
  }

  static String? validateTransition(EmergencyStatus currentStatus, EmergencyStatus nextStatus) {
    if (currentStatus == EmergencyStatus.completed && nextStatus != EmergencyStatus.completed) {
      return 'Cannot transition from COMPLETED to any other status';
    }
    if (currentStatus == EmergencyStatus.cancelled) {
      return 'Cannot transition from CANCELLED';
    }
    if (nextStatus == EmergencyStatus.cancelled && currentStatus == EmergencyStatus.completed) {
      return 'Cannot cancel a COMPLETED request';
    }
    return null;
  }
}
