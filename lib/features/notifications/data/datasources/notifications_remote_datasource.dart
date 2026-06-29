import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
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
  Future<void> registerFcmToken(String token);
  Future<void> unregisterFcmToken(String token);
  Future<void> unregisterAllFcmTokens();
}

class DioNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  const DioNotificationsRemoteDataSource(this._client);
  final NetworkClient _client;

  @override
  Future<List<AppNotificationDto>> notifications({
    String? category,
    String? type,
    bool? isRead,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/notifications',
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
    final response =
        await _client.dio.get<Map<String, dynamic>>('/api/notifications/badges');
    return NotificationBadges.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.dio.post<void>('/api/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _client.dio.post<void>('/api/notifications/read-all');
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _client.dio.delete<void>('/api/notifications/$id');
  }

  @override
  Future<void> deleteAllNotifications() async {
    await _client.dio.delete<void>('/api/notifications');
  }

  @override
  Future<Map<String, dynamic>> preferences() async {
    final response =
        await _client.dio.get<dynamic>('/api/notifications/preferences');
    return unwrapApiMap(response.data);
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    await _client.dio.put<void>(
      '/api/notifications/preferences',
      data: preferences,
    );
  }

  @override
  Future<void> registerFcmToken(String token) async {
    await _client.dio.post<void>(
      '/api/notifications/fcm/register',
      data: {'token': token, 'platform': _platformLabel()},
    );
  }

  @override
  Future<void> unregisterFcmToken(String token) async {
    await _client.dio.post<void>(
      '/api/notifications/fcm/unregister',
      data: {'token': token},
    );
  }

  @override
  Future<void> unregisterAllFcmTokens() async {
    await _client.dio.delete<void>('/api/notifications/fcm/tokens');
  }

  String _platformLabel() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };
  }
}
