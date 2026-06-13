import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/current_user_provider.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/entities/user_profile.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/get_profile.dart';
import '../domain/usecases/update_profile.dart';
import 'profile_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

final getProfileUseCaseProvider = Provider<GetProfile>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return GetProfile(repository);
});

final updateProfileUseCaseProvider = Provider<UpdateProfile>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UpdateProfile(repository);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfile _getProfile;
  final UpdateProfile _updateProfile;

  ProfileNotifier(this._getProfile, this._updateProfile) : super(const ProfileState());

  Future<void> fetchProfile(String userId) async {
    state = state.copyWith(profile: const AsyncLoading());
    try {
      final profile = await _getProfile(userId);
      state = state.copyWith(profile: AsyncData(profile));
    } catch (e, st) {
      state = state.copyWith(profile: AsyncError(e.toString(), st));
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isUpdating: true);
    try {
      await _updateProfile(profile);
      state = state.copyWith(
        isUpdating: false,
        profile: AsyncData(profile),
      );
    } catch (e, st) {
      state = state.copyWith(isUpdating: false, profile: AsyncError(e.toString(), st));
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final getProfile = ref.watch(getProfileUseCaseProvider);
  final updateProfile = ref.watch(updateProfileUseCaseProvider);
  return ProfileNotifier(getProfile, updateProfile);
});

final currentProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  
  final repository = ref.watch(profileRepositoryProvider);
  return repository.streamProfile(user.id);
});
