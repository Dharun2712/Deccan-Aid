enum Gender {
  male('Male'),
  female('Female'),
  other('Other'),
  preferNotToSay('Prefer Not to Say');

  final String displayName;

  const Gender(this.displayName);

  static Gender fromString(String? value) {
    if (value == null) return Gender.preferNotToSay;
    return Gender.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => Gender.preferNotToSay,
    );
  }
}
