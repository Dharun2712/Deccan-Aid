import '../../domain/entities/driver.dart';
import '../../domain/enums/driver_availability.dart';
import '../../domain/enums/driver_status.dart';
import '../../domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  // Mocked for now; typically uses Dio/http to call FastAPI backend
  final List<Driver> _mockDrivers = [];

  @override
  Future<Driver> getDriverById(String id) async {
    return _mockDrivers.firstWhere((d) => d.id == id, orElse: () => throw Exception('Driver not found'));
  }

  @override
  Future<void> updateAvailability(String id, DriverAvailability availability) async {
    // API Call to PATCH /drivers/{id}/availability
  }

  @override
  Future<void> updateStatus(String id, DriverStatus status) async {
    // API Call to PATCH /drivers/{id}/status
  }

  @override
  Future<List<Driver>> getAvailableDrivers() async {
    // API Call to GET /drivers?availability=AVAILABLE
    return _mockDrivers.where((d) => d.availabilityStatus == DriverAvailability.available).toList();
  }
}
