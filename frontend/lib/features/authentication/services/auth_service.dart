import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// A facade service for presentation layer to interact with auth use cases.
class AuthService {
  final Ref _ref;

  AuthService(this._ref);

  /// Signs the user out.
  Future<void> signOut() async {
    final signOutUseCase = _ref.read(signOutProvider);
    await signOutUseCase();
  }
}

/// Provides the AuthService.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});
