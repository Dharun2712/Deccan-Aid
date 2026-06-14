import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsService {
  static const String _apiKey = 'AIzaSyB4P99kVH_B4Y1sdLmIEvVjrpO-cZFrFKY';
  final PolylinePoints _polylinePoints = PolylinePoints();

  /// Get route polyline points between origin and destination following roads
  Future<List<LatLng>> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _apiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        return result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
    } catch (e) {
      print('[DirectionsService] Error getting route: $e');
    }

    // Fallback to straight line if API fails
    return [origin, destination];
  }

  /// Get route polyline with multiple waypoints
  Future<List<LatLng>> getRouteWithWaypoints({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
  }) async {
    try {
      final waypointsList = waypoints
          .map((wp) => PolylineWayPoint(
                location: '${wp.latitude},${wp.longitude}',
              ))
          .toList();

      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _apiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
          wayPoints: waypointsList,
        ),
      );

      if (result.points.isNotEmpty) {
        return result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
    } catch (e) {
      print('[DirectionsService] Error getting route with waypoints: $e');
    }

    // Fallback to straight line
    return [origin, ...waypoints, destination];
  }

  /// Get distance and duration between two points
  Future<Map<String, dynamic>?> getDistanceMatrix({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=${origin.latitude},${origin.longitude}&'
        'destinations=${destination.latitude},${destination.longitude}&'
        'mode=driving&'
        'key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return {
              'distance': element['distance']['value'], // in meters
              'duration': element['duration']['value'], // in seconds
              'distanceText': element['distance']['text'],
              'durationText': element['duration']['text'],
            };
          }
        }
      }
    } catch (e) {
      print('[DirectionsService] Error getting distance matrix: $e');
    }
    return null;
  }
}
