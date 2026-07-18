import 'package:flutter/material.dart';

import '../app_permission_state.dart';
import '../permission_kind.dart';
import '../permission_manager.dart';
import 'permission_denied_state.dart';

/// Envuelve contenido que requiere un permiso y muestra estado denegado si aplica.
class PermissionGuard extends StatefulWidget {
  const PermissionGuard({
    required this.kind,
    required this.builder,
    this.autoRequest = false,
    super.key,
  });

  final AppPermissionKind kind;
  final Widget Function(BuildContext context) builder;
  final bool autoRequest;

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard> {
  bool? _granted;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check(request: widget.autoRequest);
  }

  Future<void> _check({required bool request}) async {
    setState(() => _checking = true);
    final manager = PermissionManager.instance;
    late final bool granted;
    if (request) {
      if (!mounted) return;
      granted = await manager.ensure(context, widget.kind);
    } else {
      granted = (await manager.status(widget.kind)).allowsUse;
    }
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_granted == true) {
      return widget.builder(context);
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PermissionDeniedState(
        kind: widget.kind,
        onRetry: () => _check(request: true),
      ),
    );
  }
}
