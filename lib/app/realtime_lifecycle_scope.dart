import 'dart:async';

import 'package:flutter/widgets.dart';

typedef RealtimeLifecycleCallback = FutureOr<void> Function();

/// Pausa conexiones realtime fuera de primer plano y las revalida al volver.
class RealtimeLifecycleScope extends StatefulWidget {
  const RealtimeLifecycleScope({
    required this.child,
    required this.onResume,
    required this.onPause,
    super.key,
  });

  final Widget child;
  final RealtimeLifecycleCallback onResume;
  final RealtimeLifecycleCallback onPause;

  @override
  State<RealtimeLifecycleScope> createState() => _RealtimeLifecycleScopeState();
}

class _RealtimeLifecycleScopeState extends State<RealtimeLifecycleScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(Future<void>.sync(widget.onResume));
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(Future<void>.sync(widget.onPause));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
