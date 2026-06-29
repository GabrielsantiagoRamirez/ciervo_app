import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/ciervo_button.dart';
import '../data/staff_orders_repository.dart';
import '../domain/staff_order.dart';

class StaffOrderDetailPage extends StatefulWidget {
  const StaffOrderDetailPage({
    required this.businessId,
    required this.orderId,
    required this.canManage,
    super.key,
  });

  final int businessId;
  final String orderId;
  final bool canManage;

  @override
  State<StaffOrderDetailPage> createState() => _StaffOrderDetailPageState();
}

class _StaffOrderDetailPageState extends State<StaffOrderDetailPage> {
  StaffOrder? _order;
  String? _error;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await getIt<StaffOrdersRepository>().order(
      businessId: widget.businessId,
      orderId: widget.orderId,
    );
    if (!mounted) return;
    result.when(
      success: (order) => setState(() {
        _order = order;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${widget.orderId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : order == null
                  ? const Center(child: Text('Pedido no encontrado.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          Text(
                            order.reference.isEmpty
                                ? 'Pedido #${order.id}'
                                : order.reference,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _line('Estado', staffOrderStatusLabel(order.status)),
                          _line('Cliente', order.customerName),
                          _line('Telefono', order.customerPhone),
                          _line('Direccion', order.deliveryAddress),
                          _line('Total', '\$${order.total}'),
                          if (order.notes != null) _line('Notas', order.notes!),
                          if (order.deliveryPersonName != null)
                            _line('Domiciliario', order.deliveryPersonName!),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Items', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.sm),
                          ...order.items.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.productName),
                              subtitle: Text(
                                '${item.quantity} x \$${item.unitPrice}',
                              ),
                              trailing: Text('\$${item.totalPrice}'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (widget.canManage)
                            ..._actionsFor(order.status).map(
                              (action) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: CiervoButton(
                                  label: action.label,
                                  icon: action.icon,
                                  state: _acting
                                      ? CiervoButtonState.loading
                                      : CiervoButtonState.normal,
                                  variant: action.status == 'rejected'
                                      ? CiervoButtonVariant.secondary
                                      : CiervoButtonVariant.primary,
                                  onPressed: _acting
                                      ? null
                                      : () => _updateStatus(action.status),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _line(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text('$label: $value'),
    );
  }

  List<_StatusAction> _actionsFor(String status) => switch (status) {
    'pending' => const [
        _StatusAction('accepted', 'Aceptar', Icons.check_circle_outline),
        _StatusAction('rejected', 'Rechazar', Icons.cancel_outlined),
      ],
    'accepted' => const [
        _StatusAction('preparing', 'Marcar en preparacion', Icons.soup_kitchen_outlined),
      ],
    'preparing' => const [
        _StatusAction('ready_for_pickup', 'Marcar listo', Icons.inventory_2_outlined),
      ],
    'ready_for_pickup' => const [
        _StatusAction('picked_up', 'Confirmar recogida', Icons.delivery_dining),
      ],
    'picked_up' => const [
        _StatusAction('delivered', 'Marcar entregado', Icons.done_all),
      ],
    _ => const [],
  };

  Future<void> _updateStatus(String status) async {
    setState(() => _acting = true);
    final result = await getIt<StaffOrdersRepository>().updateStatus(
      businessId: widget.businessId,
      orderId: widget.orderId,
      status: status,
      notes: 'Actualizado desde app movil staff',
    );
    if (!mounted) return;
    setState(() => _acting = false);
    result.when(
      success: (order) => setState(() => _order = order),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

class _StatusAction {
  const _StatusAction(this.status, this.label, this.icon);

  final String status;
  final String label;
  final IconData icon;
}
