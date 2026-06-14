import 'package:flutter/material.dart';

class LocationMarker extends StatelessWidget {
  final String label;
  final Color color;

  const LocationMarker({super.key, required this.label, this.color = Colors.red});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 40),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
      ],
    );
  }
}
