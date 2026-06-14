enum DriverStatus {
  idle('IDLE'),
  assigned('ASSIGNED'),
  enRoute('EN_ROUTE'),
  onScene('ON_SCENE'),
  completed('COMPLETED');

  final String value;
  const DriverStatus(this.value);

  factory DriverStatus.fromString(String val) {
    return DriverStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DriverStatus.idle,
    );
  }
}
