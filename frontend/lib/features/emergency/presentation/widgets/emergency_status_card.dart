import 'package:flutter/material.dart';
import '../../domain/entities/emergency_request.dart';
import 'status_badge.dart';

class EmergencyStatusCard extends StatelessWidget {
  final EmergencyRequest request;

  const EmergencyStatusCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                StatusBadge(status: request.status),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Emergency Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Severity: ${request.severity.displayName}'),
            if (request.description != null && request.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Description: ${request.description}'),
            ],
            const SizedBox(height: 8),
            Text('Requested At: _formatDate(request.createdAt)'),
          ],
        ),
      ),
    );
  }
}
