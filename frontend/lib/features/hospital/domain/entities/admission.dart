import 'admission_status.dart';

class Admission {
  final String id;
  final String emergencyId;
  final String hospitalId;
  final String patientId;
  final AdmissionStatus status;
  final String? admissionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Admission({
    required this.id,
    required this.emergencyId,
    required this.hospitalId,
    required this.patientId,
    required this.status,
    this.admissionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  Admission copyWith({
    String? id,
    String? emergencyId,
    String? hospitalId,
    String? patientId,
    AdmissionStatus? status,
    String? admissionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Admission(
      id: id ?? this.id,
      emergencyId: emergencyId ?? this.emergencyId,
      hospitalId: hospitalId ?? this.hospitalId,
      patientId: patientId ?? this.patientId,
      status: status ?? this.status,
      admissionNotes: admissionNotes ?? this.admissionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
