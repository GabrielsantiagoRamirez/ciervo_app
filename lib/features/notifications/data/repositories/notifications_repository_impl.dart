import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remoteDataSource);
  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<AppNotification>>> notifications() async {
    try {
      final items = await _remoteDataSource.notifications();
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    try {
      await _remoteDataSource.markAsRead(id);
      return const Success<void>(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    try {
      await _remoteDataSource.markAllAsRead();
      return const Success<void>(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> preferences() async {
    try {
      return Success(await _remoteDataSource.preferences());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _remoteDataSource.updatePreferences(preferences);
      return const Success<void>(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
