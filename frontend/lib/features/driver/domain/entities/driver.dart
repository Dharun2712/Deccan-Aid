import 'driver_availability.dart';
import 'driver_status.dart';

class Driver {
  final String id;
  final String driverId;
  final String fullName;
  final String phoneNumber;
  final String licenseNumber;
  final String ambulanceId;
  final DriverAvailability availabilityStatus;
  final DriverStatus currentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.driverId,
    required this.fullName,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.ambulanceId,
    required this.availabilityStatus,
    required this.currentStatus,
    required this.createdAt,
    required this.updatedAt,
  });
}
