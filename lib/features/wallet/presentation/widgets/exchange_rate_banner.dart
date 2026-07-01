import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../exchange/data/exchange_rate_repository.dart';
import '../../../../shared/widgets/ciervo_card.dart';

/// Muestra tasas COP→CLP/USD desde el API (sin hardcode).
class ExchangeRateBanner extends StatefulWidget {
  const ExchangeRateBanner({super.key});

  @override
  State<ExchangeRateBanner> createState() => _ExchangeRateBannerState();
}

class _ExchangeRateBannerState extends State<ExchangeRateBanner> {
  String? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = getIt<ExchangeRateRepository>();
    final copToClp = await repo.convert(amount: 100000, from: 'COP', to: 'CLP');
    final copToUsd = await repo.convert(amount: 100000, from: 'COP', to: 'USD');
    if (!mounted) return;
    final parts = <String>[];
    copToClp.when(
      success: (c) => parts.add(
        '100.000 COP ≈ ${c.convertedAmount.toStringAsFixed(0)} CLP',
      ),
      failure: (_) {},
    );
    copToUsd.when(
      success: (c) => parts.add(
        '≈ ${c.convertedAmount.toStringAsFixed(2)} USD',
      ),
      failure: (_) {},
    );
    setState(() {
      _loading = false;
      _summary = parts.isEmpty ? null : parts.join(' · ');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_summary == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CiervoCard(
        child: Row(
          children: [
            Icon(
              Icons.currency_exchange,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _summary!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
