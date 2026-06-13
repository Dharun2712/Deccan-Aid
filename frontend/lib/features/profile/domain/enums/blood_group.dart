enum BloodGroup {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-'),
  oPositive('O+'),
  oNegative('O-'),
  unknown('Unknown');

  final String displayName;

  const BloodGroup(this.displayName);

  static BloodGroup fromString(String? value) {
    if (value == null) return BloodGroup.unknown;
    return BloodGroup.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => BloodGroup.unknown,
    );
  }
}
