import 'package:flutter/foundation.dart';
import 'emergency_location.dart';

@immutable
class EmergencyRequest {
  final String id;
  final String userId;
  final String status;
  final String severity;
  final EmergencyLocation location;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyRequest({
    required this.id,
    required this.userId,
    required this.status,
    required this.severity,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  EmergencyRequest copyWith({
    String? id,
    String? userId,
    String? status,
    String? severity,
    EmergencyLocation? location,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyRequest &&
        other.id == id &&
        other.userId == userId &&
        other.status == status &&
        other.severity == severity &&
        other.location == location &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        status.hashCode ^
        severity.hashCode ^
        location.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
