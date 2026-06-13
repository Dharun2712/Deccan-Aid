import 'package:flutter/material.dart';
import '../../domain/enums/emergency_severity.dart';

class SeveritySelector extends StatelessWidget {
  final EmergencySeverity? selectedSeverity;
  final ValueChanged<EmergencySeverity> onChanged;
  final String? errorText;

  const SeveritySelector({
    super.key,
    required this.selectedSeverity,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Severity Level', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: EmergencySeverity.values.map((severity) {
            final isSelected = selectedSeverity == severity;
            return ChoiceChip(
              label: Text(severity.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(severity);
              },
              selectedColor: _getSeverityColor(severity).withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? _getSeverityColor(severity) : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _getSeverityColor(severity) : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Color _getSeverityColor(EmergencySeverity severity) {
    switch (severity) {
      case EmergencySeverity.low:
        return Colors.green;
      case EmergencySeverity.medium:
        return Colors.orange;
      case EmergencySeverity.high:
        return Colors.deepOrange;
      case EmergencySeverity.critical:
        return Colors.red;
    }
  }
}
