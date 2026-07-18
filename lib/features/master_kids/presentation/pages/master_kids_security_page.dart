import 'package:flutter/material.dart';

import '../../data/repositories/master_kids_repository.dart';
import '../../domain/models/master_kids_models.dart';

typedef AuditExportHandler = Future<void> Function(AuditExport export);

class MasterKidsSecurityPage extends StatefulWidget {
  const MasterKidsSecurityPage({
    required this.repository,
    required this.kidId,
    this.onExport,
    super.key,
  });
  final MasterKidsRepository repository;
  final int kidId;
  final AuditExportHandler? onExport;

  @override
  State<MasterKidsSecurityPage> createState() => _MasterKidsSecurityPageState();
}

class _MasterKidsSecurityPageState extends State<MasterKidsSecurityPage> {
  MasterDashboard? _dashboard;
  List<SecurityAttempt>? _attempts;
  KidAuditPage? _audit;
  String? _error;
  bool _busy = false;
  int _auditPage = 1;
  static const _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final dashboard = await widget.repository.dashboard();
    final attempts = await widget.repository.attempts(widget.kidId);
    final audit = await widget.repository.audit(
      kidId: widget.kidId,
      page: _auditPage,
      pageSize: _pageSize,
    );
    if (!mounted) return;
    dashboard.when(
      success: (value) => _dashboard = value,
      failure: (error) => _error = error.toString(),
    );
    attempts.when(
      success: (value) => _attempts = value,
      failure: (error) => _error ??= error.toString(),
    );
    audit.when(
      success: (value) => _audit = value,
      failure: (error) => _error ??= error.toString(),
    );
    setState(() => _busy = false);
  }

  Future<void> _securityAction(bool block) async {
    if (!await _confirm(
      block ? 'Bloquear operaciones' : 'Desbloquear operaciones',
      block
          ? 'Se bloquearán todas las operaciones del menor. ¿Continuar?'
          : 'Se habilitarán nuevamente las operaciones. ¿Continuar?',
    )) {
      return;
    }
    setState(() => _busy = true);
    final command = KidsSecurityActionCommand(kidId: widget.kidId);
    final result = block
        ? await widget.repository.blockAll(command)
        : await widget.repository.unblockAll(command);
    if (!mounted) return;
    result.when(
      success: (_) => _refresh(),
      failure: (error) => setState(() {
        _busy = false;
        _error = error.toString();
      }),
    );
  }

  Future<void> _resetAttempts() async {
    if (!await _confirm(
      'Restablecer intentos',
      'El contador y registro operativo de intentos se restablecerá. ¿Continuar?',
    )) {
      return;
    }
    setState(() => _busy = true);
    final result = await widget.repository.resetAttempts(widget.kidId);
    if (!mounted) return;
    result.when(
      success: (_) => _refresh(),
      failure: (error) => setState(() {
        _busy = false;
        _error = error.toString();
      }),
    );
  }

  Future<void> _export() async {
    final handler = widget.onExport;
    if (handler == null) return;
    setState(() => _busy = true);
    final result = await widget.repository.exportAudit(kidId: widget.kidId);
    if (!mounted) return;
    await result.when(
      success: handler,
      failure: (error) async => setState(() => _error = error.toString()),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  void _goToAuditPage(int page) {
    if (page < 1 || page == _auditPage) return;
    setState(() => _auditPage = page);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seguridad Kids'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Intentos'),
              Tab(text: 'Auditoría'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              MaterialBanner(
                content: Text(_error!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _DashboardTab(
                    dashboard: _dashboard,
                    onBlock: _busy ? null : () => _securityAction(true),
                    onUnblock: _busy ? null : () => _securityAction(false),
                  ),
                  _AttemptsTab(
                    attempts: _attempts,
                    onReset: _busy ? null : _resetAttempts,
                  ),
                  _AuditTab(
                    audit: _audit,
                    onExport: _busy || widget.onExport == null ? null : _export,
                    onPrevious: _busy || _auditPage <= 1
                        ? null
                        : () => _goToAuditPage(_auditPage - 1),
                    onNext:
                        _busy ||
                            _audit == null ||
                            _auditPage * _pageSize >= _audit!.total
                        ? null
                        : () => _goToAuditPage(_auditPage + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.dashboard,
    required this.onBlock,
    required this.onUnblock,
  });
  final MasterDashboard? dashboard;
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    final value = dashboard;
    if (value == null) return const Center(child: Text('Sin datos'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${value.availableBalance} ${value.currency}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        ListTile(
          title: const Text('Solicitudes pendientes'),
          trailing: Text('${value.pendingRequests}'),
        ),
        ListTile(
          title: const Text('Solicitudes aprobadas'),
          trailing: Text('${value.approvedRequests}'),
        ),
        ListTile(
          title: const Text('Solicitudes rechazadas'),
          trailing: Text('${value.rejectedRequests}'),
        ),
        ListTile(
          title: const Text('Intentos de pago'),
          trailing: Text('${value.paymentAttempts}'),
        ),
        ListTile(
          title: const Text('Intentos restrictivos'),
          trailing: Text('${value.restrictiveAttempts}'),
        ),
        ListTile(
          title: const Text('Cuentas bloqueadas'),
          trailing: Text('${value.blockedAccounts}'),
        ),
        if (value.averageApprovalMinutes != null)
          ListTile(
            title: const Text('Tiempo promedio de aprobación'),
            trailing: Text(
              '${value.averageApprovalMinutes!.toStringAsFixed(1)} min',
            ),
          ),
        _DashboardList(
          title: 'Comercios frecuentes',
          values: value.frequentBusinesses,
        ),
        _DashboardList(
          title: 'Ubicaciones autorizadas',
          values: value.authorizedLocations,
        ),
        _DashboardList(title: 'Alertas', values: value.alerts),
        _DashboardList(
          title: 'Gasto por categoría',
          values: value.spendByCategory,
        ),
        ListTile(
          title: const Text('Actualizado'),
          trailing: Text(value.generatedAt.toLocal().toString()),
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: onBlock,
                child: const Text('Bloquear todo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onUnblock,
                child: const Text('Desbloquear'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardList extends StatelessWidget {
  const _DashboardList({required this.title, required this.values});
  final String title;
  final List<Map<String, dynamic>> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text(title),
      children: [
        for (final value in values)
          ListTile(
            title: Text(
              value['name']?.toString() ??
                  value['label']?.toString() ??
                  value['title']?.toString() ??
                  'Detalle',
            ),
            trailing: Text(
              value['amount']?.toString() ??
                  value['count']?.toString() ??
                  value['value']?.toString() ??
                  '',
            ),
          ),
      ],
    );
  }
}

class _AttemptsTab extends StatelessWidget {
  const _AttemptsTab({required this.attempts, required this.onReset});
  final List<SecurityAttempt>? attempts;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final values = attempts;
    if (values == null) return const Center(child: Text('Sin datos'));
    return ListView(
      children: [
        ListTile(
          title: const Text('Intentos registrados'),
          trailing: TextButton(
            onPressed: onReset,
            child: const Text('Restablecer'),
          ),
        ),
        if (values.isEmpty)
          const ListTile(title: Text('No hay intentos'))
        else
          for (final item in values)
            ListTile(
              leading: Icon(
                item.restrictive ? Icons.gpp_bad : Icons.info_outline,
              ),
              title: Text(item.attemptType),
              subtitle: Text(
                item.reasonCode ?? item.createdAt.toLocal().toString(),
              ),
            ),
      ],
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({
    required this.audit,
    required this.onExport,
    required this.onPrevious,
    required this.onNext,
  });
  final KidAuditPage? audit;
  final VoidCallback? onExport;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final value = audit;
    if (value == null) return const Center(child: Text('Sin datos'));
    return ListView(
      children: [
        ListTile(
          title: Text('${value.total} eventos'),
          trailing: TextButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download),
            label: const Text('CSV'),
          ),
        ),
        if (value.items.isEmpty)
          const ListTile(title: Text('No hay eventos'))
        else
          for (final item in value.items)
            ListTile(
              title: Text(item.action),
              subtitle: Text(
                item.detail ?? item.createdAt.toLocal().toString(),
              ),
              trailing: item.correlationId == null
                  ? null
                  : Tooltip(
                      message: item.correlationId!,
                      child: const Icon(Icons.tag),
                    ),
            ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              'Página ${value.page} de '
              '${(value.total / value.pageSize).ceil().clamp(1, 1 << 20)}',
            ),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
