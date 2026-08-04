import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_badges.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationBadgesCubit extends Cubit<NotificationBadges> {
  NotificationBadgesCubit(this._repository) : super(const NotificationBadges());

  final NotificationsRepository _repository;
  int _localChatUnread = 0;
  bool _chatFromInbox = false;
  DateTime? _lastRemoteFetchAt;
  Future<void>? _inFlight;

  /// Evita rafagas de GET /badges al cambiar de pestaña.
  static const minRemoteInterval = Duration(seconds: 12);

  Future<void> refresh({bool force = false}) async {
    if (!force &&
        _lastRemoteFetchAt != null &&
        DateTime.now().difference(_lastRemoteFetchAt!) < minRemoteInterval) {
      return;
    }
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _fetch();
    _inFlight = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  Future<void> _fetch() async {
    final result = await _repository.badges();
    _lastRemoteFetchAt = DateTime.now();
    result.when(
      success: (remote) => emit(_merge(remote)),
      failure: (_) {
        if (_chatFromInbox || _localChatUnread > 0) emit(_merge(state));
      },
    );
  }

  /// Complementa el badge de Chat con unread del inbox (API de conversaciones).
  /// Tras cargar el inbox, este valor manda sobre el remoto (evita badges fantasma).
  void setLocalChatUnread(int count) {
    _localChatUnread = count < 0 ? 0 : count;
    _chatFromInbox = true;
    emit(_merge(state));
  }

  NotificationBadges _merge(NotificationBadges remote) {
    final chat = _chatFromInbox
        ? _localChatUnread
        : (remote.chat > _localChatUnread ? remote.chat : _localChatUnread);
    final extra = chat - remote.chat;
    final total = remote.total + (extra > 0 ? extra : 0);
    return NotificationBadges(
      total: total,
      wallet: remote.wallet,
      chat: chat,
      delivery: remote.delivery,
      reservations: remote.reservations,
      promos: remote.promos,
    );
  }

  /// Reinicia los contadores al cerrar sesión para no mostrar datos ajenos.
  void clear() {
    _localChatUnread = 0;
    _chatFromInbox = false;
    _lastRemoteFetchAt = null;
    _inFlight = null;
    emit(const NotificationBadges());
  }
}
