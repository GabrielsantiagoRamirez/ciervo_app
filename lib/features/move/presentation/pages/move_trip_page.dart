import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/move_driver_location.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_offer.dart';
import '../../domain/entities/move_trip.dart';
import '../../domain/repositories/move_repository.dart';
import '../cubit/move_passenger_cubit.dart';
import '../cubit/move_passenger_state.dart';
import '../utils/move_labels.dart';

class MoveTripPage extends StatelessWidget {
  const MoveTripPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MovePassengerCubit(getIt<MoveRepository>())..startTracking(tripId),
      child: const _MoveTripView(),
    );
  }
}

class _MoveTripView extends StatelessWidget {
  const _MoveTripView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu viaje')),
      body: BlocConsumer<MovePassengerCubit, MovePassengerState>(
        listener: (context, state) {
          final error = state.errorMessage;
          final success = state.successMessage;
          if (error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          } else if (success != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(success)));
          }
        },
        builder: (context, state) {
          final trip = state.trip;
          if (trip == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _StatusHeader(trip: trip),
              const SizedBox(height: AppSpacing.md),
              _TripMap(trip: trip, driverLocation: state.driverLocation),
              const SizedBox(height: AppSpacing.md),
              _RouteCard(trip: trip),
              const SizedBox(height: AppSpacing.md),
              ..._buildStageContent(context, state, trip),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildStageContent(
    BuildContext context,
    MovePassengerState state,
    MoveTrip trip,
  ) {
    if (trip.status == MoveTripStatus.searching ||
        trip.status == MoveTripStatus.offered) {
      return [
        _OffersSection(
          offers: state.offers,
          trip: trip,
          busy: state.actionInProgress,
        ),
        const SizedBox(height: AppSpacing.md),
        CiervoButton(
          label: 'Cancelar búsqueda',
          icon: Icons.close,
          variant: CiervoButtonVariant.danger,
          onPressed: () => _confirmCancel(context),
        ),
      ];
    }
    if (trip.status.isActive) {
      return [
        _DriverCard(trip: trip),
        const SizedBox(height: AppSpacing.md),
        if (trip.canCancel)
          CiervoButton(
            label: 'Cancelar viaje',
            icon: Icons.close,
            variant: CiervoButtonVariant.danger,
            onPressed: () => _confirmCancel(context),
          ),
      ];
    }
    if (trip.status == MoveTripStatus.completed) {
      return [_RateSection(busy: state.actionInProgress)];
    }
    return [
      CiervoCard(
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(MoveLabels.tripStatus(trip.status))),
          ],
        ),
      ),
    ];
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<MovePassengerCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Cancelar viaje'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Motivo (opcional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                controller.text.trim().isEmpty
                    ? 'Cancelado por el pasajero'
                    : controller.text.trim(),
              ),
              child: const Text('Cancelar viaje'),
            ),
          ],
        );
      },
    );
    if (reason != null) {
      await cubit.cancelTrip(reason);
    }
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.trip});

  final MoveTrip trip;

  @override
  Widget build(BuildContext context) {
    final color = MoveLabels.tripStatusColor(trip.status);
    return CiervoCard(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MoveLabels.tripStatus(trip.status),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${MoveLabels.paymentStatus(trip.paymentStatus)} · '
                  '${MoveLabels.paymentMethod(trip.paymentMethod)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if ((trip.publicCode ?? '').isNotEmpty)
            Text(
              '#${trip.publicCode}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
    );
  }
}

class _TripMap extends StatelessWidget {
  const _TripMap({required this.trip, this.driverLocation});

  final MoveTrip trip;
  final MoveDriverLocation? driverLocation;

