/// Represents an authenticated user in the domain layer.
class AuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.emailVerified = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
