import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/user_role.dart';
import '../../providers/role_provider.dart';
import '../../../home/presentation/citizen_home_screen.dart';
import '../../../home/presentation/driver_home_screen.dart';
import '../../../home/presentation/hospital_home_screen.dart';

class AuthWrapperScreen extends ConsumerWidget {
  const AuthWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);

    if (role == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No role selected')),
      );
    }

    switch (role) {
      case UserRole.citizen:
        return const CitizenHomeScreen();
      case UserRole.driver:
        return const DriverHomeScreen();
      case UserRole.hospitalAdmin:
        return const HospitalHomeScreen();
    }
  }
}
