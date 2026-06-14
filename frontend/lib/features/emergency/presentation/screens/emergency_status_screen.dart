import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/active_emergency_provider.dart';
import '../../domain/enums/emergency_status.dart';
import '../widgets/emergency_status_card.dart';
import '../widgets/status_timeline.dart';
import '../widgets/cancel_request_dialog.dart';
import '../controllers/emergency_controller.dart';

class EmergencyStatusScreen extends ConsumerWidget {
  final String requestId;

  const EmergencyStatusScreen({
    super.key,
    required this.requestId,
  });

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (ctx) => CancelRequestDialog(
        onConfirm: () async {
          final success = await ref.read(emergencyControllerProvider.notifier).cancelEmergency(requestId);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request cancelled successfully.')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to cancel request.')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyStream = ref.watch(activeEmergencyStreamProvider(requestId));
    final controllerState = ref.watch(emergencyControllerProvider);
    final isCancelling = controllerState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Status'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: emergencyStream.when(
          data: (request) {
            if (request == null) {
              return const Center(child: Text('Emergency request not found.'));
            }

            final canCancel = request.status.isActive;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EmergencyStatusCard(request: request),
                  const SizedBox(height: 24),
                  const Text(
                    'Live Tracking',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StatusTimeline(currentStatus: request.status),
                  ),
                  if (canCancel)
                    isCancelling
                        ? const Center(child: CircularProgressIndicator())
                        : OutlinedButton(
                            onPressed: () => _cancelRequest(context, ref),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(color: Theme.of(context).colorScheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('CANCEL REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                  if (!canCancel)
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('RETURN TO DASHBOARD'),
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
