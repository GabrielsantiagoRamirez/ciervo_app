import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/move_fare_quote.dart';

/// Tarjeta con la tarifa sugerida y el rango negociable.
class MoveFareQuoteCard extends StatelessWidget {
  const MoveFareQuoteCard({required this.quote, super.key});

  final MoveFareQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = quote.currency;
    return CiervoCard(
      showGradientOverlay: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tarifa sugerida', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            DisplayFormatters.formatMoney(
              quote.suggestedFare,
              currency: currency,
            ),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Rango negociable: '
            '${DisplayFormatters.formatMoney(quote.minOffer, currency: currency)}'
            ' — '
            '${DisplayFormatters.formatMoney(quote.maxOffer, currency: currency)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (quote.breakdown.isNotEmpty) ...[
            const Divider(height: AppSpacing.lg),
            ...quote.breakdown.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DisplayFormatters.formatMoney(
                        item.amount,
                        currency: currency,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
