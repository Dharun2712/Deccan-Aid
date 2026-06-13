import 'dart:async';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  // In a real app, this would use a remote data source like Firestore or a REST API
  // and a local data source like Hive or SharedPreferences.
  
  final Map<String, UserProfileModel> _inMemoryStore = {};
  final StreamController<UserProfile?> _streamController = StreamController<UserProfile?>.broadcast();

  @override
  Future<UserProfile?> getProfile(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _inMemoryStore[userId];
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    final model = UserProfileModel.fromEntity(profile);
    _inMemoryStore[profile.id] = model;
    _streamController.add(model);
  }

  @override
  Stream<UserProfile?> streamProfile(String userId) async* {
    // Yield the initial value if it exists
    yield _inMemoryStore[userId];
    // Then yield from the stream controller
    yield* _streamController.stream.where((profile) => profile?.id == userId);
  }
}
