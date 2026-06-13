import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/emergency_request.dart';

class EmergencyState {
  final AsyncValue<EmergencyRequest?> request;
  final bool isCreating;
  final bool isCancelling;

  const EmergencyState({
    this.request = const AsyncData(null),
    this.isCreating = false,
    this.isCancelling = false,
  });

  EmergencyState copyWith({
    AsyncValue<EmergencyRequest?>? request,
    bool? isCreating,
    bool? isCancelling,
  }) {
    return EmergencyState(
      request: request ?? this.request,
      isCreating: isCreating ?? this.isCreating,
      isCancelling: isCancelling ?? this.isCancelling,
    );
  }
}
