/// Oferta de un conductor sobre un viaje (negociación de tarifa).
class MoveOffer {
  const MoveOffer({
    required this.id,
    required this.tripId,
    required this.amount,
    this.driverId,
    this.driverName,
    this.driverRating,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleLabel,
    this.etaMinutes,
    this.message,
    this.currency,
    this.isCounter = false,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final int amount;
  final String? driverId;
  final String? driverName;
  final double? driverRating;
  final String? vehicleId;
  final String? vehiclePlate;
  final String? vehicleLabel;
  final int? etaMinutes;
  final String? message;
  final String? currency;
  final bool isCounter;
  final DateTime? createdAt;
}
