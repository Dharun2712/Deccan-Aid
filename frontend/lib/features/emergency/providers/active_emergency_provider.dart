import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/emergency_request.dart';
import 'emergency_provider.dart';

/// In a real application, this would stream the active emergency for the current user.
/// For now, it provides a placeholder stream that can be tied to the repository.
final activeEmergencyStreamProvider = StreamProvider.family<EmergencyRequest?, String>((ref, id) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return repository.streamEmergencyRequest(id);
});
