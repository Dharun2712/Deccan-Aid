import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmergencyReviewScreen extends ConsumerWidget {
  const EmergencyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Request'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Verify your emergency details before submitting.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              // Detail widgets will go here
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Submit logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('SUBMIT EMERGENCY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
