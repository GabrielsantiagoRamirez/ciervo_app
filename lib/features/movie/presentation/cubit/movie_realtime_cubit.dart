import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/realtime/movie_realtime_service.dart';
import '../../data/realtime/movie_realtime_cursor_store.dart';
import '../../domain/models/movie_models.dart';

class MovieRealtimeState {
  const MovieRealtimeState({
    this.phase = MovieRealtimePhase.stopped,
    this.cursor = 0,
    this.events = const [],
    this.lastError,
  });

  final MovieRealtimePhase phase;
  final int cursor;
  final List<MovieEvent> events;
  final Object? lastError;

  MovieRealtimeState copyWith({
    MovieRealtimePhase? phase,
    int? cursor,
    List<MovieEvent>? events,
    Object? lastError,
    bool clearError = false,
  }) => MovieRealtimeState(
    phase: phase ?? this.phase,
    cursor: cursor ?? this.cursor,
    events: events ?? this.events,
    lastError: clearError ? null : lastError ?? this.lastError,
  );
}

class MovieRealtimeCubit extends Cubit<MovieRealtimeState> {
  MovieRealtimeCubit(this._service, {MovieRealtimeCursorStore? cursorStore})
    : _cursorStore = cursorStore,
      super(const MovieRealtimeState());

  final MovieRealtimeService _service;
  final MovieRealtimeCursorStore? _cursorStore;
  StreamSubscription<MovieRealtimeUpdate>? _subscription;

  /// Inicia o reanuda una sesión usando el cursor durable conservado por UI.
  Future<void> startSession({int? cursor, bool clearEvents = false}) async {
    await stop();
    final initialCursor = cursor ?? await _cursorStore?.read() ?? 0;
    emit(
      state.copyWith(
        cursor: initialCursor,
        events: clearEvents ? const [] : state.events,
        clearError: true,
      ),
    );
    _subscription = _service.watch(cursor: initialCursor).listen(_onUpdate);
  }

  /// Alias compatible con integraciones existentes.
  Future<void> start({int? cursor}) async {
    await startSession(cursor: cursor);
  }

  void _onUpdate(MovieRealtimeUpdate update) {
    switch (update) {
      case MovieRealtimePhaseChanged(:final phase, :final cursor):
        emit(state.copyWith(phase: phase, cursor: cursor));
        unawaited(_cursorStore?.write(cursor));
      case MovieRealtimeEventReceived(:final event):
        final events = [...state.events, event];
        emit(
          state.copyWith(
            cursor: event.cursor,
            events: events.length > 100
                ? events.sublist(events.length - 100)
                : events,
            clearError: true,
          ),
        );
        unawaited(_cursorStore?.write(event.cursor));
      case MovieRealtimeFailure(:final error, :final cursor):
        emit(state.copyWith(lastError: error, cursor: cursor));
    }
  }

  /// Detiene la conexión y devuelve el cursor que debe conservar la sesión.
  Future<int> pauseSession() async {
    await stop();
    return state.cursor;
  }

  Iterable<MovieEvent> eventsForRequest(String requestId) => state.events.where(
    (event) =>
        event.aggregateId == requestId ||
        event.payloadJson?.contains(requestId) == true,
  );

  Future<void> stop() async {
    _service.stop();
    await _subscription?.cancel();
    _subscription = null;
    if (!isClosed) {
      emit(state.copyWith(phase: MovieRealtimePhase.stopped));
    }
  }

  @override
  Future<void> close() async {
    _service.stop();
    await _subscription?.cancel();
    return super.close();
  }
}
