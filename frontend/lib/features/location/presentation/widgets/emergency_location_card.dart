import 'package:flutter/material.dart';
import '../../domain/entities/geo_location.dart';

class EmergencyLocationCard extends StatelessWidget {
  final GeoLocation location;

  const EmergencyLocationCard({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(location.address ?? 'Address not available'),
            const SizedBox(height: 4),
            Text('Lat: ${location.coordinate.latitude}, Lng: ${location.coordinate.longitude}'),
          ],
        ),
      ),
    );
  }
}
