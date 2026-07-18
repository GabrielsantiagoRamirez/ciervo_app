import '../../domain/entities/move_driver.dart';
import '../../domain/entities/move_driver_location.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_fare_quote.dart';
import '../../domain/entities/move_offer.dart';
import '../../domain/entities/move_trip.dart';

/// Mapeadores tolerantes JSON -> entidades del dominio MOVE.
///
/// El backend puede usar distintas claves; se leen alternativas comunes.
abstract final class MoveMappers {
  static MoveFareQuote fareQuote(Map<String, dynamic> json) {
    return MoveFareQuote(
      suggestedFare: _int(json, const ['suggestedFare', 'suggested', 'fare']),
      minOffer: _int(json, const ['minOffer', 'min']),
      maxOffer: _int(json, const ['maxOffer', 'max']),
      currency: _str(json, const ['currency', 'currencyCode']) ?? 'COP',
      breakdown: _breakdown(json['breakdown']),
    );
  }

  static List<MoveFareBreakdownItem> _breakdown(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(
            (item) => MoveFareBreakdownItem(
              label:
                  _str(item, const ['label', 'name', 'concept']) ?? 'Concepto',
              amount: _int(item, const ['amount', 'value']),
            ),
          )
          .toList();
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw).entries
          .where((entry) => entry.value is num)
          .map(
            (entry) => MoveFareBreakdownItem(
              label: entry.key,
              amount: (entry.value as num).round(),
            ),
          )
          .toList();
    }
    return const [];
  }

  static MoveTrip trip(Map<String, dynamic> json) {
    return MoveTrip(
      id: _str(json, const ['id', 'tripId']) ?? '',
      status: MoveTripStatus.fromValue(
        json['status'] ?? json['tripStatus'] ?? json['statusCode'],
      ),
      paymentStatus: MovePaymentStatus.fromValue(json['paymentStatus']),
      paymentMethod: MovePaymentMethod.fromValue(json['paymentMethod']),
      vehicleCategory: MoveVehicleCategory.fromValue(json['vehicleCategory']),
      publicCode: _str(json, const ['publicCode', 'code']),
      countryCode: _str(json, const ['countryCode', 'country']),
      city: _str(json, const ['city']),
      originLat: _double(json, const ['originLat', 'originLatitude']),
      originLng: _double(json, const ['originLng', 'originLongitude']),
      originAddress: _str(json, const ['originAddress', 'origin']),
      destLat: _double(json, const ['destLat', 'destLatitude']),
      destLng: _double(json, const ['destLng', 'destLongitude']),
      destAddress: _str(json, const ['destAddress', 'destination', 'dest']),
      distanceKm: _double(json, const ['distanceKm', 'distance']),
      durationMin: _intOrNull(json, const ['durationMin', 'duration']),
      suggestedFare: _intOrNull(json, const ['suggestedFare', 'fare']),
      minOffer: _intOrNull(json, const ['minOffer']),
      maxOffer: _intOrNull(json, const ['maxOffer']),
      agreedFare: _intOrNull(json, const ['agreedFare', 'finalFare', 'total']),
      currency: _str(json, const ['currency', 'currencyCode']),
      driverId: _str(json, const ['driverId']),
      driverName: _str(json, const ['driverName', 'driverFullName']),
      driverPhone: _str(json, const ['driverPhone']),
      driverRating: _double(json, const ['driverRating']),
      vehiclePlate: _str(json, const ['vehiclePlate', 'plate']),
      vehicleLabel: _str(json, const ['vehicleLabel', 'vehicle']),
      etaMinutes: _intOrNull(json, const ['etaMinutes', 'eta']),
      maxCounterOffers: _intOrNull(json, const ['maxCounterOffers']),
      driverLocation: _embeddedLocation(json),
      createdAt: _date(json, const ['createdAt', 'requestedAt', 'date']),
      completedAt: _date(json, const ['completedAt', 'finishedAt']),
      isKidsTrip:
          json['isKidsTrip'] == true ||
          json['isKids'] == true ||
          _str(json, const ['childProfileId']) != null,
      childProfileId: _str(json, const ['childProfileId', 'kidProfileId']),
      guardianUserId: _str(json, const ['guardianUserId', 'guardianId']),
      ruleReason: _str(json, const ['ruleReason', 'ruleReasons', 'parentRule']),
    );
  }

  static List<MoveTrip> tripList(List<dynamic> raw) => raw
      .whereType<Map>()
      .map((item) => trip(Map<String, dynamic>.from(item)))
      .toList();

  static MoveOffer offer(Map<String, dynamic> json) {
    return MoveOffer(
      id: _str(json, const ['id', 'offerId']) ?? '',
      tripId: _str(json, const ['tripId']) ?? '',
      amount: _int(json, const ['amount', 'offeredFare', 'fare']),
      driverId: _str(json, const ['driverId']),
      driverName: _str(json, const ['driverName', 'driverFullName']),
      driverRating: _double(json, const ['driverRating', 'rating']),
      vehicleId: _str(json, const ['vehicleId']),
      vehiclePlate: _str(json, const ['vehiclePlate', 'plate']),
      vehicleLabel: _str(json, const ['vehicleLabel', 'vehicle']),
      etaMinutes: _intOrNull(json, const ['etaMinutes', 'eta']),
      message: _str(json, const ['message', 'note']),
      currency: _str(json, const ['currency', 'currencyCode']),
      isCounter: json['isCounter'] == true || json['countered'] == true,
      createdAt: _date(json, const ['createdAt', 'date']),
    );
  }

  static List<MoveOffer> offerList(List<dynamic> raw) => raw
      .whereType<Map>()
      .map((item) => offer(Map<String, dynamic>.from(item)))
      .toList();

  static MoveDriverLocation? location(Map<String, dynamic> json) {
    final lat = _double(json, const ['latitude', 'lat']);
    final lng = _double(json, const ['longitude', 'lng', 'lon']);
    if (lat == null || lng == null) return null;
    return MoveDriverLocation(
      latitude: lat,
      longitude: lng,
      heading: _double(json, const ['heading', 'bearing']),
      speed: _double(json, const ['speed']),
      updatedAt: _date(json, const ['updatedAt', 'timestamp', 'date']),
    );
  }

  static MoveDriverLocation? _embeddedLocation(Map<String, dynamic> json) {
    final raw = json['driverLocation'] ?? json['location'];
    if (raw is Map) return location(Map<String, dynamic>.from(raw));
    final lat = _double(json, const ['driverLat', 'driverLatitude']);
    final lng = _double(json, const ['driverLng', 'driverLongitude']);
    if (lat == null || lng == null) return null;
    return MoveDriverLocation(latitude: lat, longitude: lng);
  }

  static MoveVehicle vehicle(Map<String, dynamic> json) {
    return MoveVehicle(
      id: _str(json, const ['id', 'vehicleId']) ?? '',
      category: MoveVehicleCategory.fromValue(json['category']),
      plate: _str(json, const ['plate']),
      brand: _str(json, const ['brand', 'make']),
      model: _str(json, const ['model']),
      year: _intOrNull(json, const ['year']),
      color: _str(json, const ['color']),
      seats: _intOrNull(json, const ['seats']),
      status: _str(json, const ['status', 'vehicleStatus']),
      isDefault: json['isDefault'] == true,
    );
  }

  static MoveDocument document(Map<String, dynamic> json) {
    return MoveDocument(
      id: _str(json, const ['id', 'documentId']) ?? '',
      documentType: _str(json, const ['documentType', 'type']) ?? 'Documento',
      status: _str(json, const ['status', 'documentStatus']),
      documentNumber: _str(json, const ['documentNumber', 'number']),
      fileUrl: _str(json, const ['fileUrl', 'url']),
      expiresAt: _date(json, const ['expiresAt', 'expiration']),
    );
  }

  static MoveDriverProfile driverProfile(Map<String, dynamic> json) {
    final vehiclesRaw = json['vehicles'];
    final documentsRaw = json['documents'];
    return MoveDriverProfile(
      id: _str(json, const ['id', 'driverId', 'profileId']) ?? '',
      status: MoveDriverStatus.fromValue(
        json['status'] ?? json['driverStatus'],
      ),
      fullName: _str(json, const ['fullName', 'name']),
      phone: _str(json, const ['phone']),
      countryCode: _str(json, const ['countryCode', 'country']),
      city: _str(json, const ['city']),
      rating: _double(json, const ['rating']),
      totalTrips: _intOrNull(json, const ['totalTrips', 'trips']),
      isOnline: json['isOnline'] == true || json['online'] == true,
      vehicles: vehiclesRaw is List
          ? vehiclesRaw
                .whereType<Map>()
                .map((item) => vehicle(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
      documents: documentsRaw is List
          ? documentsRaw
                .whereType<Map>()
                .map((item) => document(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
      rejectionReason: _str(json, const ['rejectionReason', 'reason']),
      isKidsEligible:
          json['isKidsEligible'] == true || json['kidsEligible'] == true,
    );
  }

  // --- helpers ----------------------------------------------------------
  static String? _str(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') continue;
      return text;
    }
    return null;
  }

  static int _int(Map<String, dynamic> json, List<String> keys) =>
      _intOrNull(json, keys) ?? 0;

  static int? _intOrNull(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.round();
      if (value is String) {
        final parsed = num.tryParse(value.trim());
        if (parsed != null) return parsed.round();
      }
    }
    return null;
  }

  static double? _double(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static DateTime? _date(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is DateTime) return value;
      final parsed = DateTime.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }
}
