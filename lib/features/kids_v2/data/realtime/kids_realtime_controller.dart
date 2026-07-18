import 'dart:async';
import 'dart:math';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../repositories/kids_v2_repositories.dart';
import '../../domain/models/kids_v2_models.dart';

abstract interface class KidsRealtimeCursorStore {
  Future<int> read(String paymentSessionId);
  Future<void> write(String paymentSessionId, int cursor);
}

class SecureStorageKidsRealtimeCursorStore implements KidsRealtimeCursorStore {
  const SecureStorageKidsRealtimeCursorStore(
    this._storage, {
    this.sessionNamespace = 'anonymous',
  });

  final SecureStorage _storage;
  final String sessionNamespace;

  String _key(String paymentSessionId) =>
      'ciervo.kids.realtime.$sessionNamespace.$paymentSessionId';

  @override
  Future<int> read(String paymentSessionId) async =>
      int.tryParse(await _storage.read(_key(paymentSessionId)) ?? '') ?? 0;

  @override
  Future<void> write(String paymentSessionId, int cursor) =>
      _storage.write(_key(paymentSessionId), '$cursor');
}

enum KidsRealtimePhase {
  stopped,
  catchingUp,
  live,
  pollingFallback,
  reconnecting,
  paused,
}

class KidsRealtimeState {
  const KidsRealtimeState({
    required this.phase,
    required this.cursor,
    this.lastEvent,
    this.message,
  });

  final KidsRealtimePhase phase;
  final int cursor;
  final KidsRealtimeEvent? lastEvent;
  final String? message;

  KidsRealtimeState copyWith({
    KidsRealtimePhase? phase,
    int? cursor,
    KidsRealtimeEvent? lastEvent,
    String? message,
    bool clearMessage = false,
  }) => KidsRealtimeState(
    phase: phase ?? this.phase,
    cursor: cursor ?? this.cursor,
    lastEvent: lastEvent ?? this.lastEvent,
    message: clearMessage ? null : message ?? this.message,
  );
}

typedef KidsDelay = Future<void> Function(Duration duration);

class KidsRealtimeController {
  KidsRealtimeController({
    required KidsRealtimeRepository repository,
    required KidsRealtimeCursorStore cursorStore,
    KidsDelay delay = Future<void>.delayed,
    Random? random,
    this.pollingInterval = const Duration(seconds: 3),
    this.baseBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
  }) : _repository = repository,
       _cursorStore = cursorStore,
       _delay = delay,
       _random = random ?? Random();

  final KidsRealtimeRepository _repository;
  final KidsRealtimeCursorStore _cursorStore;
  final KidsDelay _delay;
  final Random _random;
  final Duration pollingInterval;
  final Duration baseBackoff;
  final Duration maxBackoff;
  final _states = StreamController<KidsRealtimeState>.broadcast();
  final _events = StreamController<KidsRealtimeEvent>.broadcast();

  KidsRealtimeState _state = const KidsRealtimeState(
    phase: KidsRealtimePhase.stopped,
    cursor: 0,
  );
  StreamSubscription<Result<KidsRealtimeEvent>>? _liveSubscription;
  Future<void> _eventQueue = Future<void>.value();
  String? _paymentSessionId;
  int _generation = 0;
  bool _paused = false;
  bool _stopped = true;

  KidsRealtimeState get state => _state;
  Stream<KidsRealtimeState> get states => _states.stream;
  Stream<KidsRealtimeEvent> get events => _events.stream;

  Future<void> start(String paymentSessionId) async {
    await stop();
    _paymentSessionId = paymentSessionId;
    _stopped = false;
    _paused = false;
    final generation = ++_generation;
    final cursor = await _cursorStore.read(paymentSessionId);
    if (!_isCurrent(generation)) return;
    _emit(
      KidsRealtimeState(phase: KidsRealtimePhase.catchingUp, cursor: cursor),
    );
    unawaited(_run(generation, paymentSessionId));
  }

  Future<void> pause() async {
    if (_stopped || _paused) return;
    _paused = true;
    _generation++;
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    _emit(_state.copyWith(phase: KidsRealtimePhase.paused));
  }

  Future<void> resume() async {
    final sessionId = _paymentSessionId;
    if (_stopped || !_paused || sessionId == null) return;
    _paused = false;
    final generation = ++_generation;
    _emit(_state.copyWith(phase: KidsRealtimePhase.catchingUp));
    unawaited(_run(generation, sessionId));
  }

  Future<void> stop() async {
    _stopped = true;
    _paused = false;
    _generation++;
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    _paymentSessionId = null;
    _emit(_state.copyWith(phase: KidsRealtimePhase.stopped));
  }

  Future<void> dispose() async {
    await stop();
    await _states.close();
    await _events.close();
  }

