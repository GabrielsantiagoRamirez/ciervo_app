import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../domain/entities/vakupli_plan.dart';

class VakupliFriendsGroup extends StatelessWidget {
  const VakupliFriendsGroup({required this.friends, super.key});

  final List<VakupliFriend> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Text(
        'Aún no hay participantes. Invita contactos de tu país.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quién pagó', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ...friends.map((friend) {
          final paid =
              friend.hasPaid ||
              friend.paymentStatus == VakupliPaymentStatus.paid;
          final pending = friend.paymentStatus == VakupliPaymentStatus.pending;
          final statusColor = paid
              ? Colors.green
              : pending
              ? colorScheme.tertiary
              : colorScheme.onSurfaceVariant;
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: paid
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                child: Text(
                  friend.initials,
                  style: AppTextStyles.label.copyWith(
                    color: paid ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
              ),
              title: Text(friend.name),
              subtitle: Text(
                [
                  if (friend.username != null && friend.username!.isNotEmpty)
                    friend.username!.startsWith('@')
                        ? friend.username!
                        : '@${friend.username}',
                  if (friend.amount != null)
                    DisplayFormatters.formatMoney(
                      friend.amount!,
                      currency: friend.currency,
                    ),
                ].join(' · '),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: AppRadii.chip,
                ),
                child: Text(
                  friend.paymentLabel,
                  style: AppTextStyles.label.copyWith(
                    color: statusColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
