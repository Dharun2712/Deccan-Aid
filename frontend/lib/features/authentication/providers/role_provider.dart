import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/user_role.dart';

/// Simulates a persistent store for the user's selected role.
/// In a real app, this would read from SharedPreferences or SecureStorage.
class RoleNotifier extends StateNotifier<UserRole?> {
  RoleNotifier() : super(null);

  void setRole(UserRole role) {
    state = role;
    // TODO: Persist role to local storage and backend
  }

  void clearRole() {
    state = null;
  }
}

final roleProvider = StateNotifierProvider<RoleNotifier, UserRole?>((ref) {
  return RoleNotifier();
});
