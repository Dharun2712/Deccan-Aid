import '../entities/emergency_request.dart';

abstract class EmergencyRepository {
  Future<EmergencyRequest> createEmergencyRequest(EmergencyRequest request);
  Future<EmergencyRequest?> getEmergencyRequest(String id);
  Future<void> updateEmergencyStatus(String id, String status);
  Future<void> cancelEmergencyRequest(String id);
  Stream<EmergencyRequest?> streamEmergencyRequest(String id);
}
