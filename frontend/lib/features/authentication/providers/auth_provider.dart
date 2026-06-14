import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/datasources/firebase_auth_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/auth_state_changes.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/sign_out.dart';

/// Provides the FirebaseAuth instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the FirebaseAuthDataSource.
final authDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthDataSource(firebaseAuth);
});

/// Provides the AuthRepository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

/// Provides the GetCurrentUser use case.
final getCurrentUserProvider = Provider<GetCurrentUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUser(repository);
});

/// Provides the AuthStateChanges use case.
final authStateChangesProvider = Provider<AuthStateChanges>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateChanges(repository);
});

/// Provides the SignOut use case.
final signOutProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
});
