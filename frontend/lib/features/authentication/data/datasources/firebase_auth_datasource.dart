import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_user_model.dart';

/// Data source that directly interacts with Firebase Authentication.
class FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSource(this._firebaseAuth);

  /// Stream of authentication state changes.
  Stream<AuthUserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUserModel.fromFirebaseUser(user);
    });
  }

  /// Gets the currently authenticated user.
  AuthUserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromFirebaseUser(user);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
