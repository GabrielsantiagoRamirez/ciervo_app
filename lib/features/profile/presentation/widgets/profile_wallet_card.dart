import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/profile_data.dart';

class ProfileWalletCard extends StatelessWidget {
  const ProfileWalletCard({required this.wallet, super.key});

  final ProfileWallet wallet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upli Wallet', style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '\$${wallet.balance.toStringAsFixed(0)}',
            style: AppTextStyles.headline.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppRadii.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.cardType, style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xs),
                Text(wallet.cardMask, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
