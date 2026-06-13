import '../domain/entities/coordinate.dart';

class LocationValidator {
  static bool isValidCoordinate(Coordinate coordinate) {
    if (coordinate.latitude < -90 || coordinate.latitude > 90) return false;
    if (coordinate.longitude < -180 || coordinate.longitude > 180) return false;
    return true;
  }

  static void validateCoordinateOrThrow(Coordinate coordinate) {
    if (!isValidCoordinate(coordinate)) {
      throw const FormatException('Invalid coordinates: Latitude must be between -90 and 90, Longitude between -180 and 180.');
    }
  }
}
