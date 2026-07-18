import 'dart:convert';
import 'dart:typed_data';

import 'package:ciervo_clud/core/config/app_config.dart';
import 'package:ciervo_clud/core/config/app_environment.dart';
import 'package:ciervo_clud/core/network/auth_token_refresher.dart';
import 'package:ciervo_clud/core/network/network_client.dart';
import 'package:ciervo_clud/core/session/session_manager.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:ciervo_clud/features/master_kids/data/datasources/master_kids_remote_datasource.dart';
import 'package:ciervo_clud/features/master_kids/domain/models/master_kids_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carga las siete colecciones de reglas por paths canónicos', () async {
    final adapter = _ContractAdapter();
    final source = DioMasterKidsRemoteDataSource(_client(adapter));

    final rules = await source.rules(42);

    expect(
      adapter.requests.map((request) => request.path),
      containsAll([
        '/api/kids/42/rules/merchants',
        '/api/kids/42/rules/categories',
        '/api/kids/42/rules/limits',
        '/api/kids/42/rules/schedules',
        '/api/kids/42/rules/geofences',
        '/api/kids/42/rules/countries',
        '/api/kids/42/rules/blocked-merchants',
      ]),
    );
    expect(rules.merchants.single.label, 'Cine Centro');
    expect(rules.countries.single.code, 'CO');
  });

  test('CRUD geocerca y bloqueado usan método y body documentados', () async {
    final adapter = _ContractAdapter();
    final source = DioMasterKidsRemoteDataSource(_client(adapter));

    await source.updateGeofence(
      42,
      8,
      const KidGeofenceCommand(
        name: 'Casa',
        centerLatitude: 4.7,
        centerLongitude: -74,
        radiusMeters: 250,
      ),
    );
    await source.blockMerchant(42, const KidRuleMerchantCommand(17));
    await source.unblockMerchant(42, 17);

    expect(adapter.requests[0].method, 'PUT');
    expect(adapter.requests[0].path, '/api/kids/42/rules/geofences/8');
    expect(adapter.requests[1].data, {'merchantId': 17});
    expect(adapter.requests[2].method, 'DELETE');
  });

  test('ubicación, historial y auditoría bytes respetan contrato', () async {
    final adapter = _ContractAdapter();
    final source = DioMasterKidsRemoteDataSource(_client(adapter));

    await source.location(42);
    await source.locationHistory(42, take: 25);
    final export = await source.exportAudit(kidId: 42);

    expect(adapter.requests[1].path, '/api/kids/42/location/locations');
    expect(adapter.requests[1].queryParameters['take'], 25);
    expect(export.bytes, [0xEF, 0xBB, 0xBF, 0x61]);
    expect(export.fileName, 'kids.csv');
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

class _ContractAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path == '/api/v1/audit/export') {
      return ResponseBody.fromBytes(
        [0xEF, 0xBB, 0xBF, 0x61],
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
          'content-disposition': ['attachment; filename="kids.csv"'],
        },
      );
    }
    final value = switch (options.path) {
      '/api/kids/42/rules/merchants' => [
        {'merchantId': 1, 'merchantName': 'Cine Centro'},
      ],
      '/api/kids/42/rules/categories' => [
        {'categoryId': 2, 'categoryName': 'Cine'},
      ],
      '/api/kids/42/rules/limits' => {'dailyLimit': 100, 'currency': 'COP'},
      '/api/kids/42/rules/schedules' => [
        {
          'timezone': 'America/Bogota',
          'scheduleJson': '{"days":[1]}',
          'isActive': true,
        },
      ],
      '/api/kids/42/rules/geofences' => <dynamic>[],
      '/api/kids/42/rules/countries' => [
        {'countryCode': 'CO', 'countryName': 'Colombia'},
      ],
      '/api/kids/42/rules/blocked-merchants' => <dynamic>[],
      '/api/kids/42/location' => {
        'latitude': 4.7,
        'longitude': -74,
        'recordedAt': '2026-07-18T10:00:00Z',
      },
      '/api/kids/42/location/locations' => <dynamic>[],
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode({'status': true, 'value': value}),
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
