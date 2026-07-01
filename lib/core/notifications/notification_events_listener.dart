import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../di/service_locator.dart';
import '../session/session_manager.dart';
import '../../features/memberships/presentation/cubit/membership_cubit.dart';
import 'notifications_sync.dart';

/// Escucha SSE de `/api/notifications/events` y dispara sync de inbox.
class NotificationEventsListener {
  NotificationEventsListener(
    this._config,
    this._sessionManager,
    this._notificationsSync,
  );

  final AppConfig _config;
  final SessionManager _sessionManager;
  final NotificationsSync _notificationsSync;

  CancelToken? _cancelToken;
  int _sinceId = 0;

  Future<void> start() async {
    if (_cancelToken != null) return;
    final token = await _sessionManager.accessToken();
    if (token == null || token.isEmpty) return;

    _cancelToken = CancelToken();
    unawaited(_listen(token, _cancelToken!));
  }

  void stop() {
    _cancelToken?.cancel();
    _cancelToken = null;
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
        '/api/notifications/events',
        queryParameters: {'sinceId': _sinceId},
        cancelToken: cancelToken,
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      var buffer = '';
      await for (final chunk in stream) {
        if (cancelToken.isCancelled) break;
        buffer += utf8.decode(chunk, allowMalformed: true);
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
        await Future<void>.delayed(const Duration(seconds: 5));
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
            }
            final eventType = '${notification['eventType'] ?? notification['type'] ?? notification['category'] ?? ''}';
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
}

void startNotificationEventsListener() {
  if (!getIt.isRegistered<NotificationEventsListener>()) return;
  unawaited(getIt<NotificationEventsListener>().start());
}

void stopNotificationEventsListener() {
  if (!getIt.isRegistered<NotificationEventsListener>()) return;
  getIt<NotificationEventsListener>().stop();
}
