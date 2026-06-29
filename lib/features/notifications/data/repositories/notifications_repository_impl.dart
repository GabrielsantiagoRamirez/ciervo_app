import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_badges.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remoteDataSource);
  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<AppNotification>>> notifications({
    String? category,
    String? type,
    bool? isRead,
  }) async {
    try {
      final items = await _remoteDataSource.notifications(
        category: category,
        type: type,
        isRead: isRead,
      );
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<NotificationBadges>> badges() async {
    try {
      return Success(await _remoteDataSource.badges());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> markAsRead(String id) => _void(
        () => _remoteDataSource.markAsRead(id),
      );

  @override
  Future<Result<void>> markAllAsRead() => _void(
        () => _remoteDataSource.markAllAsRead(),
      );

  @override
  Future<Result<void>> deleteNotification(String id) => _void(
        () => _remoteDataSource.deleteNotification(id),
      );

  @override
  Future<Result<void>> deleteAllNotifications() => _void(
        () => _remoteDataSource.deleteAllNotifications(),
      );

  @override
  Future<Result<Map<String, dynamic>>> preferences() async {
    try {
      return Success(await _remoteDataSource.preferences());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> updatePreferences(Map<String, dynamic> preferences) =>
      _void(() => _remoteDataSource.updatePreferences(preferences));

  Future<Result<void>> _void(Future<void> Function() action) async {
    try {
      await action();
      return const Success(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
