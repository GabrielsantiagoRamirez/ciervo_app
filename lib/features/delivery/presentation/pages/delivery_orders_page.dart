import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'delivery_order_detail_page.dart';

class DeliveryOrdersPage extends StatefulWidget {
  const DeliveryOrdersPage({super.key});
  @override
  State<DeliveryOrdersPage> createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends State<DeliveryOrdersPage> {
  List<DeliveryOrder> _orders = const [];
  bool _loading = true;
  String? _error;
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
    final result = await getIt<DeliveryRepository>().orders();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _orders = items;
        _loading = false;
      }),
      failure: (e) => setState(() {
        _error = UserErrorMessage.from(e);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis pedidos de entregas')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _orders.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (_error != null) Text(_error!),
                      const CiervoEmptyState(
                        title: 'Sin pedidos asignados',
                        description: 'Los pedidos disponibles apareceran aqui.',
                        icon: Icons.local_shipping_outlined,
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: _orders.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.delivery_dining),
                        ),
                        title: Text('#${order.id} · ${order.businessName}'),
                        subtitle: Text(
                          '${order.businessAddress}\n${order.deliveryAddress}\n${deliveryStatusLabel(order.status)}',
                        ),
                        isThreeLine: true,
                        trailing: order.unreadCount > 0
                            ? Badge(label: Text('${order.unreadCount}'))
                            : const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DeliveryOrderDetailPage(orderId: order.id),
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
