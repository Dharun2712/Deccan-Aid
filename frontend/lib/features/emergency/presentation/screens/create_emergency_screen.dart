import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/emergency_severity.dart';
import '../widgets/emergency_form.dart';
import 'emergency_review_screen.dart';

class CreateEmergencyScreen extends ConsumerStatefulWidget {
  const CreateEmergencyScreen({super.key});

  @override
  ConsumerState<CreateEmergencyScreen> createState() => _CreateEmergencyScreenState();
}

class _CreateEmergencyScreenState extends ConsumerState<CreateEmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  EmergencySeverity? _selectedSeverity;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fetchLocation() {
    // Simulated location fetch
    setState(() {
      _locationController.text = '12.9716° N, 77.5946° E';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location acquired via GPS')),
    );
  }

  void _onReview() {
    if (_formKey.currentState!.validate() && _selectedSeverity != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmergencyReviewScreen(
            location: _locationController.text,
            severity: _selectedSeverity!,
            description: _descriptionController.text,
          ),
        ),
      );
    } else if (_selectedSeverity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a severity level')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Assistance'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: EmergencyForm(
                    formKey: _formKey,
                    locationController: _locationController,
                    descriptionController: _descriptionController,
                    selectedSeverity: _selectedSeverity,
                    onSeverityChanged: (severity) {
                      setState(() {
                        _selectedSeverity = severity;
                      });
                    },
                    onFetchLocation: _fetchLocation,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _onReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('REVIEW REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
