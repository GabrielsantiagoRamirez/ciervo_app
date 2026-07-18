import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      for (final channel in CiervoNotificationChannels.androidChannels()) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    _initialized = true;
  }

  static Future<bool> requestDisplayPermission() async {
    await ensureInitialized();
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        if (enabled == true) return true;
        final requested = await androidPlugin.requestNotificationsPermission();
        if (requested == true) return true;
      }
      final status = await Permission.notification.request();
      return status.isGranted || status.isLimited;
    } catch (error) {
      debugPrint('[Notifications] permiso Android: ${error.runtimeType}');
      return false;
    }
  }

  static Future<bool> hasDisplayPermission() async {
    await ensureInitialized();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() == true;
    }
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    await ensureInitialized();

    final allowed = await hasDisplayPermission();
    if (!allowed) {
      debugPrint(
        '[Notifications] Sin permiso POST_NOTIFICATIONS; no se muestra en bandeja.',
      );
      return;
    }

    final notification = message.notification;
    final data = message.data;
    final title = _firstNonEmpty([
      notification?.title,
      data['title']?.toString(),
      data['subject']?.toString(),
      data['heading']?.toString(),
    ]);
    final body = _firstNonEmpty([
      notification?.body,
      data['body']?.toString(),
      data['message']?.toString(),
      data['text']?.toString(),
      data['content']?.toString(),
      data['description']?.toString(),
    ]);

    if (title == null && body == null) {
      debugPrint('[Notifications] Push sin titulo ni cuerpo: ${data.keys}');
      return;
    }

    final displayTitle = title ?? 'CIERVO CLUB';
    final displayBody = body ?? 'Tienes una nueva actualización.';

    final category = data['category']?.toString() ?? data['type']?.toString();
    final channelId = CiervoNotificationChannels.channelForCategory(category);
    final channelName = CiervoNotificationChannels.labelForChannel(channelId);

    final notificationId =
        message.messageId?.hashCode ?? DateTime.now().microsecondsSinceEpoch;

    try {
      await _plugin.show(
        notificationId,
        displayTitle,
        displayBody,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription:
                CiervoNotificationChannels.descriptionForChannel(channelId),
            icon: '@mipmap/ic_launcher',
            color: const Color(CiervoNotificationChannels.brandColor),
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
            styleInformation: BigTextStyleInformation(displayBody),
            category: AndroidNotificationCategory.message,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(_safePayload(data)),
      );
    } catch (error) {
      debugPrint('[Notifications] Error al mostrar: ${error.runtimeType}');
    }
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static Map<String, dynamic> _safePayload(Map<String, dynamic> data) {
    const allowedKeys = {
      'type',
      'category',
      'deepLink',
      'resourceId',
      'publicId',
      'conversationId',
      'chatConversationId',
      'tripId',
      'orderId',
      'bonusId',
    };
    return <String, dynamic>{
      for (final entry in data.entries)
        if (allowedKeys.contains(entry.key) &&
            (entry.value is String ||
                entry.value is num ||
                entry.value is bool))
          entry.key: entry.value,
    };
  }
}
