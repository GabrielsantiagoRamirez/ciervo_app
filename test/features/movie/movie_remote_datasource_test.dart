import 'dart:convert';
import 'dart:typed_data';

import 'package:ciervo_clud/core/config/app_config.dart';
import 'package:ciervo_clud/core/config/app_environment.dart';
import 'package:ciervo_clud/core/network/auth_token_refresher.dart';
import 'package:ciervo_clud/core/network/network_client.dart';
import 'package:ciervo_clud/core/session/session_manager.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:ciervo_clud/features/movie/data/datasources/movie_remote_datasource.dart';
import 'package:ciervo_clud/features/movie/domain/models/movie_commands.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'usa paths canónicos y bodies exactos de request/reserva/pago/QR',
    () async {
      final adapter = _MovieAdapter();
      final dataSource = DioMovieRemoteDataSource(_client(adapter));

      await dataSource.createRequest(
        CreateMovieRequestCommand(
          conversationId: 44,
          showtimeId: '33333333-3333-3333-3333-333333333333',
          ticketCount: 2,
          idempotencyKey: 'movie-request-install-0001',
        ),
      );
      await dataSource.selectSeats(
        'reservation-1',
        SelectMovieSeatsCommand.byCodes(['A1', 'A2']),
      );
      await dataSource.payReservation(
        'reservation-1',
        PayMovieReservationCommand(idempotencyKey: 'movie-wallet-install-0001'),
      );
      await dataSource.consumeQr(
        ConsumeMovieQrCommand(List.filled(20, 't').join()),
      );

      expect(adapter.requests[0].path, '/api/v1/chat/movie/requests');
      expect(
        adapter.requests[0].data,
        containsPair('idempotencyKey', isNotNull),
      );
      expect(
        adapter.requests[1].path,
        '/api/v1/movie/reservations/reservation-1/seats',
      );
      expect(adapter.requests[1].method, 'PUT');
      expect(adapter.requests[1].data, {
        'showtimeSeatIds': <String>[],
        'codes': ['A1', 'A2'],
      });
      expect(
        adapter.requests[2].path,
        '/api/v1/movie/reservations/reservation-1/payment',
      );
      expect(adapter.requests[2].data, containsPair('paymentMethod', 1));
      expect(adapter.requests[3].path, '/api/v1/movie/qr/consume');
      expect(adapter.requests[3].data, containsPair('token', isNotEmpty));
    },
  );

  test('polling envía cursor y take por query', () async {
    final adapter = _MovieAdapter();
    final dataSource = DioMovieRemoteDataSource(_client(adapter));

    await dataSource.pollEvents(cursor: 41, take: 100);

    expect(adapter.requests.single.path, '/api/v1/movie/events');
    expect(adapter.requests.single.queryParameters, {
      'cursor': 41,
      'take': 100,
    });
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

class _MovieAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final value = switch (options.path) {
      '/api/v1/chat/movie/requests' => {
        'id': 'request-1',
        'showtimeId': 'showtime-1',
        'ticketCount': 2,
        'status': 1,
      },
      '/api/v1/movie/qr/consume' => {
        'qrId': 'qr-1',
        'reservationId': 'reservation-1',
        'consumedAt': '2030-01-01T00:00:00Z',
      },
      '/api/v1/movie/events' => {
        'nextCursor': 41,
        'hasMore': false,
        'items': <dynamic>[],
      },
      _ => {
        'id': 'reservation-1',
        'movieId': 'movie-1',
        'movieTitle': 'Movie',
        'cinemaId': 'cinema-1',
        'cinemaName': 'Cinema',
        'hallId': 'hall-1',
        'hallName': 'Hall',
        'ticketCount': 2,
        'status': 2,
        'seats': <dynamic>[],
      },
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
