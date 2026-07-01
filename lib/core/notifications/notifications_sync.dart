import 'dart:async';

/// Señal para refrescar badges y la bandeja in-app cuando llega un push
/// o termina una acción importante (pago, recarga, transferencia, chat).
class NotificationsSync {
  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get onRefresh => _controller.stream;

  void notifyInboxMayHaveChanged() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() => _controller.close();
}
