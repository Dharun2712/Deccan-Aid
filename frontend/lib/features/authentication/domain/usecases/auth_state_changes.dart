import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case to listen to authentication state changes.
class AuthStateChanges {
  final AuthRepository _repository;

  AuthStateChanges(this._repository);

  Stream<AuthUser?> call() {
    return _repository.authStateChanges;
  }
}
