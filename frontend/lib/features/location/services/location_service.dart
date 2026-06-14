import '../domain/entities/geo_location.dart';
import '../domain/repositories/location_repository.dart';

class LocationService {
  final LocationRepository _repository;

  LocationService(this._repository);

  Future<GeoLocation> saveUserLocation(GeoLocation location) async {
    return _repository.saveLocation(location);
  }

  Future<GeoLocation?> getLocation(String id) async {
    return _repository.getLocationById(id);
  }
}
