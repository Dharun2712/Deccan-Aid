enum UserRole {
  citizen,
  driver,
  hospitalAdmin;

  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.driver:
        return 'Ambulance Driver';
      case UserRole.hospitalAdmin:
        return 'Hospital Administrator';
    }
  }
}
