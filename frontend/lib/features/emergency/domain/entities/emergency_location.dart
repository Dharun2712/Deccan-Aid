import 'package:flutter/foundation.dart';

@immutable
class EmergencyLocation {
  final double latitude;
  final double longitude;
  final String address;

  const EmergencyLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  EmergencyLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return EmergencyLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ address.hashCode;
  }
}
