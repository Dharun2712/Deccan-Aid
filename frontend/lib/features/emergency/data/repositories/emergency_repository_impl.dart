import 'dart:async';
import '../../domain/entities/emergency_request.dart';
import '../../domain/enums/emergency_status.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../models/emergency_request_model.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final Map<String, EmergencyRequestModel> _inMemoryStore = {};
  final StreamController<EmergencyRequest?> _streamController = StreamController<EmergencyRequest?>.broadcast();

  @override
  Future<EmergencyRequest> createEmergencyRequest(EmergencyRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final model = EmergencyRequestModel.fromEntity(request);
    _inMemoryStore[request.id] = model;
    _streamController.add(model);
    return model;
  }

  @override
  Future<EmergencyRequest?> getEmergencyRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _inMemoryStore[id];
  }

  @override
  Future<void> updateEmergencyStatus(String id, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final request = _inMemoryStore[id];
    if (request != null) {
      final updated = EmergencyRequestModel.fromEntity(
        request.copyWith(
          status: EmergencyStatus.fromString(status),
          updatedAt: DateTime.now(),
        ),
      );
      _inMemoryStore[id] = updated;
      _streamController.add(updated);
    }
  }

  @override
  Future<void> cancelEmergencyRequest(String id) async {
    await updateEmergencyStatus(id, EmergencyStatus.cancelled.name);
  }

  @override
  Stream<EmergencyRequest?> streamEmergencyRequest(String id) async* {
    yield _inMemoryStore[id];
    yield* _streamController.stream.where((req) => req?.id == id);
  }
}
