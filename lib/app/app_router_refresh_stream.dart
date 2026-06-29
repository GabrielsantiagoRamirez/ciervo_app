import 'dart:async';

import 'package:flutter/foundation.dart';

class AppRouterRefreshStream extends ChangeNotifier {
  AppRouterRefreshStream(Stream<dynamic> stream, {Stream<dynamic>? extraListenable}) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
    _extraSubscription =
        extraListenable?.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;
  StreamSubscription<dynamic>? _extraSubscription;

  @override
  void dispose() {
    _subscription.cancel();
    _extraSubscription?.cancel();
    super.dispose();
  }
}
