import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/delivery_pricing.dart';

class DeliveryPricingCard extends StatelessWidget {
  const DeliveryPricingCard({
    required this.pricing,
    required this.currency,
    this.pickupPin,
    this.deliveryPin,
    super.key,
  });

  final DeliveryPricing pricing;
  final String currency;
  final String? pickupPin;
  final String? deliveryPin;

  @override
  Widget build(BuildContext context) {
    final moneyCurrency = pricing.currency ?? currency;
    final rows = <(String, String)>[];
    void add(String label, num? value, {int decimals = 0}) {
      if (value == null) return;
      rows.add((
        label,
        '$moneyCurrency ${value.toStringAsFixed(decimals)}',
      ));
    }

    if (pricing.distanceKm != null) {
      rows.add(('Distancia', '${pricing.distanceKm!.toStringAsFixed(1)} km'));
    }
    add('Tarifa domicilio', pricing.deliveryFee);
    add('Tarifa base', pricing.deliveryFeeBase ?? pricing.baseFee);
    add('Comision CIERVO', pricing.platformFee);
    add('Tu ganancia', pricing.courierEarning);
    add('Propina', pricing.tipAmount);
    add('Total domiciliario', pricing.courierTotal);
    if (pricing.includedKm != null) {
      rows.add(('Km incluidos', '${pricing.includedKm!.toStringAsFixed(1)} km'));
    }
    if (pricing.extraKm != null && pricing.extraKm! > 0) {
      rows.add(('Km adicionales', '${pricing.extraKm!.toStringAsFixed(1)} km'));
    }
    add('Precio km adicional', pricing.additionalKmPrice);

    if (rows.isEmpty && pickupPin == null && deliveryPin == null) {
      return const SizedBox.shrink();
    }

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose de entrega',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text(
                    row.$2,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
          if (pickupPin != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('PIN recogida: $pickupPin'),
          ],
          if (deliveryPin != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('PIN entrega: $deliveryPin'),
          ],
        ],
      ),
    );
  }
}
