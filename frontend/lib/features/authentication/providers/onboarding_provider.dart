import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simulates whether the user has completed the onboarding flow.
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false);

  void completeOnboarding() {
    state = true;
    // TODO: Persist onboarding completion status to local storage
  }

  void resetOnboarding() {
    state = false;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});
