import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

/// Hospital data model with location and details
class HospitalData {
  final String id;
  final String name;
  final LatLng location;
  final double rating;
  final int bedCount;
  final int icuCount;
  final int doctorCount;
  final double distanceFromReference;

  HospitalData({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.bedCount,
    required this.icuCount,
    required this.doctorCount,
    required this.distanceFromReference,
  });

  /// Get color based on distance from reference point
  /// Green: < 2km, Yellow: 2-3km, Orange: 3-4km, Red: > 4km
  double get markerHue {
    if (distanceFromReference < 2.0) {
      return 120.0; // Green
    } else if (distanceFromReference < 3.0) {
      return 60.0; // Yellow
    } else if (distanceFromReference < 4.0) {
      return 30.0; // Orange
    } else {
      return 0.0; // Red
    }
  }

  String get distanceCategory {
    if (distanceFromReference < 2.0) {
      return 'Very Close';
    } else if (distanceFromReference < 3.0) {
      return 'Close';
    } else if (distanceFromReference < 4.0) {
      return 'Moderate';
    } else {
      return 'Far';
    }
  }
}

/// Reference point: Lords Institute of Engineering and Technology, Hyderabad
const LatLng konguEngineeringCollege = LatLng(17.3293, 78.3514);

/// Calculate distance between two lat/lng points using Haversine formula (in km)
double calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadius = 6371; // km
  final double lat1Rad = point1.latitude * pi / 180;
  final double lat2Rad = point2.latitude * pi / 180;
  final double dLat = (point2.latitude - point1.latitude) * pi / 180;
  final double dLng = (point2.longitude - point1.longitude) * pi / 180;
  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

/// All 10 hospitals near Lords College, Hyderabad
/// Sorted by distance (nearest first)
List<HospitalData> getAllHospitals() {
  return [
    // 1. Shadan Hospital — 1.30 km
    HospitalData(
      id: 'shadan_hospital',
      name: 'Shadan Hospital',
      location: const LatLng(17.3177, 78.3527),
      rating: 4.5,
      bedCount: 150,
      icuCount: 20,
      doctorCount: 50,
      distanceFromReference: 1.30,
    ),
    // 2. Renova Hospitals Langar Houz — 8.79 km
    HospitalData(
      id: 'renova_hospital',
      name: 'Renova Hospitals Langar Houz',
      location: const LatLng(17.3865, 78.4085),
      rating: 4.3,
      bedCount: 100,
      icuCount: 15,
      doctorCount: 35,
      distanceFromReference: 8.79,
    ),
    // 3. Germanten Hospitals — 9.21 km
    HospitalData(
      id: 'germanten_hospital',
      name: 'Germanten Hospitals',
      location: const LatLng(17.3667, 78.4288),
      rating: 4.6,
      bedCount: 180,
      icuCount: 25,
      doctorCount: 60,
      distanceFromReference: 9.21,
    ),
    // 4. Continental Hospitals — 9.35 km
    HospitalData(
      id: 'continental_hospital',
      name: 'Continental Hospitals',
      location: const LatLng(17.4129, 78.3418),
      rating: 4.8,
      bedCount: 300,
      icuCount: 40,
      doctorCount: 110,
      distanceFromReference: 9.35,
    ),
    // 5. Olive Hospital — 9.72 km
    HospitalData(
      id: 'olive_hospital',
      name: 'Olive Hospital',
      location: const LatLng(17.3690, 78.4330),
      rating: 4.4,
      bedCount: 120,
      icuCount: 18,
      doctorCount: 45,
      distanceFromReference: 9.72,
    ),
    // 6. Premier Hospital — 10.44 km
    HospitalData(
      id: 'premier_hospital',
      name: 'Premier Hospital',
      location: const LatLng(17.3610, 78.4440),
      rating: 4.5,
      bedCount: 130,
      icuCount: 20,
      doctorCount: 50,
      distanceFromReference: 10.44,
    ),
    // 7. CARE Hospitals Banjara Hills — 12.97 km
    HospitalData(
      id: 'care_hospital',
      name: 'CARE Hospitals Banjara Hills',
      location: const LatLng(17.4147, 78.4347),
      rating: 4.7,
      bedCount: 250,
      icuCount: 35,
      doctorCount: 90,
      distanceFromReference: 12.97,
    ),
    // 8. TX Hospitals Banjara Hills — 13.19 km
    HospitalData(
      id: 'tx_hospital',
      name: 'TX Hospitals Banjara Hills',
      location: const LatLng(17.4077701, 78.4446554),
      rating: 4.5,
      bedCount: 160,
      icuCount: 22,
      doctorCount: 55,
      distanceFromReference: 13.19,
    ),
    // 9. Star Hospitals - Block A & C — 13.51 km
    HospitalData(
      id: 'star_hospital',
      name: 'Star Hospitals - Block A & C',
      location: const LatLng(17.4178, 78.4386),
      rating: 4.6,
      bedCount: 220,
      icuCount: 30,
      doctorCount: 80,
      distanceFromReference: 13.51,
    ),
    // 10. Aster Prime Hospital — 15.82 km
    HospitalData(
      id: 'aster_hospital',
      name: 'Aster Prime Hospital',
      location: const LatLng(17.4372, 78.4486),
      rating: 4.6,
      bedCount: 200,
      icuCount: 28,
      doctorCount: 75,
      distanceFromReference: 15.82,
    ),
  ];
}

/// Get hospitals sorted by distance
List<HospitalData> getHospitalsSortedByDistance() {
  return getAllHospitals();
}

/// Get marker for hospital
Marker createHospitalMarker(HospitalData hospital) {
  return Marker(
    markerId: MarkerId(hospital.id),
    position: hospital.location,
    icon: BitmapDescriptor.defaultMarkerWithHue(hospital.markerHue),
    infoWindow: InfoWindow(
      title: '🏥 ${hospital.name}',
      snippet:
          '${hospital.distanceFromReference.toStringAsFixed(2)}km • ⭐${hospital.rating} • 🛏️${hospital.bedCount} beds • 🏥${hospital.icuCount} ICU • 👨‍⚕️${hospital.doctorCount} doctors',
    ),
    anchor: const Offset(0.5, 0.5),
  );
}
