import '../entities/auth_user.dart';

/// Abstract repository defining authentication operations.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Gets the currently authenticated user, or null if unauthenticated.
  AuthUser? get currentUser;

  /// Signs the user out.
  Future<void> signOut();
}
