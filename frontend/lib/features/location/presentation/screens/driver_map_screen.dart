import 'package:flutter/material.dart';
import '../widgets/smartaid_map.dart';

class DriverMapScreen extends StatelessWidget {
  const DriverMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Navigation')),
      body: const SmartAidMap(
        initialLat: 12.9716,
        initialLng: 77.5946,
      ),
    );
  }
}
