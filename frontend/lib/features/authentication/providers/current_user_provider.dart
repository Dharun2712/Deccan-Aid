import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/auth_user.dart';
import 'auth_state_provider.dart';

/// Provides the current synchronously available user based on the stream.
/// Returns null if the user is not authenticated or the stream is loading.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  return authState.valueOrNull;
});
