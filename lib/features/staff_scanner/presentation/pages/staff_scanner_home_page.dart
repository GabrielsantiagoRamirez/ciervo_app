// ignore_for_file: prefer_null_aware_operators

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../staff_orders/presentation/staff_orders_page.dart';
import '../../data/staff_scanner_repository.dart';
import '../../domain/entities/staff_scanner_models.dart';
import 'staff_qr_scanner_page.dart';

class StaffScannerHomePage extends StatefulWidget {
  const StaffScannerHomePage({required this.permissions, super.key});

  final StaffPermissions permissions;

  @override
  State<StaffScannerHomePage> createState() => _StaffScannerHomePageState();
}

class _StaffScannerHomePageState extends State<StaffScannerHomePage> {
  late Future<List<StaffQrScanAudit>> _history;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _history = getIt<StaffScannerRepository>().history().then(
      (result) => result.when(
        success: (value) => value,
        failure: (error) => throw error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.permissions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo personal'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () => getIt<AuthRepository>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_reload),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CiervoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permissions.businessName ?? 'Negocio asignado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(permissions.staffName ?? 'Personal autorizado'),
                  if ((permissions.roleName ?? '').isNotEmpty)
                    Text('Rol: ${permissions.roleName}'),
                  const SizedBox(height: AppSpacing.lg),
                  CiervoButton(
                    label: 'Escanear QR',
                    icon: Icons.qr_code_scanner,
                    onPressed: _openScanner,
                  ),
                  if (permissions.canViewOrders &&
                      permissions.businessId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Pedidos',
                      icon: Icons.receipt_long_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: _openOrders,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ultimos escaneos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<StaffQrScanAudit>>(
              future: _history,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(UserErrorMessage.from(snapshot.error!));
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const CiervoEmptyState(
                    title: 'Sin escaneos recientes',
                    description: 'Cada validacion o redencion aparecera aqui.',
                    icon: Icons.history,
                  );
                }
                return Column(
                  children: items.map(_AuditTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openScanner() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StaffQrScannerPage(permissions: widget.permissions),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StaffOrdersPage(permissions: widget.permissions),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile(this.audit);

  final StaffQrScanAudit audit;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(_icon(audit.result)),
      title: Text(audit.resourceTitle ?? audit.qrType ?? 'QR escaneado'),
      subtitle: Text([
        audit.ownerName,
        audit.failureReason,
        _date(audit.scannedAt),
      ].whereType<String>().where((item) => item.isNotEmpty).join(' - ')),
      trailing: Text(_resultLabel(audit.result)),
    ),
  );

  IconData _icon(String result) {
    final text = result.toLowerCase();
    if (text.contains('success') || text.contains('valid')) {
      return Icons.check_circle_outline;
    }
    if (text.contains('expired')) return Icons.warning_amber_outlined;
    return Icons.cancel_outlined;
  }

  String? _date(DateTime? value) =>
      value == null ? null : value.toLocal().toString().substring(0, 16);

  String _resultLabel(String value) {
    final text = value.toLowerCase();
    if (text.contains('success') || text.contains('valid')) return 'Valido';
    if (text.contains('expired')) return 'Vencido';
    if (text.contains('used') || text.contains('redeemed')) return 'Usado';
    return value;
  }
}
