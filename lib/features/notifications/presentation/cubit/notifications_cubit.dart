import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());
  final NotificationsRepository _repository;

  Future<void> load({String? category}) async {
    emit(NotificationsState(
      status: NotificationsStatus.loading,
      selectedCategory: category,
    ));
    final result = await _repository.notifications(category: category);
    result.when(
      success: (items) => emit(
        NotificationsState(
          status: items.isEmpty
              ? NotificationsStatus.empty
              : NotificationsStatus.loaded,
          items: items,
          selectedCategory: category,
        ),
      ),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          errorMessage: UserErrorMessage.from(error),
          selectedCategory: category,
        ),
      ),
    );
  }

  Future<void> markAsRead(String id) async {
    emit(NotificationsState(
      status: NotificationsStatus.actionLoading,
      items: state.items,
      selectedCategory: state.selectedCategory,
    ));
    final result = await _repository.markAsRead(id);
    result.when(
      success: (_) => load(category: state.selectedCategory),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          items: state.items,
          errorMessage: UserErrorMessage.from(error),
          selectedCategory: state.selectedCategory,
        ),
      ),
    );
  }

  Future<void> markAllAsRead() async {
    emit(NotificationsState(
      status: NotificationsStatus.actionLoading,
      items: state.items,
      selectedCategory: state.selectedCategory,
    ));
    final result = await _repository.markAllAsRead();
    result.when(
      success: (_) => load(category: state.selectedCategory),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          items: state.items,
          errorMessage: UserErrorMessage.from(error),
          selectedCategory: state.selectedCategory,
        ),
      ),
    );
  }

  Future<void> deleteNotification(String id) async {
    final result = await _repository.deleteNotification(id);
    result.when(
      success: (_) => load(category: state.selectedCategory),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          items: state.items,
          errorMessage: UserErrorMessage.from(error),
          selectedCategory: state.selectedCategory,
        ),
      ),
    );
  }

  Future<void> deleteAll() async {
    final result = await _repository.deleteAllNotifications();
    result.when(
      success: (_) => load(category: state.selectedCategory),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          items: state.items,
          errorMessage: UserErrorMessage.from(error),
          selectedCategory: state.selectedCategory,
        ),
      ),
    );
  }
}
