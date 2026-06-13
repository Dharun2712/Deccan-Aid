import 'package:flutter/material.dart';

class LocationInput extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onFetchLocation;

  const LocationInput({
    super.key,
    required this.controller,
    this.errorText,
    required this.onFetchLocation,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Current Location',
        errorText: errorText,
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: onFetchLocation,
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Location is required';
        }
        return null;
      },
    );
  }
}
