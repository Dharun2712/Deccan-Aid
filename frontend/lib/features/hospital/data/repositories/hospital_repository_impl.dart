import '../../domain/entities/hospital.dart';
import '../../domain/entities/admission.dart';
import '../../domain/enums/admission_status.dart';
import '../../domain/repositories/hospital_repository.dart';

class HospitalRepositoryImpl implements HospitalRepository {
  // Mocked for now; typically uses Dio/http to call FastAPI backend
  final List<Hospital> _mockHospitals = [];
  final List<Admission> _mockAdmissions = [];

  @override
  Future<Hospital> getHospitalById(String id) async {
    return _mockHospitals.firstWhere((h) => h.id == id, orElse: () => throw Exception('Hospital not found'));
  }

  @override
  Future<void> updateCapacity(String id, int beds, int icuBeds, int emergencyBeds) async {
    // API Call to PATCH /hospitals/{id}/capacity
  }

  @override
  Future<List<Hospital>> getHospitals() async {
    return _mockHospitals;
  }

  @override
  Future<Admission> createAdmission(Admission admission) async {
    _mockAdmissions.add(admission);
    return admission;
  }

  @override
  Future<void> updateAdmissionStatus(String admissionId, AdmissionStatus status) async {
    // API Call to PATCH /admissions/{id}/approve or reject
  }
}
