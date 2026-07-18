import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../di/service_locator.dart';
import '../session/auth_token_claims.dart';
import '../session/session_manager.dart';
import '../storage/secure_storage.dart';
import '../../features/memberships/presentation/cubit/membership_cubit.dart';
import 'notifications_sync.dart';

/// Escucha SSE de `/api/v1/notifications/events` y dispara sync de inbox.
class NotificationEventsListener {
  NotificationEventsListener(
    this._config,
    this._sessionManager,
    this._notificationsSync,
    this._storage,
  );

  final AppConfig _config;
  final SessionManager _sessionManager;
  final NotificationsSync _notificationsSync;
  final SecureStorage _storage;

  CancelToken? _cancelToken;
  int _sinceId = 0;
  int _reconnectAttempt = 0;
  String? _activeCursorKey;
  static const _cursorKeyPrefix = 'ciervo.notifications.sinceId';

  Future<void> start() async {
    if (_cancelToken != null) return;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    final token = await _sessionManager.accessToken();
    if (token == null || token.isEmpty) {
      _cancelToken = null;
      return;
    }
    final cursorKey = _cursorKeyFor(token);
    if (_activeCursorKey != cursorKey) {
      _activeCursorKey = cursorKey;
      _sinceId = cursorKey == null
          ? 0
          : int.tryParse(await _storage.read(cursorKey) ?? '') ?? 0;
    }

    unawaited(_listen(token, cancelToken));
  }

  void stop({bool clearCursor = false}) {
    _cancelToken?.cancel();
    _cancelToken = null;
    _reconnectAttempt = 0;
    if (clearCursor) {
      final cursorKey = _activeCursorKey;
      if (cursorKey != null) unawaited(_storage.delete(cursorKey));
      _activeCursorKey = null;
      _sinceId = 0;
    }
  }

  Future<void> _listen(String token, CancelToken cancelToken) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: _config.apiBaseUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: Duration.zero,
        ),
      );

      final response = await dio.get<ResponseBody>(
        '/api/v1/notifications/events',
        queryParameters: {'sinceId': _sinceId},
        cancelToken: cancelToken,
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      var buffer = '';
      await for (final chunk in stream) {
        if (cancelToken.isCancelled) break;
        buffer += utf8
            .decode(chunk, allowMalformed: true)
            .replaceAll('\r\n', '\n');
        _reconnectAttempt = 0;
        while (buffer.contains('\n\n')) {
          final index = buffer.indexOf('\n\n');
          final block = buffer.substring(0, index);
          buffer = buffer.substring(index + 2);
          _handleSseBlock(block);
        }
      }
    } catch (_) {
      // SSE es complemento; el polling existente sigue activo.
    } finally {
      if (!cancelToken.isCancelled) {
        _cancelToken = null;
        final delays = <int>[1, 2, 5, 10, 30];
        final seconds = delays[min(_reconnectAttempt, delays.length - 1)];
        _reconnectAttempt++;
        final jitter = Random.secure().nextInt(500);
        await Future<void>.delayed(
          Duration(seconds: seconds, milliseconds: jitter),
        );
        await start();
      }
    }
  }

  void _handleSseBlock(String block) {
    for (final line in block.split('\n')) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      try {
        final map = jsonDecode(payload);
        if (map is Map<String, dynamic>) {
          final notification = map['notification'];
          if (notification is Map<String, dynamic>) {
            final id = notification['id'];
            final parsed = id is int ? id : int.tryParse('$id');
            if (parsed != null && parsed > _sinceId) {
              _sinceId = parsed;
              final cursorKey = _activeCursorKey;
              if (cursorKey != null) {
                unawaited(_storage.write(cursorKey, '$_sinceId'));
              }
            }
            final eventType =
                '${notification['eventType'] ?? notification['type'] ?? notification['category'] ?? ''}';
            if (eventType.toLowerCase().startsWith('membership.')) {
              unawaited(getIt<MembershipCubit>().loadFresh());
            }
          }
        }
      } catch (_) {}
      _notificationsSync.refreshInbox();
      break;
    }
  }

  String? _cursorKeyFor(String token) {
    final userId = AuthTokenClaims.fromJwt(token).userId;
    if (userId == null || userId.trim().isEmpty) return null;
    final encoded = base64Url.encode(utf8.encode(userId)).replaceAll('=', '');
    return '$_cursorKeyPrefix.$encoded';
  }
}

void startNotificationEventsListener() {
  if (!getIt.isRegistered<NotificationEventsListener>()) return;
  unawaited(getIt<NotificationEventsListener>().start());
}

void stopNotificationEventsListener({bool clearCursor = false}) {
  if (!getIt.isRegistered<NotificationEventsListener>()) return;
  getIt<NotificationEventsListener>().stop(clearCursor: clearCursor);
}
