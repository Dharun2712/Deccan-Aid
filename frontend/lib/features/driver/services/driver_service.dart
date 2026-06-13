import '../domain/repositories/driver_repository.dart';
import '../domain/enums/driver_availability.dart';
import '../domain/enums/driver_status.dart';
import '../domain/entities/driver.dart';

class DriverService {
  final DriverRepository _repository;

  DriverService(this._repository);

  Future<Driver> getDriver(String driverId) async {
    return _repository.getDriverById(driverId);
  }

  Future<void> goAvailable(String driverId) async {
    final driver = await getDriver(driverId);
    if (driver.currentStatus != DriverStatus.idle && driver.currentStatus != DriverStatus.completed) {
      throw Exception('Cannot go available while currently assigned to an emergency');
    }
    await _repository.updateAvailability(driverId, DriverAvailability.available);
  }

  Future<void> updateEmergencyStatus(String driverId, DriverStatus newStatus) async {
    final driver = await getDriver(driverId);
    if (driver.availabilityStatus == DriverAvailability.offline) {
      throw Exception('Driver is currently offline');
    }
    await _repository.updateStatus(driverId, newStatus);
  }
}
