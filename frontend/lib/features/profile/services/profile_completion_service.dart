import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/user_profile.dart';
import '../domain/enums/profile_completion_status.dart';
import '../domain/usecases/calculate_profile_completion.dart';

class ProfileCompletionService {
  final CalculateProfileCompletion _calculateUseCase;

  ProfileCompletionService(this._calculateUseCase);

  int getCompletionPercentage(UserProfile profile) {
    return _calculateUseCase(profile).percentage;
  }

  ProfileCompletionStatus getCompletionStatus(UserProfile profile) {
    return _calculateUseCase(profile).status;
  }

  bool isProfileComplete(UserProfile profile) {
    return getCompletionStatus(profile) == ProfileCompletionStatus.complete;
  }
}

final profileCompletionServiceProvider = Provider<ProfileCompletionService>((ref) {
  final calculateUseCase = CalculateProfileCompletion();
  return ProfileCompletionService(calculateUseCase);
});
