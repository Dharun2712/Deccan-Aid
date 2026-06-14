import 'package:flutter/material.dart';
import '../../domain/enums/emergency_status.dart';

class StatusBadge extends StatelessWidget {
  final EmergencyStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.created:
      case EmergencyStatus.pending:
        return Colors.orange;
      case EmergencyStatus.assigned:
      case EmergencyStatus.enRoute:
        return Colors.blue;
      case EmergencyStatus.arrived:
      case EmergencyStatus.completed:
        return Colors.green;
      case EmergencyStatus.cancelled:
        return Colors.red;
    }
  }
}
