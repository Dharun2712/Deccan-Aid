import 'package:flutter/material.dart';

class AdmissionManagementScreen extends StatelessWidget {
  const AdmissionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admission Management')),
      body: const Center(child: Text('Admission List Here')),
    );
  }
}
