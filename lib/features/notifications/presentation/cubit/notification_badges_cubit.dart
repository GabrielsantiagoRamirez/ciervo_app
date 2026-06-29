import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_badges.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationBadgesCubit extends Cubit<NotificationBadges> {
  NotificationBadgesCubit(this._repository)
      : super(const NotificationBadges());

  final NotificationsRepository _repository;

  Future<void> refresh() async {
    final result = await _repository.badges();
    result.when(
      success: emit,
      failure: (_) {},
    );
  }
}
