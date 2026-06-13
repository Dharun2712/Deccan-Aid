enum HospitalStatus {
  active('ACTIVE'),
  busy('BUSY'),
  full('FULL'),
  offline('OFFLINE');

  final String value;
  const HospitalStatus(this.value);

  factory HospitalStatus.fromString(String val) {
    return HospitalStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => HospitalStatus.offline,
    );
  }
}
