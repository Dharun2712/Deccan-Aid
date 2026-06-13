import '../../domain/entities/coordinate.dart';
import '../../domain/entities/geo_location.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  // Mocked in-memory storage for demonstration
  final List<GeoLocation> _locations = [];

  @override
  Future<GeoLocation> saveLocation(GeoLocation location) async {
    _locations.add(location);
    return location;
  }

  @override
  Future<GeoLocation?> getLocationById(String id) async {
    try {
      return _locations.firstWhere((loc) => loc.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RouteInfo> getRoute(Coordinate origin, Coordinate destination) async {
    // In reality, this would call Google Directions API or backend
    return RouteInfo(
      origin: origin,
      destination: destination,
      distanceMeters: 5000.0,
      durationSeconds: 600,
      polyline: "mock_polyline",
      routeName: "Mock Route",
    );
  }
}
