import '../../../../core/result/result.dart';
import '../entities/move_driver.dart';
import '../entities/move_driver_location.dart';
import '../entities/move_enums.dart';
import '../entities/move_fare_quote.dart';
import '../entities/move_offer.dart';
import '../entities/move_trip.dart';

/// Datos para registrar un vehículo del conductor.
class MoveVehicleInput {
  const MoveVehicleInput({
    required this.category,
    required this.plate,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.seats,
    this.isDefault = true,
  });

  final MoveVehicleCategory category;
  final String plate;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final int? seats;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
    'category': category.value,
    'plate': plate,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    if (year != null) 'year': year,
    if (color != null) 'color': color,
    if (seats != null) 'seats': seats,
    'isDefault': isDefault,
  };
}

/// Interfaz del módulo CIERVO MOVE (pasajero + conductor).
abstract interface class MoveRepository {
  // --- Pasajero ---------------------------------------------------------
  Future<Result<MoveFareQuote>> calculateFare(MoveFareRequest request);

  Future<Result<MoveTrip>> requestTrip({
    required MoveFareRequest fare,
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    required MovePaymentMethod paymentMethod,
    int offeredFare = 0,
    String? childProfileId,
  });

  Future<Result<MoveTrip>> getTrip(String tripId);

  Future<Result<List<MoveTrip>>> listTrips({
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<List<MoveOffer>>> getOffers(String tripId);

  Future<Result<MoveTrip>> acceptOffer({
    required String tripId,
    required String offerId,
  });

  Future<Result<void>> counterOffer({
    required String tripId,
    required String offerId,
    required int amount,
  });

  Future<Result<void>> cancelTrip({
    required String tripId,
    required String reason,
  });

  Future<Result<void>> rateTrip({
    required String tripId,
    required int rating,
    String? comment,
  });

  Future<Result<MoveDriverLocation?>> getTripLocation(String tripId);

  // --- CIERVO MOVE Kids (tutor) -----------------------------------------
  Future<Result<List<MoveTrip>>> kidsApprovals();

  Future<Result<MoveTrip>> parentApprove(String tripId);

  Future<Result<MoveTrip>> parentReject(String tripId, {String? reason});

  Future<Result<void>> sos({
    required String tripId,
    double? latitude,
    double? longitude,
    String? note,
  });

  // --- Conductor --------------------------------------------------------
  Future<Result<MoveDriverProfile?>> getDriverProfile();

  Future<Result<MoveDriverProfile>> applyAsDriver({
    required String fullName,
    required String phone,
    required String countryCode,
    required String city,
  });

  Future<Result<MoveVehicle>> addVehicle(MoveVehicleInput input);

  Future<Result<void>> addDocument({
    required String documentType,
    required String fileUrl,
    String? documentNumber,
    DateTime? expiresAt,
  });

  Future<Result<void>> setOnline({
    required bool isOnline,
    double? latitude,
    double? longitude,
  });

  Future<Result<void>> sendDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? tripId,
  });

  Future<Result<List<MoveTrip>>> availableTrips({double maxDistanceKm = 15});

  Future<Result<void>> submitOffer({
    required String tripId,
    required int amount,
    required String vehicleId,
    int? etaMinutes,
    String? message,
  });

  Future<Result<List<MoveTrip>>> driverTrips({
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<MoveTrip>> driverArriving(String tripId);

  Future<Result<MoveTrip>> driverArrived(String tripId);

  Future<Result<MoveTrip>> driverStart(String tripId);

  Future<Result<MoveTrip>> driverFinish(String tripId);

  Future<Result<void>> driverCancel({
    required String tripId,
    required String reason,
  });

  Future<Result<void>> driverRate({
    required String tripId,
    required int rating,
    String? comment,
  });
}
