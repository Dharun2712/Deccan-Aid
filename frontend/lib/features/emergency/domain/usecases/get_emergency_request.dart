import '../entities/emergency_request.dart';
import '../repositories/emergency_repository.dart';

class GetEmergencyRequest {
  final EmergencyRepository repository;

  GetEmergencyRequest(this.repository);

  Future<EmergencyRequest?> call(String id) {
    return repository.getEmergencyRequest(id);
  }
}
