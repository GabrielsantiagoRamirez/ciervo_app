import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/move_driver.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_trip.dart';
import '../../domain/repositories/move_repository.dart';
import '../cubit/move_driver_cubit.dart';
import '../cubit/move_driver_state.dart';
import '../utils/move_labels.dart';
import 'move_driver_documents.dart';
import 'move_driver_onboarding_page.dart';
import 'move_driver_vehicle_form.dart';

class MoveDriverPage extends StatelessWidget {
  const MoveDriverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MoveDriverCubit(getIt<MoveRepository>(), getIt<LocationService>())
            ..load(),
      child: const _MoveDriverView(),
    );
  }
}

class _MoveDriverView extends StatelessWidget {
  const _MoveDriverView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo conductor')),
      body: BlocConsumer<MoveDriverCubit, MoveDriverState>(
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
          if (state.status == MoveDriverStatusView.loading ||
              state.status == MoveDriverStatusView.initial) {
            return const CiervoLoadingState();
          }
          if (state.status == MoveDriverStatusView.failure && !state.hasProfile) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CiervoErrorState(
                title: 'No pudimos cargar tu perfil de conductor',
                description: state.errorMessage ?? 'Intenta nuevamente.',
                onRetry: () => context.read<MoveDriverCubit>().load(),
              ),
            );
          }
          final profile = state.profile;
          if (profile == null) {
            return _ApplyPrompt(cubit: context.read<MoveDriverCubit>());
          }
          return RefreshIndicator(
            onRefresh: () => context.read<MoveDriverCubit>().load(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _DriverHeader(profile: profile),
                if ((profile.rejectionReason ?? '').isNotEmpty &&
                    profile.status == MoveDriverStatus.rejected) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RejectionCard(reason: profile.rejectionReason!),
                ],
                if (profile.isApproved) ...[
                  const SizedBox(height: AppSpacing.md),
                  _OnlineToggle(state: state),
                ],
                if (profile.isApproved && state.activeTrip != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ActiveTripCard(trip: state.activeTrip!, busy: state.actionInProgress),
                ],
                if (profile.isApproved &&
                    state.isOnline &&
                    state.activeTrip == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _AvailableTripsSection(state: state),
                ],
                const SizedBox(height: AppSpacing.lg),
                _VehiclesSection(profile: profile),
                const SizedBox(height: AppSpacing.lg),
                _DocumentsSection(profile: profile),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ApplyPrompt extends StatelessWidget {
  const _ApplyPrompt({required this.cubit});

  final MoveDriverCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          showGradientOverlay: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.drive_eta,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Genera ingresos con Ciervo Move',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Regístrate como conductor, sube tu vehículo y documentos, y '
                'empieza a recibir viajes cuando estés aprobado.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CiervoButton(
          label: 'Quiero ser conductor',
          icon: Icons.how_to_reg_outlined,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MoveDriverOnboardingPage(cubit: cubit),
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({required this.profile});

  final MoveDriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final color = MoveLabels.driverStatusColor(profile.status);
    return CiervoCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(Icons.badge_outlined, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName ?? 'Conductor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  MoveLabels.driverStatus(profile.status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (profile.rating != null || profile.totalTrips != null)
                  Text(
                    [
                      if (profile.rating != null)
                        '⭐ ${profile.rating!.toStringAsFixed(1)}',
                      if (profile.totalTrips != null)
                        '${profile.totalTrips} viajes',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectionCard extends StatelessWidget {
  const _RejectionCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Solicitud rechazada: $reason'),
          ),
        ],
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.state});

  final MoveDriverState state;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: Row(
        children: [
          Icon(
            state.isOnline ? Icons.wifi_tethering : Icons.wifi_tethering_off,
            color: state.isOnline
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isOnline ? 'En línea' : 'Fuera de línea',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  state.isOnline
                      ? 'Recibiendo viajes cercanos.'
                      : 'Actívate para recibir viajes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (state.actionInProgress)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: state.isOnline,
              onChanged: (value) =>
                  context.read<MoveDriverCubit>().toggleOnline(value),
            ),
        ],
      ),
    );
  }
}

