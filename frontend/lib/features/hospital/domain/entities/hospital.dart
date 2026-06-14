import 'hospital_status.dart';

class Hospital {
  final String id;
  final String hospitalId;
  final String name;
  final String phoneNumber;
  final String email;
  final String address;
  final double latitude;
  final double longitude;
  final int totalBeds;
  final int availableBeds;
  final int totalICUBeds;
  final int availableICUBeds;
  final int totalEmergencyBeds;
  final int availableEmergencyBeds;
  final HospitalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Hospital({
    required this.id,
    required this.hospitalId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalBeds,
    required this.availableBeds,
    required this.totalICUBeds,
    required this.availableICUBeds,
    required this.totalEmergencyBeds,
    required this.availableEmergencyBeds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Hospital copyWith({
    String? id,
    String? hospitalId,
    String? name,
    String? phoneNumber,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    int? totalBeds,
    int? availableBeds,
    int? totalICUBeds,
    int? availableICUBeds,
    int? totalEmergencyBeds,
    int? availableEmergencyBeds,
    HospitalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Hospital(
      id: id ?? this.id,
      hospitalId: hospitalId ?? this.hospitalId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalBeds: totalBeds ?? this.totalBeds,
      availableBeds: availableBeds ?? this.availableBeds,
      totalICUBeds: totalICUBeds ?? this.totalICUBeds,
      availableICUBeds: availableICUBeds ?? this.availableICUBeds,
      totalEmergencyBeds: totalEmergencyBeds ?? this.totalEmergencyBeds,
      availableEmergencyBeds: availableEmergencyBeds ?? this.availableEmergencyBeds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
