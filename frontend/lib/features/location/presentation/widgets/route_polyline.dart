import 'package:flutter/material.dart';

class RoutePolyline extends StatelessWidget {
  final String encodedPolyline;

  const RoutePolyline({super.key, required this.encodedPolyline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blueAccent.withOpacity(0.2),
      child: const Text('Polyline rendering overlay active'),
    );
  }
}
