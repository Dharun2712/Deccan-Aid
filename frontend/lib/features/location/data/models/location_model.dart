import '../../domain/entities/geo_location.dart';

class LocationModel extends GeoLocation {
  const LocationModel({
    super.id,
    required super.coordinate,
    super.address,
    super.city,
    super.state,
    super.country,
    super.postalCode,
  });

  factory LocationModel.fromEntity(GeoLocation entity) {
    return LocationModel(
      id: entity.id,
      coordinate: entity.coordinate,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      postalCode: entity.postalCode,
    );
  }
}
