import '../domain/entities/user_profile.dart';
import '../domain/entities/emergency_contact.dart';

class ProfileValidator {
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Full name must be at least 3 characters long';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Simple regex for phone validation (can be enhanced based on region)
    final phoneRegex = RegExp(r'^\+?[0-9]{10,14}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid mobile number';
    }
    return null;
  }

  static String? validateBloodGroup(String? value) {
    if (value == null || value.isEmpty) {
      return 'Blood group is required';
    }
    return null;
  }

  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }
    if (value.isAfter(DateTime.now())) {
      return 'Date of birth cannot be in the future';
    }
    return null;
  }

  static String? validateEmergencyContacts(List<EmergencyContact> contacts) {
    if (contacts.isEmpty) {
      return 'At least one emergency contact is required';
    }
    final hasPrimary = contacts.any((contact) => contact.isPrimary);
    if (!hasPrimary) {
      return 'At least one primary emergency contact is required';
    }
    return null;
  }

  static Map<String, String> validateProfile(UserProfile profile) {
    final errors = <String, String>{};

    final nameError = validateFullName(profile.fullName);
    if (nameError != null) errors['fullName'] = nameError;

    final phoneError = validatePhoneNumber(profile.phoneNumber);
    if (phoneError != null) errors['phoneNumber'] = phoneError;

    final bgError = validateBloodGroup(profile.bloodGroup);
    if (bgError != null) errors['bloodGroup'] = bgError;

    final dobError = validateDateOfBirth(profile.dateOfBirth);
    if (dobError != null) errors['dateOfBirth'] = dobError;

    final contactError = validateEmergencyContacts(profile.emergencyContacts);
    if (contactError != null) errors['emergencyContacts'] = contactError;

    return errors;
  }
}
