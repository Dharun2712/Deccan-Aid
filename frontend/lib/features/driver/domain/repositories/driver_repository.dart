import '../entities/driver.dart';
import '../enums/driver_availability.dart';
import '../enums/driver_status.dart';

abstract class DriverRepository {
  Future<Driver> getDriverById(String id);
  Future<void> updateAvailability(String id, DriverAvailability availability);
  Future<void> updateStatus(String id, DriverStatus status);
  Future<List<Driver>> getAvailableDrivers();
}
