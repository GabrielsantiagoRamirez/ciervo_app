import '../../../../core/result/result.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<Result<List<AppNotification>>> notifications();
  Future<Result<void>> markAsRead(String id);
  Future<Result<void>> markAllAsRead();
  Future<Result<Map<String, dynamic>>> preferences();
  Future<Result<void>> updatePreferences(Map<String, dynamic> preferences);
}