  Future<void> _run(int generation, String sessionId) async {
    var failures = 0;
    while (_isCurrent(generation)) {
      _emit(
        _state.copyWith(
          phase: KidsRealtimePhase.catchingUp,
          clearMessage: true,
        ),
      );
      final caughtUp = await _catchUp(generation, sessionId);
      if (!_isCurrent(generation)) return;
      if (!caughtUp) {
        failures++;
        _emit(_state.copyWith(phase: KidsRealtimePhase.pollingFallback));
        await _wait(_fallbackDelay(failures), generation);
        continue;
      }

      failures = 0;
      _emit(_state.copyWith(phase: KidsRealtimePhase.live, clearMessage: true));
      final disconnected = Completer<void>();
      _liveSubscription = _repository
          .connect(sessionId, cursor: _state.cursor)
          .listen(
            (result) {
              result.when(
                success: (event) => _queueAccept(sessionId, event),
                failure: (error) {
                  _emit(
                    _state.copyWith(
                      phase: KidsRealtimePhase.pollingFallback,
                      message: UserErrorMessage.from(error),
                    ),
                  );
                  if (!disconnected.isCompleted) disconnected.complete();
                },
              );
            },
            onError: (Object error) {
              _emit(
                _state.copyWith(
                  phase: KidsRealtimePhase.pollingFallback,
                  message: UserErrorMessage.from(error),
                ),
              );
              if (!disconnected.isCompleted) disconnected.complete();
            },
            onDone: () {
              if (!disconnected.isCompleted) disconnected.complete();
            },
          );
      await disconnected.future;
      await _liveSubscription?.cancel();
      _liveSubscription = null;
      await _eventQueue;
      if (!_isCurrent(generation)) return;

      _emit(_state.copyWith(phase: KidsRealtimePhase.pollingFallback));
      await _wait(pollingInterval, generation);
      if (!_isCurrent(generation)) return;
      await _catchUp(generation, sessionId);
      if (!_isCurrent(generation)) return;
      _emit(_state.copyWith(phase: KidsRealtimePhase.reconnecting));
      failures++;
      await _wait(_backoff(failures), generation);
    }
  }

  Future<bool> _catchUp(int generation, String sessionId) async {
    while (_isCurrent(generation)) {
      final result = await _repository.poll(sessionId, cursor: _state.cursor);
      var succeeded = false;
      var hasMore = false;
      await result.when(
        success: (page) async {
          succeeded = true;
          final sorted = [...page.items]
            ..sort((a, b) => a.cursor.compareTo(b.cursor));
          for (final event in sorted) {
            await _accept(sessionId, event);
          }
          if (page.nextCursor > _state.cursor) {
            await _persistCursor(sessionId, page.nextCursor);
          }
          hasMore = page.hasMore;
        },
        failure: (error) async {
          _emit(_state.copyWith(message: UserErrorMessage.from(error)));
        },
      );
      if (!succeeded) return false;
      if (!hasMore) return true;
    }
    return false;
  }

  Future<void> _accept(String sessionId, KidsRealtimeEvent event) async {
    if (event.cursor <= _state.cursor) return;
    await _persistCursor(sessionId, event.cursor, event: event);
    if (!_events.isClosed) _events.add(event);
  }

  void _queueAccept(String sessionId, KidsRealtimeEvent event) {
    _eventQueue = _eventQueue.then((_) => _accept(sessionId, event)).catchError(
      (Object error) {
        _emit(_state.copyWith(message: UserErrorMessage.from(error)));
      },
    );
  }

  Future<void> _persistCursor(
    String sessionId,
    int cursor, {
    KidsRealtimeEvent? event,
  }) async {
    _emit(_state.copyWith(cursor: cursor, lastEvent: event));
    try {
      await _cursorStore.write(sessionId, cursor);
    } catch (error) {
      _emit(_state.copyWith(message: UserErrorMessage.from(error)));
    }
  }

  Duration _fallbackDelay(int failures) =>
      failures <= 1 ? pollingInterval : _backoff(failures);

  Duration _backoff(int failures) {
    final exponent = (failures - 1).clamp(0, 20);
    final multiplier = 1 << exponent;
    final rawMs = baseBackoff.inMilliseconds * multiplier;
    final cappedMs = min(rawMs, maxBackoff.inMilliseconds);
    final jitter = cappedMs == 0 ? 0 : _random.nextInt(max(1, cappedMs ~/ 4));
    return Duration(
      milliseconds: min(cappedMs + jitter, maxBackoff.inMilliseconds),
    );
  }

  Future<void> _wait(Duration duration, int generation) async {
    await _delay(duration);
    if (!_isCurrent(generation)) return;
  }

  bool _isCurrent(int generation) =>
      !_stopped && !_paused && generation == _generation;

  void _emit(KidsRealtimeState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }
}
