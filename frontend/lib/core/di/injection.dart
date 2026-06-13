import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dependency Injection setup using Riverpod.
/// All global services, repositories, and configurations can be initialized here.
Future<void> initializeDependencies() async {
  // Setup global dependencies like SharedPreferences, Databases, or Network Clients.
}

/// Global provider for network client (e.g. Dio)
final networkClientProvider = Provider<dynamic>((ref) {
  throw UnimplementedError('Network client not initialized');
});
