import 'package:flutter/material.dart';
import '../widgets/smartaid_map.dart';

class HospitalMapScreen extends StatelessWidget {
  const HospitalMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Region Map')),
      body: const SmartAidMap(
        initialLat: 12.9716,
        initialLng: 77.5946,
      ),
    );
  }
}
