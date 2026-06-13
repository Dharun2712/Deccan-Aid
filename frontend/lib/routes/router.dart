import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/widgets/error_screen.dart';

import '../features/authentication/providers/auth_state_provider.dart';

import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';
import '../features/authentication/presentation/screens/role_selection_screen.dart';
import '../features/authentication/presentation/screens/onboarding_screen.dart';
import '../features/authentication/presentation/screens/auth_wrapper_screen.dart';
import '../features/authentication/providers/role_provider.dart';
import '../features/authentication/providers/onboarding_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  final role = ref.watch(roleProvider);
  final hasCompletedOnboarding = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => ErrorScreen(error: state.error.toString()),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      
      final isAuthenticated = authState.valueOrNull != null;
      final isLoggingIn = loc == '/login' || loc == '/register';
      
      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/select-role';
      
      if (isAuthenticated) {
        if (role == null && loc != '/select-role') return '/select-role';
        if (role != null && !hasCompletedOnboarding && loc != '/onboarding') return '/onboarding';
        if (role != null && hasCompletedOnboarding && (loc == '/select-role' || loc == '/onboarding')) return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/select-role',
        name: 'select-role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const AuthWrapperScreen(),
      ),
    ],
  );
});
