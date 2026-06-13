import 'dispatch_status.dart';

class Dispatch {
  final String id;
  final String emergencyId;
  final String driverId;
  final String hospitalId;
  final DispatchStatus status;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dispatch({
    required this.id,
    required this.emergencyId,
    required this.driverId,
    required this.hospitalId,
    required this.status,
    this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Dispatch copyWith({
    String? id,
    String? emergencyId,
    String? driverId,
    String? hospitalId,
    DispatchStatus? status,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dispatch(
      id: id ?? this.id,
      emergencyId: emergencyId ?? this.emergencyId,
      driverId: driverId ?? this.driverId,
      hospitalId: hospitalId ?? this.hospitalId,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
