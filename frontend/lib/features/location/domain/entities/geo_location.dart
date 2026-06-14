import 'coordinate.dart';

class GeoLocation {
  final String? id;
  final Coordinate coordinate;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  const GeoLocation({
    this.id,
    required this.coordinate,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  GeoLocation copyWith({
    String? id,
    Coordinate? coordinate,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) {
    return GeoLocation(
      id: id ?? this.id,
      coordinate: coordinate ?? this.coordinate,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coordinate': coordinate.toJson(),
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      id: json['id'] as String?,
      coordinate: Coordinate.fromJson(json['coordinate'] as Map<String, dynamic>),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }
}
