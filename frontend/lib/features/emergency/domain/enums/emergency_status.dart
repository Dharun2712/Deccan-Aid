enum EmergencyStatus {
  created('Created'),
  pending('Pending'),
  assigned('Assigned'),
  enRoute('En Route'),
  arrived('Arrived'),
  completed('Completed'),
  cancelled('Cancelled');

  final String displayName;

  const EmergencyStatus(this.displayName);

  static EmergencyStatus fromString(String? value) {
    if (value == null) return EmergencyStatus.created;
    return EmergencyStatus.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => EmergencyStatus.created,
    );
  }

  bool get isActive => this != EmergencyStatus.completed && this != EmergencyStatus.cancelled;
}
