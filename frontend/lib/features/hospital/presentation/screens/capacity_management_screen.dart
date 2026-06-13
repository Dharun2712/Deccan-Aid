import 'package:flutter/material.dart';

class CapacityManagementScreen extends StatelessWidget {
  const CapacityManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capacity Management')),
      body: const Center(child: Text('Bed Capacity Updates Here')),
    );
  }
}
