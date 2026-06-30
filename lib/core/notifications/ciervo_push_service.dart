import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../session/session_manager.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'notification_channels.dart';
import 'notification_deep_link.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Servicio FCM + notificaciones locales CIERVO CLUB.
class CiervoPushService {
  CiervoPushService(this._dataSource, this._sessionManager);

  final NotificationsRemoteDataSource _dataSource;
  final SessionManager _sessionManager;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _firebaseReady = false;
  String? _currentToken;

  void bindNavigator(GlobalKey<NavigatorState> key) => _navigatorKey = key;

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
    await _initLocalNotifications();

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
    // Permiso de notificaciones: AppPermissionService tras autenticación.
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

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _openPayload(data);
        } catch (_) {}
      },
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final channel in CiervoNotificationChannels.androidChannels()) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
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
    final notification = message.notification;
    final data = message.data;
    final title =
        notification?.title ?? data['title']?.toString() ?? 'CIERVO CLUB';
    final body = notification?.body ?? data['body']?.toString() ?? '';
    final category = data['category']?.toString();
    final channelId = CiervoNotificationChannels.channelForCategory(category);

    _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'CIERVO CLUB',
          channelDescription: category ?? 'Notificacion',
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD4AF37),
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _onOpenedFromPush(RemoteMessage message) {
    _handleOpenedPayload(message.data);
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
}
