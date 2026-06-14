import 'package:flutter/material.dart';

class StatusManagementScreen extends StatelessWidget {
  const StatusManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Status')),
      body: const Center(child: Text('Change dispatch status here')),
    );
  }
}
