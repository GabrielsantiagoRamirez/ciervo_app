import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/app_notification_dto.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<List<AppNotificationDto>> notifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<Map<String, dynamic>> preferences();
  Future<void> updatePreferences(Map<String, dynamic> preferences);
}

class DioNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  const DioNotificationsRemoteDataSource(this._client);
  final NetworkClient _client;

  @override
  Future<List<AppNotificationDto>> notifications() async {
    final response = await _client.dio.get<dynamic>('/api/notifications');
    return AppNotificationDto.listFrom(unwrapApiResponse(response.data));
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
}
