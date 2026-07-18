import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/move_driver.dart';
import '../../domain/entities/move_driver_location.dart';
import '../../domain/entities/move_fare_quote.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_offer.dart';
import '../../domain/entities/move_trip.dart';
import '../../domain/repositories/move_repository.dart';
import '../datasources/move_remote_datasource.dart';

class MoveRepositoryImpl implements MoveRepository {
  const MoveRepositoryImpl(this._remote);

  final MoveRemoteDataSource _remote;

  @override
  Future<Result<MoveFareQuote>> calculateFare(MoveFareRequest request) =>
      _guard(() => _remote.calculateFare(request));

  @override
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
  }) => _guard(
    () => _remote.requestTrip(
      fare: fare,
      originLat: originLat,
      originLng: originLng,
      originAddress: originAddress,
      destLat: destLat,
      destLng: destLng,
      destAddress: destAddress,
      paymentMethod: paymentMethod,
      offeredFare: offeredFare,
      childProfileId: childProfileId,
    ),
  );

  @override
  Future<Result<MoveTrip>> getTrip(String tripId) =>
      _guard(() => _remote.getTrip(tripId));

  @override
  Future<Result<List<MoveTrip>>> listTrips({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) => _guard(
    () => _remote.listTrips(status: status, page: page, pageSize: pageSize),
  );

  @override
  Future<Result<List<MoveOffer>>> getOffers(String tripId) =>
      _guard(() => _remote.getOffers(tripId));

  @override
  Future<Result<MoveTrip>> acceptOffer({
    required String tripId,
    required String offerId,
  }) => _guard(() => _remote.acceptOffer(tripId, offerId));

  @override
  Future<Result<void>> counterOffer({
    required String tripId,
    required String offerId,
    required int amount,
  }) => _guard(
    () =>
        _remote.counterOffer(tripId: tripId, offerId: offerId, amount: amount),
  );

  @override
  Future<Result<void>> cancelTrip({
    required String tripId,
    required String reason,
  }) => _guard(() => _remote.cancelTrip(tripId, reason));

  @override
  Future<Result<void>> rateTrip({
    required String tripId,
    required int rating,
    String? comment,
  }) => _guard(() => _remote.rateTrip(tripId, rating, comment));

  @override
  Future<Result<MoveDriverLocation?>> getTripLocation(String tripId) =>
      _guard(() => _remote.getTripLocation(tripId));

  @override
  Future<Result<List<MoveTrip>>> kidsApprovals() =>
      _guard(() => _remote.kidsApprovals());

  @override
  Future<Result<MoveTrip>> parentApprove(String tripId) =>
      _guard(() => _remote.parentApprove(tripId));

  @override
  Future<Result<MoveTrip>> parentReject(String tripId, {String? reason}) =>
      _guard(() => _remote.parentReject(tripId, reason: reason));

  @override
  Future<Result<void>> sos({
    required String tripId,
    double? latitude,
    double? longitude,
    String? note,
  }) => _guard(
    () => _remote.sos(
      tripId,
      latitude: latitude,
      longitude: longitude,
      note: note,
    ),
  );

  @override
  Future<Result<MoveDriverProfile?>> getDriverProfile() =>
      _guard(() => _remote.getDriverProfile());

  @override
  Future<Result<MoveDriverProfile>> applyAsDriver({
    required String fullName,
    required String phone,
    required String countryCode,
    required String city,
  }) => _guard(
    () => _remote.applyAsDriver(
      fullName: fullName,
      phone: phone,
      countryCode: countryCode,
      city: city,
    ),
  );

  @override
  Future<Result<MoveVehicle>> addVehicle(MoveVehicleInput input) =>
      _guard(() => _remote.addVehicle(input));

  @override
  Future<Result<void>> addDocument({
    required String documentType,
    required String fileUrl,
    String? documentNumber,
    DateTime? expiresAt,
  }) => _guard(
    () => _remote.addDocument(
      documentType: documentType,
      fileUrl: fileUrl,
      documentNumber: documentNumber,
      expiresAt: expiresAt,
    ),
  );

  @override
  Future<Result<void>> setOnline({
    required bool isOnline,
    double? latitude,
    double? longitude,
  }) => _guard(
    () => _remote.setOnline(
      isOnline: isOnline,
      latitude: latitude,
      longitude: longitude,
    ),
  );

  @override
  Future<Result<void>> sendDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? tripId,
  }) => _guard(
    () => _remote.sendDriverLocation(
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speed: speed,
      tripId: tripId,
    ),
  );

  @override
  Future<Result<List<MoveTrip>>> availableTrips({double maxDistanceKm = 15}) =>
      _guard(() => _remote.availableTrips(maxDistanceKm: maxDistanceKm));

  @override
  Future<Result<void>> submitOffer({
    required String tripId,
    required int amount,
    required String vehicleId,
    int? etaMinutes,
    String? message,
  }) => _guard(
    () => _remote.submitOffer(
      tripId: tripId,
      amount: amount,
      vehicleId: vehicleId,
      etaMinutes: etaMinutes,
      message: message,
    ),
  );

  @override
  Future<Result<List<MoveTrip>>> driverTrips({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) => _guard(
    () => _remote.driverTrips(status: status, page: page, pageSize: pageSize),
  );

  @override
  Future<Result<MoveTrip>> driverArriving(String tripId) =>
      _guard(() => _remote.driverArriving(tripId));

  @override
  Future<Result<MoveTrip>> driverArrived(String tripId) =>
      _guard(() => _remote.driverArrived(tripId));

  @override
  Future<Result<MoveTrip>> driverStart(String tripId) =>
      _guard(() => _remote.driverStart(tripId));

  @override
  Future<Result<MoveTrip>> driverFinish(String tripId) =>
      _guard(() => _remote.driverFinish(tripId));

  @override
  Future<Result<void>> driverCancel({
    required String tripId,
    required String reason,
  }) => _guard(() => _remote.driverCancel(tripId, reason));

  @override
  Future<Result<void>> driverRate({
    required String tripId,
    required int rating,
    String? comment,
  }) => _guard(() => _remote.driverRate(tripId, rating, comment));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
