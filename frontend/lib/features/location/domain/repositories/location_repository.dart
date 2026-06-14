import '../entities/geo_location.dart';
import '../entities/coordinate.dart';
import '../entities/route_info.dart';

abstract class LocationRepository {
  Future<GeoLocation> saveLocation(GeoLocation location);
  Future<GeoLocation?> getLocationById(String id);
  Future<RouteInfo> getRoute(Coordinate origin, Coordinate destination);
}
