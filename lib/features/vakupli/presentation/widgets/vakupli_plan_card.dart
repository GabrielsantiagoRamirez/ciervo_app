import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/vakupli_plan.dart';

class VakupliPlanCard extends StatefulWidget {
  const VakupliPlanCard({required this.plan, super.key});

  final VakupliPlan plan;

  @override
  State<VakupliPlanCard> createState() => _VakupliPlanCardState();
}

class _VakupliPlanCardState extends State<VakupliPlanCard> {
  Timer? _ticker;
  late DateTime? _endsAt;

  VakupliPlan get plan => widget.plan;

  @override
  void initState() {
    super.initState();
    _syncEndsAt();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant VakupliPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.expiresAt != plan.expiresAt ||
        oldWidget.plan.remainingSeconds != plan.remainingSeconds ||
        oldWidget.plan.createdAt != plan.createdAt) {
      _syncEndsAt();
    }
  }

  void _syncEndsAt() {
    // Prefer expiresAt del API; si no, anclar remainingSeconds al momento local.
    if (plan.expiresAt != null) {
      _endsAt = plan.expiresAt!.toUtc();
      return;
    }
    if (plan.remainingSeconds != null) {
      _endsAt = DateTime.now().toUtc().add(
        Duration(seconds: plan.remainingSeconds!),
      );
      return;
    }
    if (plan.createdAt != null) {
      _endsAt = plan.createdAt!.toUtc().add(const Duration(hours: 24));
      return;
    }
    _endsAt = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _timeLeftLabel {
    if (plan.statusLabel.toLowerCase().contains('complet')) {
      return 'Finalizado';
    }
    final ends = _endsAt;
    if (ends == null) return plan.timeLeftLabel;
    final left = ends.difference(DateTime.now().toUtc());
    final seconds = left.isNegative ? 0 : left.inSeconds;
    if (seconds <= 0) return 'Expirado';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours >= 24) {
      final days = hours ~/ 24;
      final remHours = hours % 24;
      return '${days}d ${remHours}h ${minutes}m';
    }
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final code = plan.code?.trim();

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: AppTextStyles.title.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      plan.statusLabel,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (code != null && code.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.tag, size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text('ID Vaku: $code', style: AppTextStyles.bodyMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  'Tiempo restante: $_timeLeftLabel',
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            DisplayFormatters.formatPrice(plan.totalAmount),
            style: AppTextStyles.display.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text('Total estimado del plan', style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cupos del grupo: ${plan.participantsLabel}',
            style: AppTextStyles.bodyMuted,
          ),
          Text(
            plan.planCapacityHint,
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
          ),
          if (plan.nextPackPriceLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              plan.nextPackPriceLabel,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
            ),
          ],
          if (plan.paymentProgressLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              plan.paymentProgressLabel,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
