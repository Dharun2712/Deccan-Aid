import 'coordinate.dart';

class RouteInfo {
  final Coordinate origin;
  final Coordinate destination;
  final double distanceMeters;
  final int durationSeconds;
  final String polyline;
  final String? routeName;

  const RouteInfo({
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
    this.routeName,
  });

  RouteInfo copyWith({
    Coordinate? origin,
    Coordinate? destination,
    double? distanceMeters,
    int? durationSeconds,
    String? polyline,
    String? routeName,
  }) {
    return RouteInfo(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      polyline: polyline ?? this.polyline,
      routeName: routeName ?? this.routeName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'polyline': polyline,
      'routeName': routeName,
    };
  }

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      origin: Coordinate.fromJson(json['origin'] as Map<String, dynamic>),
      destination: Coordinate.fromJson(json['destination'] as Map<String, dynamic>),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      polyline: json['polyline'] as String,
      routeName: json['routeName'] as String?,
    );
  }
}
