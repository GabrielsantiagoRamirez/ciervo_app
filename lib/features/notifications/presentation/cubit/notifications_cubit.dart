import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());
  final NotificationsRepository _repository;

  Future<void> load() async {
    emit(const NotificationsState(status: NotificationsStatus.loading));
    final result = await _repository.notifications();
    result.when(
      success: (items) => emit(
        NotificationsState(
          status:
              items.isEmpty ? NotificationsStatus.empty : NotificationsStatus.loaded,
          items: items,
        ),
      ),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> markAsRead(String id) async {
    emit(NotificationsState(status: NotificationsStatus.actionLoading, items: state.items));
    final result = await _repository.markAsRead(id);
    result.when(
      success: (_) => load(),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          items: state.items,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> markAllAsRead() async {
    emit(NotificationsState(
      status: NotificationsStatus.actionLoading,
      items: state.items,
    ));
    final result = await _repository.markAllAsRead();
    result.when(
      success: (_) => load(),
      failure: (error) => emit(
        NotificationsState(
          status: NotificationsStatus.failure,
          items: state.items,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }
}
