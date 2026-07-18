import 'package:ciervo_clud/core/result/result.dart';
import 'package:ciervo_clud/features/movie/data/datasources/movie_remote_datasource.dart';
import 'package:ciervo_clud/features/movie/data/realtime/movie_realtime_service.dart';
import 'package:ciervo_clud/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:ciervo_clud/features/movie/domain/models/movie_models.dart';
import 'package:ciervo_clud/features/movie/domain/repositories/movie_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QR emitido vive solo en memoria y puede olvidarse', () async {
    final repository = MovieRepositoryImpl(_QrRemote());

    final result = await repository.issueQr('reservation-1');

    expect(result, isA<Success<MovieQr>>());
    expect(
      repository.qrInMemory('reservation-1')?.token,
      List.filled(20, 'x').join(),
    );
    repository.forgetQr('reservation-1');
    expect(repository.qrInMemory('reservation-1'), isNull);
  });

  test('realtime hace catch-up antes de SSE y avanza cursor', () async {
    final repository = _RealtimeRepository();
    final service = MovieRealtimeService(
      repository,
      initialBackoff: Duration.zero,
      maximumBackoff: Duration.zero,
    );

    final received = await service
        .watch(cursor: 0)
        .where((update) => update is MovieRealtimeEventReceived)
        .cast<MovieRealtimeEventReceived>()
        .take(2)
        .map((update) => update.event.cursor)
        .toList();

    expect(received, [1, 2]);
    expect(repository.sseCursor, 1);
  });
}

class _QrRemote implements MovieRemoteDataSource {
  @override
  Future<MovieQr> issueQr(String reservationId) async => MovieQr(
    qrId: 'qr-1',
    reservationId: reservationId,
    token: List.filled(20, 'x').join(),
    expiresAt: DateTime.utc(2030),
    imageBase64: '',
    imageDataUrl: '',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RealtimeRepository implements MovieRepository {
  int? sseCursor;

  @override
  Future<Result<MovieEventPage>> pollEvents({
    required int cursor,
    int take = 100,
  }) async => Success(
    MovieEventPage(nextCursor: 1, hasMore: false, items: [_event(1)]),
  );

  @override
  Stream<MovieEvent> streamEvents({required int cursor}) {
    sseCursor = cursor;
    return Stream.value(_event(2));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MovieEvent _event(int cursor) => MovieEvent(
  cursor: cursor,
  aggregateId: 'reservation-1',
  aggregateType: 'MovieReservation',
  eventType: 'Changed',
  payloadJson: '{}',
  createdAt: DateTime.utc(2030),
);
