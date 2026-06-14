enum AdmissionStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  admitted('ADMITTED'),
  discharged('DISCHARGED');

  final String value;
  const AdmissionStatus(this.value);

  factory AdmissionStatus.fromString(String val) {
    return AdmissionStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AdmissionStatus.pending,
    );
  }
}
