import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

import '../../../../core/device/device_installation_service.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/version/app_version_service.dart';
import '../dtos/app_notification_dto.dart';
import '../../domain/entities/notification_badges.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<List<AppNotificationDto>> notifications({
    String? category,
    String? type,
    bool? isRead,
  });
  Future<NotificationBadges> badges();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> deleteAllNotifications();
  Future<Map<String, dynamic>> preferences();
  Future<void> updatePreferences(Map<String, dynamic> preferences);
  Future<void> registerFcmToken(String token, {String? deviceId});
  Future<void> unregisterFcmToken(String token, {String? deviceId});
  Future<void> unregisterAllFcmTokens();
}

class DioNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  const DioNotificationsRemoteDataSource(
    this._client,
    this._deviceInstallation,
    this._appVersion,
  );

  final NetworkClient _client;
  final DeviceInstallationService _deviceInstallation;
  final AppVersionService _appVersion;
  static const _base = '/api/v1/notifications';

  @override
  Future<List<AppNotificationDto>> notifications({
    String? category,
    String? type,
    bool? isRead,
  }) async {
    final response = await _client.dio.get<dynamic>(
      _base,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (type != null && type.isNotEmpty) 'type': type,
        if (isRead != null) 'isRead': isRead,
      },
    );
    return AppNotificationDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<NotificationBadges> badges() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '$_base/badges',
    );
    return NotificationBadges.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.dio.post<void>('$_base/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _client.dio.post<void>('$_base/read-all');
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _client.dio.delete<void>('$_base/$id');
  }

  @override
  Future<void> deleteAllNotifications() async {
    await _client.dio.delete<void>(_base);
  }

  @override
  Future<Map<String, dynamic>> preferences() async {
    final response = await _client.dio.get<dynamic>('$_base/preferences');
    return unwrapApiMap(response.data);
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    await _client.dio.put<void>('$_base/preferences', data: preferences);
  }

  @override
  Future<void> registerFcmToken(String token, {String? deviceId}) async {
    await _client.dio.post<void>(
      '$_base/fcm/register',
      data: {
        'fcmToken': token,
        'platform': _platformLabel(),
        'deviceId': deviceId ?? await _deviceInstallation.deviceId(),
        'appVersion': await _appVersion.version(),
      },
    );
  }

  @override
  Future<void> unregisterFcmToken(String token, {String? deviceId}) async {
    await _client.dio.post<void>(
      '$_base/fcm/unregister',
      data: {
        'fcmToken': token,
        'deviceId': deviceId ?? await _deviceInstallation.deviceId(),
      },
    );
  }

  @override
  Future<void> unregisterAllFcmTokens() async {
    await _client.dio.delete<void>('$_base/fcm/tokens');
  }

  String _platformLabel() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };
  }
}
