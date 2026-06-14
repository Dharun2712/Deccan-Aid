import '../entities/emergency_request.dart';
import '../repositories/emergency_repository.dart';

class CreateEmergencyRequest {
  final EmergencyRepository repository;

  CreateEmergencyRequest(this.repository);

  Future<EmergencyRequest> call(EmergencyRequest request) {
    return repository.createEmergencyRequest(request);
  }
}
