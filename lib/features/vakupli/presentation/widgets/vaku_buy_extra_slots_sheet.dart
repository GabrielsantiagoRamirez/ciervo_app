import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../data/vakupli_repository.dart';
import '../../domain/entities/vakupli_plan.dart';

Future<VakupliExtraSlotsPurchase?> showVakuBuyExtraSlotsSheet(
  BuildContext context, {
  required VakupliPlan plan,
}) {
  return showModalBottomSheet<VakupliExtraSlotsPurchase>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VakuBuyExtraSlotsSheet(plan: plan),
  );
}

class _VakuBuyExtraSlotsSheet extends StatefulWidget {
  const _VakuBuyExtraSlotsSheet({required this.plan});

  final VakupliPlan plan;

  @override
  State<_VakuBuyExtraSlotsSheet> createState() =>
      _VakuBuyExtraSlotsSheetState();
}

class _VakuBuyExtraSlotsSheetState extends State<_VakuBuyExtraSlotsSheet> {
  final _repository = getIt<VakupliRepository>();
  int _packs = 1;
  bool _submitting = false;
  String? _idempotencyKey;

  VakupliPlan get _plan => widget.plan;

  int get _guestsPerPack =>
      _plan.extraSlotPackSize > 0 ? _plan.extraSlotPackSize : 4;

  double get _unitPrice => _plan.nextPackPriceUsd ??
      (((_plan.planCode ?? 'free').toLowerCase() == 'free') ? 2 : 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalUsd = _unitPrice * _packs;
    final guests = _guestsPerPack * _packs;
    final priceLabel = totalUsd == totalUsd.roundToDouble()
        ? totalUsd.toStringAsFixed(0)
        : totalUsd.toStringAsFixed(2);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Más cupos Vaku', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cada pack suma +$_guestsPerPack invitados por 2 meses '
            '(cobro bimensual desde tu wallet).',
            style: theme.textTheme.bodyMedium,
          ),
          if (_plan.nextPackPriceLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _plan.nextPackPriceLabel,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('Packs'),
              const Spacer(),
              IconButton(
                onPressed: _submitting || _packs <= 1
                    ? null
                    : () => setState(() => _packs -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_packs', style: theme.textTheme.titleMedium),
              IconButton(
                onPressed: _submitting || _packs >= 20
                    ? null
                    : () => setState(() => _packs += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Text(
            '+$guests invitados · US\$$priceLabel',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          CiervoButton(
            label: _submitting ? 'Comprando...' : 'Comprar con wallet',
            icon: Icons.shopping_bag_outlined,
            onPressed: _submitting ? null : _purchase,
          ),
        ],
      ),
    );
  }

  Future<void> _purchase() async {
    final groupId = _plan.id;
    if (groupId == null) return;
    setState(() {
      _submitting = true;
      _idempotencyKey ??= IdempotencyKey.generate();
    });
    final result = await _repository.purchaseExtraSlots(
      groupId: groupId,
      packs: _packs,
      idempotencyKey: _idempotencyKey!,
    );
    if (!mounted) return;
    result.when(
      success: (purchase) {
        Navigator.of(context).pop(purchase);
      },
      failure: (error) {
        setState(() {
          _submitting = false;
          _idempotencyKey = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }
}
