/// Ubicación en tiempo real del conductor durante un viaje.
class MoveDriverLocation {
  const MoveDriverLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime? updatedAt;

  bool get hasCoordinates => latitude != 0 || longitude != 0;
}
