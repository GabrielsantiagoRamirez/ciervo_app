import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_channels.dart';

class _GroupedNotificationLine {
  const _GroupedNotificationLine({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

/// Presentación de notificaciones locales (foreground y background FCM).
abstract final class NotificationPresenter {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Historial corto por grupo para el resumen estilo inbox.
  static final Map<String, List<_GroupedNotificationLine>> _groupInbox = {};
  static const _maxInboxLines = 6;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@drawable/ic_stat_ciervo');
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

    // Cold start: tap en notificación local con la app cerrada.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          // Diferir hasta que haya listener (navigator bound).
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            onNotificationTap?.call(data);
          });
        } catch (_) {}
      }
    }

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
    final title = _brandSafe(
      _firstNonEmpty([
        notification?.title,
        data['title']?.toString(),
        data['senderName']?.toString(),
        data['subject']?.toString(),
        data['heading']?.toString(),
      ]),
    );
    final body = _brandSafe(
      _firstNonEmpty([
        notification?.body,
        data['previewText']?.toString(),
        data['body']?.toString(),
        data['message']?.toString(),
        data['text']?.toString(),
        data['content']?.toString(),
        data['description']?.toString(),
      ]),
    );

    if (title == null && body == null) {
      debugPrint('[Notifications] Push sin titulo ni cuerpo: ${data.keys}');
      return;
    }

    final displayTitle = title ?? 'CIERVO CLUB';
    final displayBody = body ?? 'Tienes una nueva actualización.';

    final category = data['category']?.toString() ?? data['type']?.toString();
    final channelId = CiervoNotificationChannels.channelForCategory(category);
    final channelName = CiervoNotificationChannels.labelForChannel(channelId);
    final groupKey = 'ciervo_group_$channelId';
    final summaryId = groupKey.hashCode & 0x7fffffff;

    final lines = _groupInbox.putIfAbsent(
      groupKey,
      () => <_GroupedNotificationLine>[],
    );
    lines.insert(
      0,
      _GroupedNotificationLine(title: displayTitle, body: displayBody),
    );
    if (lines.length > _maxInboxLines) {
      lines.removeRange(_maxInboxLines, lines.length);
    }

    final childId =
        message.messageId?.hashCode ?? DateTime.now().microsecondsSinceEpoch;
    final payload = jsonEncode(_safePayload(data));
    final inboxLines = lines
        .map((line) => '${line.title}: ${line.body}')
        .toList(growable: false);
    final summaryTitle = lines.length == 1
        ? 'CIERVO CLUB'
        : 'CIERVO CLUB · ${lines.length} notificaciones';
    final summaryBody = lines.length == 1
        ? displayBody
        : lines.map((line) => '• ${line.title}').take(3).join('\n');

    try {
      await _plugin.show(
        childId,
        displayTitle,
        displayBody,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription:
                CiervoNotificationChannels.descriptionForChannel(channelId),
            icon: '@drawable/ic_stat_ciervo',
            color: const Color(CiervoNotificationChannels.brandColor),
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
            styleInformation: BigTextStyleInformation(displayBody),
            category: AndroidNotificationCategory.message,
            groupKey: groupKey,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier: 'ciervo',
          ),
        ),
        payload: payload,
      );

      // Resumen agrupado (una sola tarjeta expandible con lista).
      await _plugin.show(
        summaryId,
        summaryTitle,
        summaryBody,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription:
                CiervoNotificationChannels.descriptionForChannel(channelId),
            icon: '@drawable/ic_stat_ciervo',
            color: const Color(CiervoNotificationChannels.brandColor),
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
            groupKey: groupKey,
            setAsGroupSummary: true,
            styleInformation: InboxStyleInformation(
              inboxLines,
              contentTitle: summaryTitle,
              summaryText: '${lines.length} actualizaciones',
            ),
            category: AndroidNotificationCategory.message,
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: true,
            presentSound: false,
            threadIdentifier: 'ciervo',
          ),
        ),
        payload: payload,
      );
    } catch (error) {
      debugPrint('[Notifications] Error al mostrar: ${error.runtimeType}');
    }
  }

  static String? _brandSafe(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text
        .replaceAll(RegExp('vakuply', caseSensitive: false), 'Vaku')
        .replaceAll(RegExp('vakupli', caseSensitive: false), 'Vaku');
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
      'previewText',
      'senderName',
      'messageType',
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
