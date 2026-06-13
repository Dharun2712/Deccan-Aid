import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/auth_user.dart';

/// Data Transfer Object for AuthUser. Maps Firebase User to Domain Entity.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    super.email,
    super.displayName,
    super.emailVerified,
  });

  /// Factory constructor to create an [AuthUserModel] from a Firebase [User].
  factory AuthUserModel.fromFirebaseUser(firebase.User user) {
    return AuthUserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }
}
