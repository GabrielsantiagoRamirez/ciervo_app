import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/display_formatters.dart';
import '../../features/delivery/domain/entities/delivery_models.dart';

class CommercePurchaseReceipt {
  const CommercePurchaseReceipt({
    required this.orderId,
    required this.businessName,
    required this.fulfillmentLabel,
    required this.totalAmount,
    required this.currency,
    this.pickupPin,
    this.items = const [],
    this.notes,
  });

  final String orderId;
  final String businessName;
  final String fulfillmentLabel;
  final double totalAmount;
  final String currency;
  final String? pickupPin;
  final List<String> items;
  final String? notes;

  factory CommercePurchaseReceipt.fromOrder(
    DeliveryOrder order, {
    required String fulfillmentLabel,
  }) {
    return CommercePurchaseReceipt(
      orderId: order.id,
      businessName: order.businessName,
      fulfillmentLabel: fulfillmentLabel,
      totalAmount: order.totalAmount?.toDouble() ?? 0,
      currency: order.currency ?? 'COP',
      pickupPin: order.effectivePickupCode ?? order.reference,
      items: order.items
          .map((item) => '${item.quantity}x ${item.productName}')
          .toList(),
      notes: order.isPickup ? fulfillmentLabel : order.deliveryAddress,
    );
  }
}

Future<T?> runCommercePurchaseWithSplash<T>({
  required BuildContext context,
  required Future<T> Function() purchase,
  required CommercePurchaseReceipt Function(T result) buildReceipt,
}) async {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    pageBuilder: (dialogContext, _, _) {
      return _CommercePurchaseSplashDialog<T>(
        purchase: purchase,
        buildReceipt: buildReceipt,
      );
    },
  );
}

class _CommercePurchaseSplashDialog<T> extends StatefulWidget {
  const _CommercePurchaseSplashDialog({
    required this.purchase,
    required this.buildReceipt,
  });

  final Future<T> Function() purchase;
  final CommercePurchaseReceipt Function(T result) buildReceipt;

  @override
  State<_CommercePurchaseSplashDialog<T>> createState() =>
      _CommercePurchaseSplashDialogState<T>();
}

class _CommercePurchaseSplashDialogState<T>
    extends State<_CommercePurchaseSplashDialog<T>>
    with SingleTickerProviderStateMixin {
  bool _processing = true;
  T? _result;
  CommercePurchaseReceipt? _receipt;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _run();
  }

  Future<void> _run() async {
    try {
      final result = await widget.purchase();
      if (!mounted) return;
      setState(() {
        _processing = false;
        _result = result;
        _receipt = widget.buildReceipt(result);
      });
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _processing
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                          CurvedAnimation(
                            parent: _pulse,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 72,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Procesando tu compra...',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const LinearProgressIndicator(),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '¡Gracias por tu compra!',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        receipt!.businessName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(receipt.fulfillmentLabel),
                      Text(
                        DisplayFormatters.formatMoney(
                          receipt.totalAmount,
                          currency: receipt.currency,
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (receipt.pickupPin != null &&
                          receipt.pickupPin!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text('PIN recogida: ${receipt.pickupPin}'),
                      ],
                      if (receipt.items.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tu pedido',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        ...receipt.items.map(Text.new),
                      ],
                      if (receipt.notes != null &&
                          receipt.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text('Notas: ${receipt.notes}'),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(_result),
                        child: const Text('Listo'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> showCommerceFulfillmentSheet({
  required BuildContext context,
  required bool deliveryAvailable,
  String? deliveryMessage,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Cómo quieres recibir tu pedido?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (deliveryAvailable) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('Domicilio'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ] else if (deliveryMessage != null) ...[
                Text(deliveryMessage),
                const SizedBox(height: AppSpacing.sm),
              ],
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Recoger en el establecimiento'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
