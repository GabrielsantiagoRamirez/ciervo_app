import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/bonus.dart';
import '../../domain/repositories/bonuses_repository.dart';
import '../pages/bonus_detail_page.dart';
import '../widgets/bonus_card.dart';

/// UI preparatoria para aplicar bonos disponibles en flujos de pago/wallet.
class WalletAvailableBonusesSection extends StatefulWidget {
  const WalletAvailableBonusesSection({super.key});

  @override
  State<WalletAvailableBonusesSection> createState() =>
      _WalletAvailableBonusesSectionState();
}

class _WalletAvailableBonusesSectionState
    extends State<WalletAvailableBonusesSection> {
  List<Bonus> _items = const [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<BonusesRepository>().myBonuses(pageSize: 5);
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items
            .where(
              (bonus) =>
                  bonus.status.isUsable &&
                  bonus.redeemedAt == null,
            )
            .toList();
        _loading = false;
      }),
      failure: (_) => setState(() => _loading = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonos disponibles para pagar',
          style: AppTextStyles.title.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Selecciona un bono al confirmar tu pago cuando el comercio lo permita.',
          style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._items.map(
          (bonus) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: BonusCard(
              bonus: bonus,
              compact: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BonusDetailPage(bonusId: bonus.id),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
