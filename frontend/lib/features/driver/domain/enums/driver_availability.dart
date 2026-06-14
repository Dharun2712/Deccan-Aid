enum DriverAvailability {
  available('AVAILABLE'),
  busy('BUSY'),
  offline('OFFLINE');

  final String value;
  const DriverAvailability(this.value);

  factory DriverAvailability.fromString(String val) {
    return DriverAvailability.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DriverAvailability.offline,
    );
  }
}
