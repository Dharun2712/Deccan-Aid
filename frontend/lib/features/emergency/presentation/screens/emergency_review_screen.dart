import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/emergency_severity.dart';
import '../../domain/entities/emergency_location.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_status_screen.dart';

class EmergencyReviewScreen extends ConsumerWidget {
  final String location;
  final EmergencySeverity severity;
  final String description;

  const EmergencyReviewScreen({
    super.key,
    required this.location,
    required this.severity,
    required this.description,
  });

  Future<void> _submitRequest(BuildContext context, WidgetRef ref) async {
    // Parse simulated location
    final parts = location.replaceAll(RegExp(r'[° N E]'), '').split(',');
    double lat = parts.length == 2 ? double.tryParse(parts[0].trim()) ?? 0.0 : 0.0;
    double lng = parts.length == 2 ? double.tryParse(parts[1].trim()) ?? 0.0 : 0.0;

    final locObj = EmergencyLocation(latitude: lat, longitude: lng, address: location);

    final result = await ref.read(emergencyControllerProvider.notifier).submitEmergency(
      severity: severity,
      location: locObj,
      description: description.isNotEmpty ? description : null,
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency request dispatched successfully')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => EmergencyStatusScreen(requestId: result.id)),
        (route) => route.isFirst,
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to dispatch request. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyState = ref.watch(emergencyControllerProvider);
    final isLoading = emergencyState is AsyncLoading;

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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Location', location),
                      const Divider(),
                      _buildDetailRow('Severity', severity.displayName),
                      if (description.isNotEmpty) ...[
                        const Divider(),
                        _buildDetailRow('Description', description),
                      ]
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () => _submitRequest(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('SUBMIT EMERGENCY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
