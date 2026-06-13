import 'package:flutter/material.dart';
import '../widgets/smartaid_map.dart';

class EmergencyMapScreen extends StatelessWidget {
  const EmergencyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Map')),
      body: const SmartAidMap(
        initialLat: 12.9716,
        initialLng: 77.5946,
      ),
    );
  }
}
