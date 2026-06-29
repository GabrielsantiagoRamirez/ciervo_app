import '../../../../core/result/result.dart';
import '../entities/app_notification.dart';
import '../entities/notification_badges.dart';

abstract interface class NotificationsRepository {
  Future<Result<List<AppNotification>>> notifications({
    String? category,
    String? type,
    bool? isRead,
  });
  Future<Result<NotificationBadges>> badges();
  Future<Result<void>> markAsRead(String id);
  Future<Result<void>> markAllAsRead();
  Future<Result<void>> deleteNotification(String id);
  Future<Result<void>> deleteAllNotifications();
  Future<Result<Map<String, dynamic>>> preferences();
  Future<Result<void>> updatePreferences(Map<String, dynamic> preferences);
}
