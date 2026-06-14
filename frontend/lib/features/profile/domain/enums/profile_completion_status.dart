enum ProfileCompletionStatus {
  incomplete('Incomplete'),
  partial('Partial'),
  complete('Complete');

  final String displayName;

  const ProfileCompletionStatus(this.displayName);
}
