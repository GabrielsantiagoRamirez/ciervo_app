import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/ciervo_empty_state.dart';
import '../data/staff_orders_repository.dart';
import '../domain/staff_order.dart';
import '../../staff_scanner/domain/entities/staff_scanner_models.dart';
import 'staff_order_detail_page.dart';

class StaffOrdersPage extends StatefulWidget {
  const StaffOrdersPage({required this.permissions, super.key});

  final StaffPermissions permissions;

  @override
  State<StaffOrdersPage> createState() => _StaffOrdersPageState();
}

class _StaffOrdersPageState extends State<StaffOrdersPage> {
  static const _statuses = [
    'pending',
    'accepted',
    'preparing',
    'ready_for_pickup',
    'assigned',
    'picked_up',
    'delivered',
    'cancelled',
    'rejected',
  ];

  String _status = 'pending';
  late Future<List<StaffOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _orders = getIt<StaffOrdersRepository>().orders(
      businessId: widget.permissions.businessId!,
      status: _status,
    ).then(
      (result) => result.when(
        success: (value) => value,
        failure: (error) => throw error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pedidos')),
    body: Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: _statuses.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final status = _statuses[index];
              return ChoiceChip(
                label: Text(staffOrderStatusLabel(status)),
                selected: _status == status,
                onSelected: (_) => setState(() {
                  _status = status;
                  _reload();
                }),
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: FutureBuilder<List<StaffOrder>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(UserErrorMessage.from(snapshot.error!)),
                      ),
                    ],
                  );
                }
                final orders = snapshot.data ?? const [];
                if (orders.isEmpty) {
                  return ListView(
                    children: [
                      CiervoEmptyState(
                        title: 'Sin pedidos',
                        description: 'No hay pedidos en este estado.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        title: Text(order.reference.isEmpty
                            ? 'Pedido #${order.id}'
                            : order.reference),
                        subtitle: Text([
                          order.customerName,
                          order.deliveryAddress,
                          staffOrderStatusLabel(order.status),
                        ].where((item) => item.isNotEmpty).join('\n')),
                        trailing: Text('\$${order.total}'),
                        onTap: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => StaffOrderDetailPage(
                                businessId: widget.permissions.businessId!,
                                orderId: order.id,
                                canManage: widget.permissions.canManageOrders,
                              ),
                            ),
                          );
                          if (mounted) setState(_reload);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
