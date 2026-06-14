class Coordinate {
  final double latitude;
  final double longitude;

  const Coordinate({
    required this.latitude,
    required this.longitude,
  }) : assert(latitude >= -90 && latitude <= 90, 'Latitude must be between -90 and 90'),
       assert(longitude >= -180 && longitude <= 180, 'Longitude must be between -180 and 180');

  Coordinate copyWith({
    double? latitude,
    double? longitude,
  }) {
    return Coordinate(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }
}