  @override
  Widget build(BuildContext context) {
    if (!trip.hasOrigin && !trip.hasDestination) {
      return const SizedBox.shrink();
    }
    final markers = <Marker>{
      if (trip.hasOrigin)
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(trip.originLat!, trip.originLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Origen'),
        ),
      if (trip.hasDestination)
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(trip.destLat!, trip.destLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Destino'),
        ),
      if (driverLocation case final loc? when loc.hasCoordinates)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(loc.latitude, loc.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'Conductor'),
        ),
    };
    final target = trip.hasOrigin
        ? LatLng(trip.originLat!, trip.originLng!)
        : LatLng(trip.destLat!, trip.destLng!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 13),
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.trip});

  final MoveTrip trip;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _routeLine(
            context,
            Icons.my_location,
            'Origen',
            trip.originAddress ?? 'Origen',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Divider(height: 1),
          ),
          _routeLine(
            context,
            Icons.place_outlined,
            'Destino',
            trip.destAddress ?? 'Destino',
          ),
          if (trip.agreedFare != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tarifa acordada: '
              '${DisplayFormatters.formatMoney(trip.agreedFare, currency: trip.currency ?? 'COP')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _routeLine(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _OffersSection extends StatelessWidget {
  const _OffersSection({
    required this.offers,
    required this.trip,
    required this.busy,
  });

  final List<MoveOffer> offers;
  final MoveTrip trip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return CiervoCard(
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Buscando conductores cercanos. Las ofertas aparecerán aquí.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ofertas (${offers.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...offers.map(
          (offer) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OfferTile(offer: offer, trip: trip, busy: busy),
          ),
        ),
      ],
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.trip,
    required this.busy,
  });

  final MoveOffer offer;
  final MoveTrip trip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final currency = offer.currency ?? trip.currency ?? 'COP';
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person_outline)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.driverName ?? 'Conductor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        if (offer.driverRating != null)
                          '⭐ ${offer.driverRating!.toStringAsFixed(1)}',
                        if (offer.etaMinutes != null)
                          'Llega en ${offer.etaMinutes} min',
                        if ((offer.vehicleLabel ?? '').isNotEmpty)
                          offer.vehicleLabel!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                DisplayFormatters.formatMoney(offer.amount, currency: currency),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          if ((offer.message ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              offer.message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _counter(context, currency),
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Contraofertar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () =>
                            context.read<MovePassengerCubit>().acceptOffer(
                              offer.id,
                            ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _counter(BuildContext context, String currency) async {
    final cubit = context.read<MovePassengerCubit>();
    final min = trip.minOffer;
    final max = trip.maxOffer;
    final controller = TextEditingController(text: offer.amount.toString());
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contraoferta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (min != null && max != null)
              Text(
                'Rango permitido: '
                '${DisplayFormatters.formatMoney(min, currency: currency)} — '
                '${DisplayFormatters.formatMoney(max, currency: currency)}',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tu oferta'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      await cubit.counterOffer(offer.id, amount);
    }
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.trip});

  final MoveTrip trip;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                child: Icon(Icons.person),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driverName ?? 'Tu conductor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        if (trip.driverRating != null)
                          '⭐ ${trip.driverRating!.toStringAsFixed(1)}',
                        if ((trip.vehicleLabel ?? '').isNotEmpty)
                          trip.vehicleLabel!,
                        if ((trip.vehiclePlate ?? '').isNotEmpty)
                          trip.vehiclePlate!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (trip.etaMinutes != null)
                      Text(
                        'Llega en ${trip.etaMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((trip.driverPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${trip.driverPhone}')),
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Llamar al conductor'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RateSection extends StatefulWidget {
  const _RateSection({required this.busy});

  final bool busy;

  @override
  State<_RateSection> createState() => _RateSectionState();
}

class _RateSectionState extends State<_RateSection> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return CiervoCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Gracias por calificar tu viaje.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Califica tu viaje',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Comentario (opcional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          CiervoButton(
            label: 'Enviar calificación',
            icon: Icons.send_outlined,
            state: widget.busy
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: () async {
              await context.read<MovePassengerCubit>().rateTrip(
                _rating,
                _commentController.text.trim().isEmpty
                    ? null
                    : _commentController.text.trim(),
              );
              if (mounted) setState(() => _submitted = true);
            },
          ),
        ],
      ),
    );
  }
}
