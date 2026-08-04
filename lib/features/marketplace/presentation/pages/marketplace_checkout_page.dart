import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/marketplace_models.dart';
import '../../domain/repositories/marketplace_repository.dart';

class MarketplaceCheckoutPage extends StatefulWidget {
  const MarketplaceCheckoutPage({
    required this.promotionId,
    this.initialQuantity = 1,
    this.initialPaymentMethod = 'CIERVO',
    super.key,
  });

  final int promotionId;
  final int initialQuantity;
  final String initialPaymentMethod;

  @override
  State<MarketplaceCheckoutPage> createState() =>
      _MarketplaceCheckoutPageState();
}

class _MarketplaceCheckoutPageState extends State<MarketplaceCheckoutPage> {
  final _repo = getIt<MarketplaceRepository>();
  MarketplacePromo? _promo;
  MarketplaceBenefits? _benefits;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  late int _quantity;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity.clamp(1, 100);
    _paymentMethod = widget.initialPaymentMethod;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final promoResult = await _repo.promotion(widget.promotionId);
    promoResult.when(
      success: (promo) {
        _promo = promo;
      },
      failure: (error) => _error = UserErrorMessage.from(error),
    );
    if (_promo != null) {
      await _refreshBenefits();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshBenefits() async {
    final result = await _repo.calculateBenefits(
      promotionId: widget.promotionId,
      quantity: _quantity,
      paymentMethod: _paymentMethod,
    );
    result.when(
      success: (benefits) {
        if (mounted) setState(() => _benefits = benefits);
      },
      failure: (_) {},
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await _repo.checkout(
      promotionId: widget.promotionId,
      quantity: _quantity,
      paymentMethod: _paymentMethod,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (order) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido #${order.id} · ${order.status}')),
        );
        context.go('/marketplace/orders');
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CiervoLoadingState(itemCount: 3)),
      );
    }
    if (_error != null || _promo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: CiervoErrorState(
          title: 'No pudimos preparar el pago',
          description: _error ?? 'Intenta de nuevo.',
          onRetry: _load,
        ),
      );
    }

    final promo = _promo!;
    final benefits = _benefits;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(promo.title, style: AppTextStyles.title),
          Text(promo.businessName, style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          Text('Método de pago', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final method in const ['CIERVO', 'CONTACT', 'PENDING'])
                ChoiceChip(
                  label: Text(method),
                  selected: _paymentMethod == method,
                  onSelected: (_) async {
                    setState(() => _paymentMethod = method);
                    await _refreshBenefits();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('Cantidad'),
              const Spacer(),
              IconButton(
                onPressed: _quantity <= 1
                    ? null
                    : () async {
                        setState(() => _quantity--);
                        await _refreshBenefits();
                      },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_quantity', style: AppTextStyles.title),
              IconButton(
                onPressed: () async {
                  setState(() => _quantity++);
                  await _refreshBenefits();
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (benefits != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _Row(
                    'Subtotal',
                    DisplayFormatters.formatMoney(
                      benefits.subtotal,
                      currency: benefits.currency,
                    ),
                  ),
                  _Row(
                    'Descuento',
                    DisplayFormatters.formatMoney(
                      benefits.discount,
                      currency: benefits.currency,
                    ),
                  ),
                  _Row(
                    'Cashback',
                    DisplayFormatters.formatMoney(
                      benefits.cashback,
                      currency: benefits.currency,
                    ),
                  ),
                  _Row('Puntos', '${benefits.totalPoints}'),
                  const Divider(),
                  _Row(
                    'Total',
                    DisplayFormatters.formatMoney(
                      benefits.totalPay,
                      currency: benefits.currency,
                    ),
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          CiervoButton(
            label: _submitting ? 'Procesando…' : 'Confirmar compra',
            icon: Icons.lock_outline,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize ? AppTextStyles.label : AppTextStyles.bodyMuted,
            ),
          ),
          Text(
            value,
            style: emphasize
                ? AppTextStyles.label.copyWith(color: AppColors.primary)
                : AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
