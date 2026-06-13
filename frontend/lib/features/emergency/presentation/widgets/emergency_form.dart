import 'package:flutter/material.dart';
import '../../domain/enums/emergency_severity.dart';
import 'location_input.dart';
import 'severity_selector.dart';
import 'description_input.dart';

class EmergencyForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final EmergencySeverity? selectedSeverity;
  final ValueChanged<EmergencySeverity> onSeverityChanged;
  final VoidCallback onFetchLocation;

  const EmergencyForm({
    super.key,
    required this.formKey,
    required this.locationController,
    required this.descriptionController,
    required this.selectedSeverity,
    required this.onSeverityChanged,
    required this.onFetchLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationInput(
            controller: locationController,
            onFetchLocation: onFetchLocation,
          ),
          const SizedBox(height: 24),
          SeveritySelector(
            selectedSeverity: selectedSeverity,
            onChanged: onSeverityChanged,
            errorText: selectedSeverity == null ? 'Please select a severity level' : null,
          ),
          const SizedBox(height: 24),
          DescriptionInput(
            controller: descriptionController,
          ),
        ],
      ),
    );
  }
}
