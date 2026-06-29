import '../../domain/entities/app_notification.dart';

enum NotificationsStatus {
  initial,
  loading,
  loaded,
  empty,
  failure,
  actionLoading,
}

class NotificationsState {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.selectedCategory,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final String? errorMessage;
  final String? selectedCategory;
}
