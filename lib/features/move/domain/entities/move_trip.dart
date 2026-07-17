import 'move_driver_location.dart';
import 'move_enums.dart';

/// Viaje MOVE. Refleja el `MoveTripDto` del backend.
class MoveTrip {
  const MoveTrip({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.vehicleCategory,
    this.publicCode,
    this.countryCode,
    this.city,
    this.originLat,
    this.originLng,
    this.originAddress,
    this.destLat,
    this.destLng,
    this.destAddress,
    this.distanceKm,
    this.durationMin,
    this.suggestedFare,
    this.minOffer,
    this.maxOffer,
    this.agreedFare,
    this.currency,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.vehiclePlate,
    this.vehicleLabel,
    this.etaMinutes,
    this.maxCounterOffers,
    this.driverLocation,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final MoveTripStatus status;
  final MovePaymentStatus paymentStatus;
  final MovePaymentMethod paymentMethod;
  final MoveVehicleCategory vehicleCategory;
  final String? publicCode;
  final String? countryCode;
  final String? city;
  final double? originLat;
  final double? originLng;
  final String? originAddress;
  final double? destLat;
  final double? destLng;
  final String? destAddress;
  final double? distanceKm;
  final int? durationMin;
  final int? suggestedFare;
  final int? minOffer;
  final int? maxOffer;
  final int? agreedFare;
  final String? currency;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final String? vehiclePlate;
  final String? vehicleLabel;
  final int? etaMinutes;
  final int? maxCounterOffers;
  final MoveDriverLocation? driverLocation;
  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get hasDriver => (driverId ?? '').isNotEmpty;

  bool get hasOrigin => originLat != null && originLng != null;

  bool get hasDestination => destLat != null && destLng != null;

  bool get canRate => status == MoveTripStatus.completed;

  bool get canCancel => status.isActive;
}
