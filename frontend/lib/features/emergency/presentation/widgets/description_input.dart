import 'package:flutter/material.dart';

class DescriptionInput extends StatelessWidget {
  final TextEditingController controller;

  const DescriptionInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Additional Details (Optional)',
        hintText: 'Describe the emergency briefly...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}
