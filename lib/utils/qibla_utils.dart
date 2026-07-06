import 'dart:math' as math;

/// Kaaba coordinates used for Qibla bearing calculations.
const double kaabaLatitude = 21.4225241;
const double kaabaLongitude = 39.8261818;

/// Returns the initial bearing from [latitude]/[longitude] to the Kaaba in degrees.
double calculateQiblaBearing(double latitude, double longitude) {
  final lat1 = latitude * math.pi / 180;
  final lat2 = kaabaLatitude * math.pi / 180;
  final deltaLng = (kaabaLongitude - longitude) * math.pi / 180;

  final y = math.sin(deltaLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

  final bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}
