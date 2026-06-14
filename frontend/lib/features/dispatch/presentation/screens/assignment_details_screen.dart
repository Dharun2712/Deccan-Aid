import 'package:flutter/material.dart';

class AssignmentDetailsScreen extends StatelessWidget {
  const AssignmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: const Center(child: Text('Dispatch information and routing details here')),
    );
  }
}
