import '../domain/repositories/hospital_repository.dart';
import '../domain/entities/hospital.dart';
import '../domain/entities/admission.dart';
import '../domain/enums/admission_status.dart';

class HospitalService {
  final HospitalRepository _repository;

  HospitalService(this._repository);

  Future<Hospital> getHospital(String id) async {
    return _repository.getHospitalById(id);
  }

  Future<void> updateCapacity(String id, int beds, int icuBeds, int emergencyBeds) async {
    if (beds < 0 || icuBeds < 0 || emergencyBeds < 0) {
      throw Exception('Capacity values cannot be negative');
    }
    await _repository.updateCapacity(id, beds, icuBeds, emergencyBeds);
  }

  Future<Admission> requestAdmission(Admission admission) async {
    final hospital = await getHospital(admission.hospitalId);
    if (hospital.availableBeds <= 0) {
      throw Exception('Cannot request admission when no beds are available');
    }
    return _repository.createAdmission(admission);
  }

  Future<void> approveAdmission(String admissionId) async {
    await _repository.updateAdmissionStatus(admissionId, AdmissionStatus.approved);
  }

  Future<void> rejectAdmission(String admissionId) async {
    await _repository.updateAdmissionStatus(admissionId, AdmissionStatus.rejected);
  }
}
