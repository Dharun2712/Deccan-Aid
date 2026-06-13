import '../repositories/emergency_repository.dart';

class CancelEmergencyRequest {
  final EmergencyRepository repository;

  CancelEmergencyRequest(this.repository);

  Future<void> call(String id) {
    return repository.cancelEmergencyRequest(id);
  }
}
