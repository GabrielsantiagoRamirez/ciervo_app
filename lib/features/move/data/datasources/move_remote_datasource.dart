import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../domain/entities/move_driver.dart';
import '../../domain/entities/move_driver_location.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_fare_quote.dart';
import '../../domain/entities/move_offer.dart';
import '../../domain/entities/move_trip.dart';
import '../../domain/repositories/move_repository.dart';
import '../dtos/move_dtos.dart';

/// Fuente remota del módulo MOVE contra la API v1.
class MoveRemoteDataSource {
  const MoveRemoteDataSource(this._client);

  final NetworkClient _client;

  static const _base = '/api/v1/move';

  // --- Pasajero ---------------------------------------------------------
  Future<MoveFareQuote> calculateFare(MoveFareRequest request) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/fare/calculate',
      data: request.toJson(),
    );
    return MoveMappers.fareQuote(unwrapApiMap(response.data));
  }

  Future<MoveTrip> requestTrip({
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
  }) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/trips',
      data: {
        'countryCode': fare.countryCode,
        'city': fare.city,
        'vehicleCategory': fare.vehicleCategory.value,
        'originLat': originLat,
        'originLng': originLng,
        'originAddress': originAddress,
        'destLat': destLat,
        'destLng': destLng,
        'destAddress': destAddress,
        'distanceKm': fare.distanceKm,
        'durationMin': fare.durationMin,
        'waitMinutes': fare.waitMinutes,
        'isNight': fare.isNight,
        'isRaining': fare.isRaining,
        'highDemandPct': fare.highDemandPct,
        'isAirport': fare.isAirport,
        'tolls': fare.tolls,
        'paymentMethod': paymentMethod.value,
        'offeredFare': offeredFare,
        'childProfileId': ?childProfileId,
      },
      options: _idempotent(),
    );
    return MoveMappers.trip(unwrapApiMap(response.data));
  }

  // --- CIERVO MOVE Kids (tutor) -----------------------------------------
  /// Viajes de menores pendientes de aprobación del tutor.
  Future<List<MoveTrip>> kidsApprovals() async {
    final response = await _client.dio.get<dynamic>(
      '$_base/trips/kids/approvals',
    );
    return MoveMappers.tripList(unwrapApiList(response.data));
  }

  Future<MoveTrip> parentApprove(String tripId) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/trips/$tripId/parent-approve',
      options: _idempotent(),
    );
    return MoveMappers.trip(unwrapApiMap(response.data));
  }

  Future<MoveTrip> parentReject(String tripId, {String? reason}) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/trips/$tripId/parent-reject',
      data: {'reason': ?reason},
    );
    return MoveMappers.trip(unwrapApiMap(response.data));
  }

  Future<void> sos(
    String tripId, {
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    await _client.dio.post<dynamic>(
      '$_base/trips/$tripId/sos',
      data: {'latitude': ?latitude, 'longitude': ?longitude, 'note': ?note},
    );
  }

  Future<MoveTrip> getTrip(String tripId) async {
    final response = await _client.dio.get<dynamic>('$_base/trips/$tripId');
    return MoveMappers.trip(unwrapApiMap(response.data));
  }

  Future<List<MoveTrip>> listTrips({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '$_base/trips',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return MoveMappers.tripList(unwrapApiList(response.data));
  }

  Future<List<MoveOffer>> getOffers(String tripId) async {
    final response = await _client.dio.get<dynamic>(
      '$_base/trips/$tripId/offers',
    );
    return MoveMappers.offerList(unwrapApiList(response.data));
  }

  Future<MoveTrip> acceptOffer(String tripId, String offerId) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/trips/$tripId/accept/$offerId',
      options: _idempotent(),
    );
    return MoveMappers.trip(unwrapApiMap(response.data));
  }

  Future<void> counterOffer({
    required String tripId,
    required String offerId,
    required int amount,
  }) async {
    await _client.dio.post<dynamic>(
      '$_base/trips/counter-offer',
      data: {
        'tripId': _numericId(tripId),
        'offerId': _numericId(offerId),
        'amount': amount,
      },
    );
  }

  Future<void> cancelTrip(String tripId, String reason) async {
    await _client.dio.post<dynamic>(
      '$_base/trips/$tripId/cancel',
      data: {'reason': reason},
    );
  }

  Future<void> rateTrip(String tripId, int rating, String? comment) async {
    await _client.dio.post<dynamic>(
      '$_base/trips/$tripId/rate',
      data: {'rating': rating, 'comment': ?comment},
    );
  }

  Future<MoveDriverLocation?> getTripLocation(String tripId) async {
    final response = await _client.dio.get<dynamic>(
      '$_base/trips/$tripId/location',
    );
    return MoveMappers.location(unwrapApiMap(response.data));
  }

  // --- Conductor --------------------------------------------------------
  Future<MoveDriverProfile?> getDriverProfile() async {
    final response = await _client.dio.get<dynamic>('$_base/driver/me');
    final map = unwrapApiMap(response.data);
    if (map.isEmpty) return null;
    return MoveMappers.driverProfile(map);
  }

  Future<MoveDriverProfile> applyAsDriver({
    required String fullName,
    required String phone,
    required String countryCode,
    required String city,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/driver/apply',
      data: {
        'fullName': fullName,
        'phone': phone,
        'countryCode': countryCode,
        'city': city,
      },
      options: _idempotent(),
    );
    return MoveMappers.driverProfile(unwrapApiMap(response.data));
  }

  Future<MoveVehicle> addVehicle(MoveVehicleInput input) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/driver/vehicles',
      data: input.toJson(),
    );
    return MoveMappers.vehicle(unwrapApiMap(response.data));
  }

  Future<void> addDocument({
    required String documentType,
    required String fileUrl,
    String? documentNumber,
    DateTime? expiresAt,
  }) async {
    await _client.dio.post<dynamic>(
      '$_base/driver/documents',
      data: {
        'documentType': documentType,
        'fileUrl': fileUrl,
        'documentNumber': ?documentNumber,
        'expiresAt': ?expiresAt?.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> setOnline({
    required bool isOnline,
    double? latitude,
    double? longitude,
  }) async {
    await _client.dio.post<dynamic>(
      '$_base/driver/online',
      data: {
        'isOnline': isOnline,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
    );
  }

  Future<void> sendDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? tripId,
  }) async {
    await _client.dio.post<dynamic>(
      '$_base/driver/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'heading': ?heading,
        'speed': ?speed,
        if (tripId != null) 'tripId': _numericId(tripId),
      },
    );
  }

  Future<List<MoveTrip>> availableTrips({double maxDistanceKm = 15}) async {
    final response = await _client.dio.get<dynamic>(
      '$_base/driver/trips/available',
      queryParameters: {'maxDistanceKm': maxDistanceKm},
    );
    return MoveMappers.tripList(unwrapApiList(response.data));
  }

  Future<void> submitOffer({
    required String tripId,
    required int amount,
    required String vehicleId,
    int? etaMinutes,
    String? message,
  }) async {
    await _client.dio.post<dynamic>(
      '$_base/driver/trips/offer',
      data: {
        'tripId': _numericId(tripId),
        'amount': amount,
        'vehicleId': _numericId(vehicleId),
        'etaMinutes': ?etaMinutes,
        'message': ?message,
      },
    );
  }

  Future<List<MoveTrip>> driverTrips({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '$_base/driver/trips',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return MoveMappers.tripList(unwrapApiList(response.data));
  }

  Future<MoveTrip> driverArriving(String tripId) =>
      _driverTransition(tripId, 'arriving');

  Future<MoveTrip> driverArrived(String tripId) =>
      _driverTransition(tripId, 'arrived');

  Future<MoveTrip> driverStart(String tripId) =>
      _driverTransition(tripId, 'start');

  Future<MoveTrip> driverFinish(String tripId) =>
      _driverTransition(tripId, 'finish');

  Future<MoveTrip> _driverTransition(String tripId, String action) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/driver/trips/$tripId/$action',
      options: _idempotent(),
    );
    final map = unwrapApiMap(response.data);
    return MoveMappers.trip(map.isEmpty ? {'id': tripId} : map);
  }

  Future<void> driverCancel(String tripId, String reason) async {
    await _client.dio.post<dynamic>(
      '$_base/driver/trips/$tripId/cancel',
      data: {'reason': reason},
    );
  }

  Future<void> driverRate(String tripId, int rating, String? comment) async {
    await _client.dio.post<dynamic>(
      '$_base/driver/trips/$tripId/rate',
      data: {'rating': rating, 'comment': ?comment},
    );
  }

  Options _idempotent() =>
      Options(headers: {'Idempotency-Key': IdempotencyKey.generate()});

  /// El backend acepta ids numéricos en cuerpos JSON; envía int cuando aplica.
  Object _numericId(String id) => int.tryParse(id.trim()) ?? id;
}
