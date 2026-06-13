import '../../domain/entities/emergency_location.dart';

class EmergencyLocationModel extends EmergencyLocation {
  const EmergencyLocationModel({
    required super.latitude,
    required super.longitude,
    super.address,
  });

  factory EmergencyLocationModel.fromJson(Map<String, dynamic> json) {
    return EmergencyLocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory EmergencyLocationModel.fromEntity(EmergencyLocation entity) {
    return EmergencyLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
    );
  }
}
