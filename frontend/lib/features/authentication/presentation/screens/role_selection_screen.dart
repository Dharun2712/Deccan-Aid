import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/enums/user_role.dart';
import '../../providers/role_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/role_card.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  void _submit() {
    if (_selectedRole != null) {
      ref.read(roleProvider.notifier).setRole(_selectedRole!);
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How will you be using SmartAid?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  RoleCard(
                    title: UserRole.citizen.displayName,
                    icon: Icons.person,
                    isSelected: _selectedRole == UserRole.citizen,
                    onTap: () => setState(() => _selectedRole = UserRole.citizen),
                  ),
                  const SizedBox(height: 16),
                  RoleCard(
                    title: UserRole.driver.displayName,
                    icon: Icons.directions_car,
                    isSelected: _selectedRole == UserRole.driver,
                    onTap: () => setState(() => _selectedRole = UserRole.driver),
                  ),
                  const SizedBox(height: 16),
                  RoleCard(
                    title: UserRole.hospitalAdmin.displayName,
                    icon: Icons.local_hospital,
                    isSelected: _selectedRole == UserRole.hospitalAdmin,
                    onTap: () => setState(() => _selectedRole = UserRole.hospitalAdmin),
                  ),
                ],
              ),
            ),
            AuthButton(
              text: 'Continue',
              onPressed: _selectedRole != null ? _submit : () {},
            ),
          ],
        ),
      ),
    );
  }
}
