import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_channels.dart';

/// Presentación de notificaciones locales (foreground y background FCM).
abstract final class NotificationPresenter {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          onNotificationTap?.call(data);
        } catch (_) {}
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final channel in CiervoNotificationChannels.androidChannels()) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    _initialized = true;
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    await ensureInitialized();

    final notification = message.notification;
    final data = message.data;
    final title =
        notification?.title ?? data['title']?.toString() ?? 'CIERVO CLUB';
    final body = notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        '';
    if (body.isEmpty && title == 'CIERVO CLUB') return;

    final category = data['category']?.toString();
    final channelId = CiervoNotificationChannels.channelForCategory(category);

    await _plugin.show(
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
}
