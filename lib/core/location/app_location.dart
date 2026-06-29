class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;

  bool get hasCoordinates => latitude != 0 || longitude != 0;
}
