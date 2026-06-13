import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case to get the currently authenticated user.
class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  AuthUser? call() {
    return _repository.currentUser;
  }
}
