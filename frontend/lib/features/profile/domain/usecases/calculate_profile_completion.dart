import '../entities/user_profile.dart';
import '../enums/profile_completion_status.dart';

class CalculateProfileCompletion {
  
  /// Returns the completion percentage and status.
  ({int percentage, ProfileCompletionStatus status}) call(UserProfile profile) {
    int totalFields = 5; // fullName, phoneNumber, bloodGroup, dateOfBirth, emergencyContacts
    int completedFields = 0;

    if (profile.fullName != null && profile.fullName!.trim().isNotEmpty) completedFields++;
    if (profile.phoneNumber != null && profile.phoneNumber!.trim().isNotEmpty) completedFields++;
    if (profile.bloodGroup != null && profile.bloodGroup!.isNotEmpty) completedFields++;
    if (profile.dateOfBirth != null) completedFields++;
    if (profile.emergencyContacts.isNotEmpty) completedFields++;

    int percentage = ((completedFields / totalFields) * 100).toInt();

    ProfileCompletionStatus status;
    if (percentage < 50) {
      status = ProfileCompletionStatus.incomplete;
    } else if (percentage < 90) {
      status = ProfileCompletionStatus.partial;
    } else {
      status = ProfileCompletionStatus.complete;
    }

    return (percentage: percentage, status: status);
  }
}
