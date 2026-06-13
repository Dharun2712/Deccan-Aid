import '../repositories/auth_repository.dart';

/// Use case to sign out the user.
class SignOut {
  final AuthRepository _repository;

  SignOut(this._repository);

  Future<void> call() async {
    await _repository.signOut();
  }
}
