import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';
import '../di/service_locator.dart';
import '../session/session_manager.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'firebase_messaging_background.dart';
import 'notification_deep_link.dart';
import 'notification_presenter.dart';
import 'notifications_sync.dart';

/// Servicio FCM + notificaciones locales CIERVO CLUB.
class CiervoPushService {
  CiervoPushService(this._dataSource, this._sessionManager);

  final NotificationsRemoteDataSource _dataSource;
  final SessionManager _sessionManager;

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _firebaseReady = false;
  String? _currentToken;

  void bindNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    NotificationPresenter.onNotificationTap = _handleOpenedPayload;
  }

  Future<void> initialize() async {
    try {
      await _initializeInternal().timeout(const Duration(seconds: 12));
    } on TimeoutException {
      debugPrint('[FCM] Inicializacion cancelada por tiempo de espera.');
    } catch (error) {
      debugPrint('[FCM] Inicializacion fallida: $error');
    }
  }

  Future<void> _initializeInternal() async {
    await NotificationPresenter.ensureInitialized();

    if (!_hasValidFirebaseOptions()) {
      debugPrint(
        '[FCM] Firebase omitido: ejecuta flutterfire configure para FCM real.',
      );
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseReady = true;
    } catch (error) {
      debugPrint('[FCM] Firebase no configurado: $error');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedFromPush);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleOpenedPayload(initial.data);

    messaging.onTokenRefresh.listen(_registerToken);
    final token = await messaging.getToken().timeout(const Duration(seconds: 8));
    if (token != null) await _registerToken(token);
  }

  bool _hasValidFirebaseOptions() {
    const placeholder = 'REPLACE_WITH_FLUTTERFIRE';
    final options = DefaultFirebaseOptions.currentPlatform;
    return options.apiKey != placeholder &&
        options.appId != placeholder &&
        options.messagingSenderId != placeholder;
  }

  Future<void> syncTokenIfAuthenticated() async {
    if (!_firebaseReady) return;
    if (_sessionManager.state.status.name != 'authenticated') return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (_) {}
  }

  Future<void> unregisterAllTokens() async {
    try {
      await _dataSource.unregisterAllFcmTokens();
      if (_firebaseReady) {
        await FirebaseMessaging.instance.deleteToken();
      }
      _currentToken = null;
    } catch (error) {
      debugPrint('[FCM] unregister error: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    if (token == _currentToken) return;
    _currentToken = token;
    try {
      await _dataSource.registerFcmToken(token);
    } catch (error) {
      debugPrint('[FCM] register token error: $error');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    unawaited(NotificationPresenter.showRemoteMessage(message));
    _notifyInboxRefresh();
  }

  void _onOpenedFromPush(RemoteMessage message) {
    _handleOpenedPayload(message.data);
    _notifyInboxRefresh();
  }

  void _handleOpenedPayload(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPayload(data);
    });
  }

  void _openPayload(Map<String, dynamic> data) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    NotificationDeepLink.openFromPayload(context, data);
  }

  void _notifyInboxRefresh() {
    if (getIt.isRegistered<NotificationsSync>()) {
      getIt<NotificationsSync>().notifyInboxMayHaveChanged();
    }
  }
}
