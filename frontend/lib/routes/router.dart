import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/widgets/error_screen.dart';

import '../features/authentication/providers/auth_state_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateStreamProvider);

  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => ErrorScreen(error: state.error.toString()),
    redirect: (context, state) {
      // Allow splash screen to show first
      if (state.matchedLocation == '/splash') return null;
      
      final isAuthenticated = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';
      
      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/'; // Adjust based on roles later
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Future routes (authentication, emergency, etc.) will be added here
    ],
  );
});
