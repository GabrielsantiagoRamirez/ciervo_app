import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../widgets/delivery_pricing_card.dart';
import 'delivery_order_detail_page.dart';

class AvailableDeliveryOrdersPage extends StatefulWidget {
  const AvailableDeliveryOrdersPage({super.key});

  @override
  State<AvailableDeliveryOrdersPage> createState() =>
      _AvailableDeliveryOrdersPageState();
}

class _AvailableDeliveryOrdersPageState
    extends State<AvailableDeliveryOrdersPage> {
  List<AvailableDeliveryOrder> _orders = const [];
  DeliveryProfile? _profile;
  bool _loading = true;
  String? _claimingId;
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
    final repository = getIt<DeliveryRepository>();
    final profileResult = await repository.me();
    final result = await repository.availableOrders();
    if (!mounted) return;
    profileResult.when(
      success: (profile) => _profile = profile,
      failure: (_) => _profile = null,
    );
    result.when(
      success: (orders) => setState(() {
        _orders = orders;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Domicilios disponibles')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _orders.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      CiervoEmptyState(
                        title: 'Sin domicilios disponibles',
                        description:
                            _error ?? 'Los pedidos aprobados apareceran aqui.',
                        icon: Icons.delivery_dining_outlined,
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _orders.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final canClaim =
                          _profile?.isSettlementAccountVerified == true;
                      return CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.businessName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Recogida: ${order.businessAddress}'),
                            Text('Entrega: ${order.deliveryAddress}'),
                            const SizedBox(height: AppSpacing.sm),
                            DeliveryPricingCard(
                              pricing: order.effectivePricing,
                              currency: order.currency ?? 'COP',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (!canClaim)
                              const Padding(
                                padding: EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  'Necesitas una cuenta de liquidacion aprobada para aceptar domicilios.',
                                ),
                              ),
                            CiervoButton(
                              label: 'Aceptar domicilio',
                              icon: Icons.check,
                              state: _claimingId == order.id
                                  ? CiervoButtonState.loading
                                  : CiervoButtonState.normal,
                              onPressed: canClaim && _claimingId == null
                                  ? () => _claim(order)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
  );

  Future<void> _claim(AvailableDeliveryOrder order) async {
    if (_profile?.isSettlementAccountVerified != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu cuenta de liquidacion debe estar aprobada para reclamar domicilios.',
          ),
        ),
      );
      return;
    }
    setState(() => _claimingId = order.id);
    final result = await getIt<DeliveryRepository>().claimOrder(order.id);
    if (!mounted) return;
    setState(() => _claimingId = null);
    result.when(
      success: (claimed) async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DeliveryOrderDetailPage(orderId: claimed.id),
          ),
        );
        _load();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
        _load();
      },
    );
  }
}
