import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;

  GetProfile(this.repository);

  Future<UserProfile?> call(String userId) {
    return repository.getProfile(userId);
  }
}
