import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/profile_completion_status.dart';
import '../domain/usecases/calculate_profile_completion.dart';
import 'profile_provider.dart';

final calculateProfileCompletionUseCaseProvider = Provider<CalculateProfileCompletion>((ref) {
  return CalculateProfileCompletion();
});

final profileCompletionProvider = Provider<({int percentage, ProfileCompletionStatus status})?>((ref) {
  final profileAsync = ref.watch(currentProfileStreamProvider);
  final calculateUseCase = ref.watch(calculateProfileCompletionUseCaseProvider);

  return profileAsync.whenOrNull(
    data: (profile) {
      if (profile == null) return null;
      return calculateUseCase(profile);
    },
  );
});
