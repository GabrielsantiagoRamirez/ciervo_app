import 'package:flutter/material.dart';

import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../payments/presentation/widgets/payment_summary_row.dart';
import '../../domain/entities/payment_quote.dart';
import '../utils/nfc_payment_ui.dart';

/// Resumen estilo Nequi: comisión solo en confirmación, no en ingreso de monto.
class PaymentQuoteSummaryCard extends StatelessWidget {
  const PaymentQuoteSummaryCard({
    required this.quote,
    super.key,
    this.title = 'Resumen del pago',
    this.subtitle,
  });

  final PaymentQuote quote;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primary : theme.colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
        child: CiervoCard(
          showGradientOverlay: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.lg),
              PaymentSummaryRow(
                label: 'Subtotal',
                value: NfcPaymentUi.formatMoney(quote.subtotal, quote.currency),
              ),
              if (quote.feeApplies && quote.fee > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                PaymentSummaryRow(
                  label: quote.feePercentage != null
                      ? 'Comisión (${quote.feePercentage!.toStringAsFixed(0)}%)'
                      : 'Comisión',
                  value: NfcPaymentUi.formatMoney(quote.fee, quote.currency),
                ),
              ],
              if (quote.discount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                PaymentSummaryRow(
                  label: 'Descuento',
                  value:
                      '- ${NfcPaymentUi.formatMoney(quote.discount, quote.currency)}',
                ),
              ],
              if (quote.cashback > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                PaymentSummaryRow(
                  label: 'Cashback estimado',
                  value: NfcPaymentUi.formatMoney(
                    quote.cashback,
                    quote.currency,
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total a pagar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  Text(
                    NfcPaymentUi.formatMoney(quote.total, quote.currency),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
              if (quote.availableBalance != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: quote.sufficientFunds
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: isDark ? 0.25 : 0.45,
                          )
                        : theme.colorScheme.errorContainer.withValues(
                            alpha: isDark ? 0.25 : 0.45,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        quote.sufficientFunds
                            ? Icons.account_balance_wallet_outlined
                            : Icons.warning_amber_outlined,
                        size: 20,
                        color: quote.sufficientFunds
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          quote.sufficientFunds
                              ? 'Saldo disponible: ${NfcPaymentUi.formatMoney(quote.availableBalance!, quote.currency)}'
                              : 'Saldo insuficiente para este pago.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
