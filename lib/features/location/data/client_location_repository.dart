import 'package:geolocator/geolocator.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/location/app_location.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/secure_storage.dart';

class ClientLocationRepository {
  const ClientLocationRepository({
    required NetworkClient client,
    required LocationService locationService,
    required SecureStorage storage,
  }) : _client = client,
       _locationService = locationService,
       _storage = storage;

  static const _lastLatitudeKey = 'ciervo.clientLocation.lastLatitude';
  static const _lastLongitudeKey = 'ciervo.clientLocation.lastLongitude';
  static const _lastSyncAtKey = 'ciervo.clientLocation.lastSyncAt';
  static const _syncDistanceMeters = 250.0;
  static const _syncInterval = Duration(minutes: 7);

  final NetworkClient _client;
  final LocationService _locationService;
  final SecureStorage _storage;

  Future<Result<AppLocation?>> syncForRecommendations({
    required String city,
    required String countryCode,
  }) async {
    try {
      final current = await _currentOrCachedLocation();
      if (current == null) {
        return const Success(null);
      }

      if (!await _shouldSync(current)) {
        return Success(current);
      }

      await _client.dio.put<dynamic>(
        '/api/clients/me/location',
        data: {
          'latitude': current.latitude,
          'longitude': current.longitude,
          'city': city,
          'countryCode': countryCode,
        },
      );
      await _saveSyncedLocation(current);
      return Success(current);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<AppLocation?> _currentOrCachedLocation() async {
    try {
      return await _locationService.currentLocation();
    } catch (_) {
      return await _lastSyncedLocation() ??
          await _locationService.lastKnownLocation();
    }
  }

  Future<bool> _shouldSync(AppLocation current) async {
    final last = await _lastSyncedLocation();
    final lastSyncAt = DateTime.tryParse(await _storage.read(_lastSyncAtKey) ?? '');
    if (last == null || lastSyncAt == null) {
      return true;
    }

    final distance = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      current.latitude,
      current.longitude,
    );
    if (distance >= _syncDistanceMeters) {
      return true;
    }

    return DateTime.now().toUtc().difference(lastSyncAt.toUtc()) >=
        _syncInterval;
  }

  Future<AppLocation?> _lastSyncedLocation() async {
    final latitude = double.tryParse(await _storage.read(_lastLatitudeKey) ?? '');
    final longitude = double.tryParse(await _storage.read(_lastLongitudeKey) ?? '');
    if (latitude == null || longitude == null) {
      return null;
    }
    return AppLocation(latitude: latitude, longitude: longitude);
  }

  Future<void> _saveSyncedLocation(AppLocation location) async {
    await _storage.write(_lastLatitudeKey, location.latitude.toStringAsFixed(6));
    await _storage.write(_lastLongitudeKey, location.longitude.toStringAsFixed(6));
    await _storage.write(_lastSyncAtKey, DateTime.now().toUtc().toIso8601String());
  }
}
