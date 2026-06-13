import '../domain/entities/coordinate.dart';
import '../domain/entities/route_info.dart';
import '../domain/repositories/location_repository.dart';

class RouteService {
  final LocationRepository _repository;

  RouteService(this._repository);

  Future<RouteInfo> getRoute(Coordinate origin, Coordinate destination) async {
    return _repository.getRoute(origin, destination);
  }
}
