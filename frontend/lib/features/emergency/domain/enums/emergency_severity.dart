enum EmergencySeverity {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String displayName;

  const EmergencySeverity(this.displayName);

  static EmergencySeverity fromString(String? value) {
    if (value == null) return EmergencySeverity.low;
    return EmergencySeverity.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => EmergencySeverity.low,
    );
  }
}
