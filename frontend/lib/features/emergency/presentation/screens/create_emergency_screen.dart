import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateEmergencyScreen extends ConsumerWidget {
  const CreateEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Emergency Assistance'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Emergency Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Form widget will be injected here
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Review Screen
                },
                child: const Text('Review Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
