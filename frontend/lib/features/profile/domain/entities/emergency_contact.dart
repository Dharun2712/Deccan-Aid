import 'package:flutter/foundation.dart';

@immutable
class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.isPrimary = false,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phoneNumber,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyContact &&
        other.id == id &&
        other.name == name &&
        other.relationship == relationship &&
        other.phoneNumber == phoneNumber &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        relationship.hashCode ^
        phoneNumber.hashCode ^
        isPrimary.hashCode;
  }
}
