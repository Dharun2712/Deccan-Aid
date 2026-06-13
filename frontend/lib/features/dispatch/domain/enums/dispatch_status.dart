enum DispatchStatus {
  created('CREATED'),
  assigned('ASSIGNED'),
  accepted('ACCEPTED'),
  enRoute('EN_ROUTE'),
  arrived('ARRIVED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  final String value;
  const DispatchStatus(this.value);

  factory DispatchStatus.fromString(String val) {
    return DispatchStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DispatchStatus.created,
    );
  }
}
