import '../../domain/entities/user_profile.dart';
import 'emergency_contact_model.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.fullName,
    super.phoneNumber,
    super.dateOfBirth,
    super.gender,
    super.bloodGroup,
    super.allergies,
    super.medicalConditions,
    super.emergencyContacts,
    super.profileImageUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
      gender: json['gender'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      allergies: List<String>.from(json['allergies'] ?? []),
      medicalConditions: List<String>.from(json['medicalConditions'] ?? []),
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'emergencyContacts': emergencyContacts
          .map((e) => EmergencyContactModel.fromEntity(e).toJson())
          .toList(),
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      bloodGroup: entity.bloodGroup,
      allergies: entity.allergies,
      medicalConditions: entity.medicalConditions,
      emergencyContacts: entity.emergencyContacts,
      profileImageUrl: entity.profileImageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
