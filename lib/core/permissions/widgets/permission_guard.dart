import 'package:flutter/material.dart';

import '../permission_kind.dart';
import '../permission_manager.dart';
import 'permission_denied_state.dart';

/// Envuelve contenido que requiere un permiso y muestra estado denegado si aplica.
class PermissionGuard extends StatefulWidget {
  const PermissionGuard({
    required this.kind,
    required this.builder,
    this.autoRequest = true,
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
    final granted = request
        ? await PermissionManager.instance.ensure(context, widget.kind)
        : false;
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
