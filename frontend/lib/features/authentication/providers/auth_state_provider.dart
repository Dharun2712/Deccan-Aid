import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/auth_user.dart';
import 'auth_provider.dart';

/// Enum representing the current authentication status.
enum AuthenticationStatus {
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// A StreamProvider that listens to the auth state changes.
final authStateStreamProvider = StreamProvider<AuthUser?>((ref) {
  final authStateChanges = ref.watch(authStateChangesProvider);
  return authStateChanges();
});
