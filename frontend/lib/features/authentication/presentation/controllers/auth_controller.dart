import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _firebaseAuth;

  AuthController(this._firebaseAuth) : super(const AsyncData(null));

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Authentication failed', StackTrace.current);
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Registration failed', StackTrace.current);
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthController(firebaseAuth);
});
