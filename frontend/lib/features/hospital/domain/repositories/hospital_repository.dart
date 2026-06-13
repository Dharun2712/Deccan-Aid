import '../entities/hospital.dart';
import '../entities/admission.dart';
import '../enums/admission_status.dart';

abstract class HospitalRepository {
  Future<Hospital> getHospitalById(String id);
  Future<void> updateCapacity(String id, int beds, int icuBeds, int emergencyBeds);
  Future<List<Hospital>> getHospitals();
  
  Future<Admission> createAdmission(Admission admission);
  Future<void> updateAdmissionStatus(String admissionId, AdmissionStatus status);
}
