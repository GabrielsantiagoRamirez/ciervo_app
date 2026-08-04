import 'dart:convert';
import 'dart:typed_data';

import 'package:ciervo_clud/core/config/app_config.dart';
import 'package:ciervo_clud/core/config/app_environment.dart';
import 'package:ciervo_clud/core/network/auth_token_refresher.dart';
import 'package:ciervo_clud/core/network/network_client.dart';
import 'package:ciervo_clud/core/session/session_manager.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:ciervo_clud/features/move/data/onboarding/move_onboarding_remote_datasource.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_enums.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_requests.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa los seis endpoints canónicos y header de idempotencia', () async {
    final adapter = _Adapter();
    final dataSource = DioMoveOnboardingRemoteDataSource(_client(adapter));
    const key = 'move-intent-1';

    await dataSource.getStatus();
    await dataSource.saveIdentity(
      MoveIdentityOnboardingRequest(
        firstNames: 'Ana',
        lastNames: 'Demo',
        documentType: 'CC',
        documentNumber: 'DEMO0001',
        countryCode: 'CO',
        city: 'Bogotá',
        email: 'demo@example.invalid',
        phone: null,
        birthDate: DateTime.utc(1990),
        selfieMediaAssetId: 1,
        acceptMoveTerms: true,
        termsVersion: 'v1',
        termsContentHash: List.filled(64, 'a').join(),
      ),
      idempotencyKey: key,
    );
    await dataSource.saveLicense(
      MoveLicenseOnboardingRequest(
        number: 'LIC1',
        licenseClass: 'B1',
        expiresAt: DateTime.utc(2030),
        frontMediaAssetId: 2,
      ),
      idempotencyKey: key,
    );
    await dataSource.saveVehicle(
      const MoveVehicleOnboardingRequest(
        physicalType: MovePhysicalVehicleType.car,
        serviceCategory: MoveVehicleCategory.economy,
        brand: 'Marca',
        model: 'Modelo',
        year: 2026,
        color: 'Blanco',
        plate: 'ABC123',
        passengerCapacity: 4,
        vin: null,
        documents: [],
        photos: [],
        confirmsFrontShowsReadablePlate: true,
      ),
      idempotencyKey: key,
    );
    await dataSource.saveOperations(
      const MoveOperationsOnboardingRequest(
        emergencyName: 'Contacto',
        emergencyPhone: '+573000000001',
        emergencyRelationship: 'Familiar',
        languages: ['es'],
        accessible: false,
        pets: true,
        airConditioning: true,
        luggage: true,
        isAvailableNow: false,
        services: [MoveServiceType.economy],
      ),
      idempotencyKey: key,
    );
    await dataSource.submit(idempotencyKey: key);

    expect(adapter.requests.map((request) => request.path), [
      '/api/v1/move/driver/onboarding/status',
      '/api/v1/move/driver/onboarding/identity',
      '/api/v1/move/driver/onboarding/license',
      '/api/v1/move/driver/onboarding/vehicle',
      '/api/v1/move/driver/onboarding/operations',
      '/api/v1/move/driver/onboarding/submit',
    ]);
    expect(adapter.requests.first.method, 'GET');
    expect(
      adapter.requests.skip(1).take(4).map((request) => request.method),
      everyElement('PUT'),
    );
    expect(adapter.requests.last.method, 'POST');
    for (final request in adapter.requests.skip(1)) {
      expect(request.headers['Idempotency-Key'], key);
    }
    expect(adapter.requests.last.data, isNull);
  });

  test('rechaza Idempotency-Key vacía antes de enviar', () async {
    final adapter = _Adapter();
    final dataSource = DioMoveOnboardingRemoteDataSource(_client(adapter));

    expect(
      () => dataSource.submit(idempotencyKey: ' '),
      throwsA(isA<Exception>()),
    );
    expect(adapter.requests, isEmpty);
  });
}

NetworkClient _client(HttpClientAdapter adapter) {
  const config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://example.test',
    refreshTokenPath: '/api/auth/refresh-token',
    connectTimeout: Duration(seconds: 1),
    receiveTimeout: Duration(seconds: 1),
  );
  final session = SessionManager(_MemoryStorage());
  final client = NetworkClient(
    config: config,
    sessionManager: session,
    tokenRefresher: AuthTokenRefresher(config: config, sessionManager: session),
  );
  client.dio.httpClientAdapter = adapter;
  return client;
}

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'value': {
          'driverId': 25,
          'status': 'Draft',
          'percentage': 0,
          'canSubmit': false,
          'canGoOnline': false,
          'vehicleDocuments': <dynamic>[],
          'stages': <dynamic>[],
          'missing': <dynamic>[],
          'reasons': <dynamic>[],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryStorage implements SecureStorage {
  final Map<String, String> values = {};
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<void> deleteAll() async => values.clear();
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