class _AvailableTripsSection extends StatelessWidget {
  const _AvailableTripsSection({required this.state});

  final MoveDriverState state;

  @override
  Widget build(BuildContext context) {
    final trips = state.availableTrips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Viajes disponibles (${trips.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<MoveDriverCubit>().refreshAvailable(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (trips.isEmpty)
          const CiervoEmptyState(
            title: 'Sin viajes por ahora',
            description: 'Mantente en línea; los viajes cercanos aparecerán aquí.',
            icon: Icons.map_outlined,
          )
        else
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AvailableTripTile(trip: trip, busy: state.actionInProgress),
            ),
          ),
      ],
    );
  }
}

class _AvailableTripTile extends StatelessWidget {
  const _AvailableTripTile({required this.trip, required this.busy});

  final MoveTrip trip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final currency = trip.currency ?? 'COP';
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                MoveLabels.vehicleCategoryIcon(trip.vehicleCategory),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  MoveLabels.vehicleCategory(trip.vehicleCategory),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (trip.suggestedFare != null)
                Text(
                  DisplayFormatters.formatMoney(
                    trip.suggestedFare,
                    currency: currency,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _line(context, Icons.my_location, trip.originAddress ?? 'Origen'),
          _line(context, Icons.place_outlined, trip.destAddress ?? 'Destino'),
          if (trip.distanceKm != null)
            Text(
              '${trip.distanceKm!.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.sm),
          CiervoButton(
            label: 'Ofertar',
            icon: Icons.local_offer_outlined,
            variant: CiervoButtonVariant.secondary,
            onPressed: busy ? () {} : () => _offer(context),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Future<void> _offer(BuildContext context) async {
    final cubit = context.read<MoveDriverCubit>();
    final vehicles = cubit.state.profile?.vehicles
            .where((v) => v.isActive)
            .toList() ??
        const [];
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas un vehículo activo para ofertar.'),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OfferSheet(trip: trip, cubit: cubit, vehicles: vehicles),
    );
  }
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({
    required this.trip,
    required this.cubit,
    required this.vehicles,
  });

  final MoveTrip trip;
  final MoveDriverCubit cubit;
  final List<MoveVehicle> vehicles;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  late final TextEditingController _amountController;
  final _etaController = TextEditingController(text: '5');
  final _messageController = TextEditingController();
  late String _vehicleId = widget.vehicles.first.id;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.trip.suggestedFare ?? widget.trip.minOffer ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _etaController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.trip.currency ?? 'COP';
    final min = widget.trip.minOffer;
    final max = widget.trip.maxOffer;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enviar oferta', style: Theme.of(context).textTheme.titleLarge),
          if (min != null && max != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Rango: ${DisplayFormatters.formatMoney(min, currency: currency)} — '
              '${DisplayFormatters.formatMoney(max, currency: currency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _vehicleId,
            decoration: const InputDecoration(labelText: 'Vehículo'),
            items: widget.vehicles
                .map(
                  (v) => DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.displayName} · ${v.plate ?? ''}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _vehicleId = value ?? _vehicleId),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Tu tarifa ($currency)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _etaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutos para llegar',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Mensaje (opcional)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: 'Enviar oferta',
            icon: Icons.send_outlined,
            onPressed: () async {
              final amount = int.tryParse(_amountController.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa una tarifa válida.')),
                );
                return;
              }
              final ok = await widget.cubit.submitOffer(
                tripId: widget.trip.id,
                amount: amount,
                vehicleId: _vehicleId,
                etaMinutes: int.tryParse(_etaController.text.trim()),
                message: _messageController.text.trim().isEmpty
                    ? null
                    : _messageController.text.trim(),
              );
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip, required this.busy});

  final MoveTrip trip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MoveDriverCubit>();
    return CiervoCard(
      showGradientOverlay: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Viaje activo · ${MoveLabels.tripStatus(trip.status)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _line(context, Icons.my_location, trip.originAddress ?? 'Origen'),
          _line(context, Icons.place_outlined, trip.destAddress ?? 'Destino'),
          if (trip.agreedFare != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tarifa: ${DisplayFormatters.formatMoney(trip.agreedFare, currency: trip.currency ?? 'COP')}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ..._actions(context, cubit),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  List<Widget> _actions(BuildContext context, MoveDriverCubit cubit) {
    if (trip.status == MoveTripStatus.completed) {
      return [
        CiervoButton(
          label: 'Calificar al pasajero',
          icon: Icons.star_outline,
          onPressed: () => _rate(context, cubit),
        ),
      ];
    }
    final primary = switch (trip.status) {
      MoveTripStatus.driverAssigned => (
        'Voy en camino',
        Icons.directions_car,
        cubit.arriving,
      ),
      MoveTripStatus.driverArriving => (
        'Llegué al punto',
        Icons.location_on,
        cubit.arrived,
      ),
      MoveTripStatus.driverArrived => (
        'Iniciar viaje',
        Icons.play_arrow,
        cubit.startTrip,
      ),
      MoveTripStatus.inProgress => (
        'Finalizar viaje',
        Icons.flag,
        cubit.finishTrip,
      ),
      _ => null,
    };
    return [
      if (primary != null)
        CiervoButton(
          label: primary.$1,
          icon: primary.$2,
          state: busy ? CiervoButtonState.loading : CiervoButtonState.normal,
          onPressed: () => primary.$3(),
        ),
      const SizedBox(height: AppSpacing.sm),
      CiervoButton(
        label: 'Cancelar viaje',
        icon: Icons.close,
        variant: CiervoButtonVariant.danger,
        onPressed: () => _cancel(context, cubit),
      ),
    ];
  }

  Future<void> _cancel(BuildContext context, MoveDriverCubit cubit) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Motivo'),
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
                  ? 'Cancelado por el conductor'
                  : controller.text.trim(),
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (reason != null) await cubit.cancelActiveTrip(reason);
  }

  Future<void> _rate(BuildContext context, MoveDriverCubit cubit) async {
    var rating = 5;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Calificar al pasajero'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => rating = value),
                    icon: Icon(
                      value <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Comentario'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Omitir'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await cubit.rateActiveTrip(
        rating,
        controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
    }
  }
}

class _VehiclesSection extends StatelessWidget {
  const _VehiclesSection({required this.profile});

  final MoveDriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MoveDriverCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mis vehículos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => showMoveVehicleForm(context, cubit),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (profile.vehicles.isEmpty)
          const CiervoEmptyState(
            title: 'Sin vehículos',
            description: 'Registra un vehículo para poder recibir viajes.',
            icon: Icons.directions_car_outlined,
          )
        else
          ...profile.vehicles.map(
            (vehicle) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CiervoCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    MoveLabels.vehicleCategoryIcon(vehicle.category),
                  ),
                  title: Text(vehicle.displayName),
                  subtitle: Text(
                    '${MoveLabels.vehicleCategory(vehicle.category)} · '
                    '${vehicle.plate ?? 'Sin placa'}',
                  ),
                  trailing: _StatusChip(
                    label: vehicle.status ?? 'Pendiente',
                    active: vehicle.isActive,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.profile});

  final MoveDriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MoveDriverCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Documentos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => showMoveDocumentForm(context, cubit),
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (profile.documents.isEmpty)
          const CiervoEmptyState(
            title: 'Sin documentos',
            description: 'Sube tus documentos para ser aprobado.',
            icon: Icons.description_outlined,
          )
        else
          ...profile.documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CiervoCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(doc.documentType),
                  subtitle: Text(doc.documentNumber ?? 'Enviado'),
                  trailing: _StatusChip(
                    label: doc.status ?? 'Pendiente',
                    active: doc.isApproved,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.amber;
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
    );
  }
}
