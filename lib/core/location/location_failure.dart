enum LocationFailureType {
  serviceDisabled,
  denied,
  deniedForever,
  timeout,
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);

  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}
