import 'package:flutter/material.dart';
import '../../domain/enums/emergency_status.dart';

class StatusTimeline extends StatelessWidget {
  final EmergencyStatus currentStatus;

  const StatusTimeline({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStatus == EmergencyStatus.cancelled) {
      return const Center(
        child: Text(
          'Emergency Request Cancelled',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }

    final timelineStatuses = [
      EmergencyStatus.created,
      EmergencyStatus.pending,
      EmergencyStatus.assigned,
      EmergencyStatus.enRoute,
      EmergencyStatus.arrived,
      EmergencyStatus.completed,
    ];

    final currentIndex = timelineStatuses.indexOf(currentStatus);

    return Column(
      children: List.generate(timelineStatuses.length, (index) {
        final status = timelineStatuses[index];
        final isPast = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast ? Colors.green : Colors.grey.shade300,
                  ),
                  child: isPast
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (index < timelineStatuses.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isPast ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  status.displayName,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isPast ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
