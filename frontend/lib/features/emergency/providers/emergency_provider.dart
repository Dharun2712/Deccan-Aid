import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/emergency_repository_impl.dart';
import '../domain/entities/emergency_request.dart';
import '../domain/repositories/emergency_repository.dart';
import '../domain/usecases/create_emergency_request.dart';
import '../domain/usecases/get_emergency_request.dart';
import '../domain/usecases/cancel_emergency_request.dart';
import 'emergency_state.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepositoryImpl();
});

final createEmergencyRequestUseCaseProvider = Provider<CreateEmergencyRequest>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return CreateEmergencyRequest(repository);
});

final getEmergencyRequestUseCaseProvider = Provider<GetEmergencyRequest>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return GetEmergencyRequest(repository);
});

final cancelEmergencyRequestUseCaseProvider = Provider<CancelEmergencyRequest>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return CancelEmergencyRequest(repository);
});

class EmergencyNotifier extends StateNotifier<EmergencyState> {
  final CreateEmergencyRequest _createEmergencyRequest;
  final CancelEmergencyRequest _cancelEmergencyRequest;
  final GetEmergencyRequest _getEmergencyRequest;

  EmergencyNotifier(
    this._createEmergencyRequest,
    this._cancelEmergencyRequest,
    this._getEmergencyRequest,
  ) : super(const EmergencyState());

  Future<void> fetchRequest(String id) async {
    state = state.copyWith(request: const AsyncLoading());
    try {
      final req = await _getEmergencyRequest(id);
      state = state.copyWith(request: AsyncData(req));
    } catch (e, st) {
      state = state.copyWith(request: AsyncError(e.toString(), st));
    }
  }

  Future<EmergencyRequest?> createRequest(EmergencyRequest request) async {
    state = state.copyWith(isCreating: true);
    try {
      final newRequest = await _createEmergencyRequest(request);
      state = state.copyWith(
        isCreating: false,
        request: AsyncData(newRequest),
      );
      return newRequest;
    } catch (e, st) {
      state = state.copyWith(
        isCreating: false,
        request: AsyncError(e.toString(), st),
      );
      return null;
    }
  }

  Future<void> cancelRequest(String id) async {
    state = state.copyWith(isCancelling: true);
    try {
      await _cancelEmergencyRequest(id);
      final req = await _getEmergencyRequest(id);
      state = state.copyWith(
        isCancelling: false,
        request: AsyncData(req),
      );
    } catch (e, st) {
      state = state.copyWith(
        isCancelling: false,
        request: AsyncError(e.toString(), st),
      );
    }
  }
}

final emergencyNotifierProvider = StateNotifierProvider<EmergencyNotifier, EmergencyState>((ref) {
  final createReq = ref.watch(createEmergencyRequestUseCaseProvider);
  final cancelReq = ref.watch(cancelEmergencyRequestUseCaseProvider);
  final getReq = ref.watch(getEmergencyRequestUseCaseProvider);
  return EmergencyNotifier(createReq, cancelReq, getReq);
});
