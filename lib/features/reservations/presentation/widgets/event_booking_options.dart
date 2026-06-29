import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/booking_repository.dart';
import '../../domain/entities/booking.dart';

class EventBookingOptions extends StatelessWidget {
  const EventBookingOptions({required this.eventId, super.key});
  final int eventId;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<EventBookingOption>>(
    future: getIt<BookingRepository>().getEventOptions(eventId).then(
      (result) => result.when(
        success: (value) => value,
        failure: (error) => throw error,
      ),
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return Text(UserErrorMessage.from(snapshot.error!));
      final options = snapshot.data ?? const [];
      if (options.isEmpty) {
        return const Text('No hay opciones disponibles para este evento.');
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map(_BookingOptionCard.new).toList(),
      );
    },
  );
}

class _BookingOptionCard extends StatelessWidget {
  const _BookingOptionCard(this.option);

  final EventBookingOption option;

  @override
  Widget build(BuildContext context) {
    final period = [
      if (option.startsAt != null) 'Desde ${_date(option.startsAt)}',
      if (option.endsAt != null) 'Hasta ${_date(option.endsAt)}',
    ].join(' - ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    option.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('${option.price} ${option.currency}'),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _pill(option.type),
                _pill('Capacidad ${option.capacity}'),
                _pill('${option.availableQuantity} disponibles'),
                if (option.isActive) _pill('Activa'),
              ],
            ),
            if (period.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(period, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) => Chip(
    label: Text(text),
    visualDensity: VisualDensity.compact,
  );

  String _date(DateTime? value) =>
      value == null ? '' : value.toLocal().toString().substring(0, 16);
}
