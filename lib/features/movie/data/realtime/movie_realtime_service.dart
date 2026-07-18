import 'dart:async';

import '../../../../core/result/result.dart';
import '../../domain/models/movie_models.dart';
import '../../domain/repositories/movie_repository.dart';

enum MovieRealtimePhase {
  connecting,
  catchingUp,
  live,
  reconnecting,
  pollingFallback,
  stopped,
}

sealed class MovieRealtimeUpdate {
  const MovieRealtimeUpdate();
}

class MovieRealtimePhaseChanged extends MovieRealtimeUpdate {
  const MovieRealtimePhaseChanged(this.phase, this.cursor);
  final MovieRealtimePhase phase;
  final int cursor;
}

class MovieRealtimeEventReceived extends MovieRealtimeUpdate {
  const MovieRealtimeEventReceived(this.event);
  final MovieEvent event;
}

class MovieRealtimeFailure extends MovieRealtimeUpdate {
  const MovieRealtimeFailure(this.error, this.cursor);
  final Object error;
  final int cursor;
}

/// Realiza catch-up durable por polling antes de cada conexión SSE.
class MovieRealtimeService {
  MovieRealtimeService(
    this._repository, {
    this.initialBackoff = const Duration(seconds: 1),
    this.maximumBackoff = const Duration(seconds: 30),
  });

  final MovieRepository _repository;
  final Duration initialBackoff;
  final Duration maximumBackoff;
  bool _stopped = false;

  Stream<MovieRealtimeUpdate> watch({int cursor = 0}) async* {
    _stopped = false;
    var current = cursor;
    var attempt = 0;
    yield MovieRealtimePhaseChanged(MovieRealtimePhase.connecting, current);

    while (!_stopped) {
      yield MovieRealtimePhaseChanged(MovieRealtimePhase.catchingUp, current);
      var pollFailed = false;
      while (!_stopped) {
        final result = await _repository.pollEvents(cursor: current, take: 100);
        if (result case Success<MovieEventPage>(:final value)) {
          for (final event in value.items) {
            if (event.cursor <= current) continue;
            current = event.cursor;
            yield MovieRealtimeEventReceived(event);
          }
          if (value.nextCursor > current) current = value.nextCursor;
          if (!value.hasMore) break;
        } else if (result case Failure<MovieEventPage>(:final error)) {
          pollFailed = true;
          yield MovieRealtimeFailure(error, current);
          break;
        }
      }
      if (_stopped) break;

      if (pollFailed) {
        yield MovieRealtimePhaseChanged(
          MovieRealtimePhase.pollingFallback,
          current,
        );
        await Future<void>.delayed(_backoff(attempt++, current));
        continue;
      }

      try {
        yield MovieRealtimePhaseChanged(MovieRealtimePhase.live, current);
        await for (final event in _repository.streamEvents(cursor: current)) {
          if (_stopped) break;
          if (event.cursor <= current) continue;
          current = event.cursor;
          attempt = 0;
          yield MovieRealtimeEventReceived(event);
        }
      } catch (error) {
        if (!_stopped) yield MovieRealtimeFailure(error, current);
      }

      if (!_stopped) {
        yield MovieRealtimePhaseChanged(
          MovieRealtimePhase.reconnecting,
          current,
        );
        await Future<void>.delayed(_backoff(attempt++, current));
      }
    }
    yield MovieRealtimePhaseChanged(MovieRealtimePhase.stopped, current);
  }

  void stop() => _stopped = true;

  Duration _backoff(int attempt, int cursor) {
    final shift = attempt.clamp(0, 10);
    final base = initialBackoff.inMilliseconds * (1 << shift);
    final capped = base.clamp(
      initialBackoff.inMilliseconds,
      maximumBackoff.inMilliseconds,
    );
    final jitter = capped == 0
        ? 0
        : (cursor + attempt * 137) % (capped ~/ 4 + 1);
    return Duration(milliseconds: (capped + jitter).toInt());
  }
}
