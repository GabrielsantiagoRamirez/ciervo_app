import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'customer_order_detail_page.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  List<DeliveryOrder> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<DeliveryRepository>().customerOrders();
    if (!mounted) return;
    result.when(
      success: (orders) => setState(() {
        _orders = orders;
        _loading = false;
        _error = null;
      }),
      failure: (error) => setState(() {
        _loading = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis pedidos')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _orders.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      CiervoEmptyState(
                        title: 'Sin pedidos',
                        description: _error ?? 'Tus pedidos apareceran aqui.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _orders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return ListTile(
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: Text(order.businessName),
                        subtitle: Text([
                          if ((order.reference ?? '').isNotEmpty) order.reference!,
                          deliveryStatusLabel(order.status),
                        ].join(' - ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CustomerOrderDetailPage(orderId: order.id),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
          ),
  );
}
