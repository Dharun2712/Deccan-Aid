import 'dart:math' as math;
import '../domain/entities/coordinate.dart';

class DistanceService {
  static const double earthRadiusKm = 6371.0;

  double calculateDistance(Coordinate point1, Coordinate point2) {
    var lat1 = _degreesToRadians(point1.latitude);
    var lon1 = _degreesToRadians(point1.longitude);
    var lat2 = _degreesToRadians(point2.latitude);
    var lon2 = _degreesToRadians(point2.longitude);

    var dlon = lon2 - lon1;
    var dlat = lat2 - lat1;

    var a = math.pow(math.sin(dlat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dlon / 2), 2);
    
    var c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c * 1000; // Returns meters
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
