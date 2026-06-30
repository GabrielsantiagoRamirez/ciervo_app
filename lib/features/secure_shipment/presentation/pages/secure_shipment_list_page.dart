import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../data/secure_shipment_repository.dart';
import '../../domain/models/secure_shipment.dart';
import '../widgets/shipment_status_chip.dart';
import 'secure_shipment_create_page.dart';
import 'secure_shipment_detail_page.dart';

class SecureShipmentListPage extends StatefulWidget {
  const SecureShipmentListPage({super.key});

  @override
  State<SecureShipmentListPage> createState() => _SecureShipmentListPageState();
}

class _SecureShipmentListPageState extends State<SecureShipmentListPage>
    with SingleTickerProviderStateMixin {
  final _repository = getIt<SecureShipmentRepository>();
  late final TabController _tabs;
  List<SecureShipment> _sent = const [];
  List<SecureShipment> _received = const [];
  SecureShipmentReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final sentResult = await _repository.listShipments(sentOnly: true);
    final receivedResult = await _repository.listShipments(receivedOnly: true);
    final reportResult = await _repository.userReport();
    if (!mounted) return;

    sentResult.when(
      success: (items) => _sent = items,
      failure: (e) => _error = UserErrorMessage.from(e),
    );
    receivedResult.when(
      success: (items) => _received = items,
      failure: (e) => _error ??= UserErrorMessage.from(e),
    );
    reportResult.when(
      success: (r) => _report = r,
      failure: (_) {},
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envíos seguros'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Enviados'),
            Tab(text: 'Recibidos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const SecureShipmentCreatePage()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo envío'),
      ),
      body: _loading
          ? const CiervoLoadingState(itemCount: 4)
          : _error != null && _sent.isEmpty && _received.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                CiervoErrorState(
                  title: 'No pudimos cargar tus envíos',
                  description: _error!,
                  onRetry: _load,
                ),
              ],
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _ShipmentList(
                  items: _sent,
                  report: _report,
                  emptyTitle: 'Aún no has enviado nada',
                  emptyDescription:
                      'Crea un envío seguro para proteger tu venta con PIN dual y fondos en custodia.',
                  onRefresh: _load,
                  onTap: _openDetail,
                ),
                _ShipmentList(
                  items: _received,
                  report: null,
                  emptyTitle: 'Sin envíos recibidos',
                  emptyDescription:
                      'Cuando alguien te envíe un paquete seguro, aparecerá aquí para que lo aceptes.',
                  onRefresh: _load,
                  onTap: _openDetail,
                ),
              ],
            ),
    );
  }

  Future<void> _openDetail(SecureShipment shipment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SecureShipmentDetailPage(publicId: shipment.publicId),
      ),
    );
    _load();
  }
}

class _ShipmentList extends StatelessWidget {
  const _ShipmentList({
    required this.items,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.onRefresh,
    required this.onTap,
    this.report,
  });

  final List<SecureShipment> items;
  final SecureShipmentReport? report;
  final String emptyTitle;
  final String emptyDescription;
  final Future<void> Function() onRefresh;
  final void Function(SecureShipment) onTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (report != null) _ReportCard(report: report!),
                CiervoEmptyState(
                  title: emptyTitle,
                  description: emptyDescription,
                  icon: Icons.local_shipping_outlined,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length + (report != null ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (report != null && index == 0) {
                  return _ReportCard(report: report!);
                }
                final item = items[index - (report != null ? 1 : 0)];
                return _ShipmentCard(shipment: item, onTap: () => onTap(item));
              },
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final SecureShipmentReport report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CiervoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu resumen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('${report.totalCount} envíos · ${report.completedCount} completados'),
            Text(
              'Volumen: ${report.currency} ${report.totalVolume.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment, required this.onTap});

  final SecureShipment shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shipment.publicId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ShipmentStatusChip(statusName: shipment.statusName),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(shipment.counterpartyLabel),
              Text(
                '${shipment.currency} ${shipment.totalAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (shipment.hasActiveDispute)
                const Text(
                  'Disputa activa — fondos congelados',
                  style: TextStyle(color: Color(0xFFC62828)),
                )
              else if (shipment.hasActiveHold)
                const Text('Fondos en custodia'),
            ],
          ),
        ),
      ),
    );
  }
}
