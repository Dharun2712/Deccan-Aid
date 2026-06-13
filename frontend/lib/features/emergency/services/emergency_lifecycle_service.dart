import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/emergency_request.dart';
import '../domain/enums/emergency_status.dart';
import '../providers/emergency_provider.dart';
import 'emergency_validator.dart';

class EmergencyLifecycleService {
  final Ref _ref;

  EmergencyLifecycleService(this._ref);

  Future<void> transitionStatus(String requestId, EmergencyStatus currentStatus, EmergencyStatus nextStatus) async {
    final validationError = EmergencyValidator.validateTransition(currentStatus, nextStatus);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final repository = _ref.read(emergencyRepositoryProvider);
    await repository.updateEmergencyStatus(requestId, nextStatus.name);
  }

  Future<void> cancelRequest(EmergencyRequest request) async {
    final validationError = EmergencyValidator.validateTransition(request.status, EmergencyStatus.cancelled);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final cancelUseCase = _ref.read(cancelEmergencyRequestUseCaseProvider);
    await cancelUseCase(request.id);
  }
}

final emergencyLifecycleServiceProvider = Provider<EmergencyLifecycleService>((ref) {
  return EmergencyLifecycleService(ref);
});
