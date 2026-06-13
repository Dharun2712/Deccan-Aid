import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/user_profile.dart';

class ProfileState {
  final AsyncValue<UserProfile?> profile;
  final bool isUpdating;

  const ProfileState({
    this.profile = const AsyncData(null),
    this.isUpdating = false,
  });

  ProfileState copyWith({
    AsyncValue<UserProfile?>? profile,
    bool? isUpdating,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}
