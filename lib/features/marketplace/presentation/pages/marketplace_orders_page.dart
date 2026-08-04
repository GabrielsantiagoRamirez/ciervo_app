import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/marketplace_models.dart';
import '../../domain/repositories/marketplace_repository.dart';

class MarketplaceOrdersPage extends StatefulWidget {
  const MarketplaceOrdersPage({super.key});

  @override
  State<MarketplaceOrdersPage> createState() => _MarketplaceOrdersPageState();
}

class _MarketplaceOrdersPageState extends State<MarketplaceOrdersPage> {
  final _repo = getIt<MarketplaceRepository>();
  List<MarketplaceOrder> _orders = const [];
  String? _error;
  bool _loading = true;

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
    final result = await _repo.orders();
    result.when(
      success: (orders) => _orders = orders,
      failure: (error) => _error = UserErrorMessage.from(error),
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cancel(MarketplaceOrder order) async {
    final result = await _repo.cancelOrder(order.id);
    if (!mounted) return;
    result.when(
      success: (_) => _load(),
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: _loading
          ? const Center(child: CiervoLoadingState(itemCount: 4))
          : _error != null
          ? CiervoErrorState(
              title: 'No pudimos cargar pedidos',
              description: _error!,
              onRetry: _load,
            )
          : _orders.isEmpty
          ? CiervoEmptyState(
              title: 'Sin pedidos',
              description: 'Cuando compres en el marketplace aparecerán aquí.',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'Ir al marketplace',
              onAction: () => context.go('/'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _orders.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    color: AppColors.surfaceHigh,
                    child: ListTile(
                      title: Text(order.promotionTitle),
                      subtitle: Text(
                        '${order.businessName}\n'
                        '${order.status} · '
                        '${DisplayFormatters.formatMoney(order.total, currency: order.currency)}',
                        style: AppTextStyles.bodyMuted,
                      ),
                      isThreeLine: true,
                      trailing: order.status == 'pending' ||
                              order.status == 'pending_payment'
                          ? TextButton(
                              onPressed: () => _cancel(order),
                              child: const Text('Cancelar'),
                            )
                          : Text('#${order.id}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
