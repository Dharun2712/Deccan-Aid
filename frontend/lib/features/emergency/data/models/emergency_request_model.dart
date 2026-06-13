import '../../domain/entities/emergency_request.dart';
import '../../domain/enums/emergency_status.dart';
import '../../domain/enums/emergency_severity.dart';
import 'emergency_location_model.dart';

class EmergencyRequestModel extends EmergencyRequest {
  const EmergencyRequestModel({
    required super.id,
    required super.userId,
    super.status,
    required super.severity,
    required super.location,
    super.description,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EmergencyRequestModel.fromJson(Map<String, dynamic> json) {
    return EmergencyRequestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: EmergencyStatus.fromString(json['status'] as String?),
      severity: EmergencySeverity.fromString(json['severity'] as String?),
      location: EmergencyLocationModel.fromJson(json['location'] as Map<String, dynamic>),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status.name,
      'severity': severity.name,
      'location': EmergencyLocationModel.fromEntity(location).toJson(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmergencyRequestModel.fromEntity(EmergencyRequest entity) {
    return EmergencyRequestModel(
      id: entity.id,
      userId: entity.userId,
      status: entity.status,
      severity: entity.severity,
      location: entity.location,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
