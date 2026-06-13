import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/emergency_request.dart';
import '../../domain/entities/emergency_location.dart';
import '../../domain/enums/emergency_severity.dart';
import '../../providers/emergency_provider.dart';

class EmergencyController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  EmergencyController(this._ref) : super(const AsyncData(null));

  Future<EmergencyRequest?> submitEmergency({
    required EmergencySeverity severity,
    required EmergencyLocation location,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      // In a real app, you would fetch the current user ID
      final userId = 'dummy_user_id'; 
      
      final request = EmergencyRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        severity: severity,
        location: location,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _ref.read(emergencyNotifierProvider.notifier).createRequest(request);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return null;
    }
  }

  Future<bool> cancelEmergency(String requestId) async {
    state = const AsyncLoading();
    try {
      await _ref.read(emergencyNotifierProvider.notifier).cancelRequest(requestId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return false;
    }
  }
}

final emergencyControllerProvider = StateNotifierProvider<EmergencyController, AsyncValue<void>>((ref) {
  return EmergencyController(ref);
});
