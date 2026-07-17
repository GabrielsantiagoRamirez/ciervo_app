import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/move_trip.dart';
import '../../domain/repositories/move_repository.dart';
import 'move_trip_page.dart';

/// Pantalla del tutor para aprobar/rechazar viajes solicitados por un menor
/// (CIERVO MOVE Kids). Consume `GET /move/trips/kids/approvals`.
class MoveKidsApprovalsPage extends StatefulWidget {
  const MoveKidsApprovalsPage({super.key});

  @override
  State<MoveKidsApprovalsPage> createState() => _MoveKidsApprovalsPageState();
}

class _MoveKidsApprovalsPageState extends State<MoveKidsApprovalsPage> {
  final _repository = getIt<MoveRepository>();
  late Future<List<MoveTrip>> _future;
  String? _actingTripId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MoveTrip>> _load() async {
    final result = await _repository.kidsApprovals();
    return result.when(
      success: (trips) => trips,
      failure: (error) => throw error,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(MoveTrip trip) async {
    setState(() => _actingTripId = trip.id);
    final result = await _repository.parentApprove(trip.id);
    if (!mounted) return;
    await result.when(
      success: (approved) async {
        _snack('Viaje aprobado. Ya buscamos conductores.');
        await _refresh();
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MoveTripPage(tripId: approved.id),
          ),
        );
      },
      failure: (error) async => _snack(UserErrorMessage.from(error)),
    );
    if (mounted) setState(() => _actingTripId = null);
  }

  Future<void> _reject(MoveTrip trip) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar viaje'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Motivo (opcional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    setState(() => _actingTripId = trip.id);
    final result = await _repository.parentReject(
      trip.id,
      reason: reason.isEmpty ? null : reason,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        _snack('Viaje rechazado.');
        _refresh();
      },
      failure: (error) => _snack(UserErrorMessage.from(error)),
    );
    if (mounted) setState(() => _actingTripId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprobaciones Kids')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MoveTrip>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageView(
                icon: Icons.error_outline,
                message: UserErrorMessage.from(snapshot.error!),
              );
            }
            final trips = snapshot.data ?? const [];
            if (trips.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  _MessageView(
                    icon: Icons.verified_user_outlined,
                    message:
                        'No hay viajes de menores esperando tu aprobación.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: trips.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _ApprovalCard(
                  trip: trip,
                  busy: _actingTripId == trip.id,
                  onApprove: () => _approve(trip),
                  onReject: () => _reject(trip),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.trip,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final MoveTrip trip;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final fare = trip.agreedFare ?? trip.suggestedFare;
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.child_care, color: Colors.deepPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Solicitud de viaje',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (fare != null)
                Text(
                  DisplayFormatters.formatMoney(
                    fare,
                    currency: trip.currency ?? 'COP',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _line(context, Icons.my_location, trip.originAddress ?? 'Origen'),
          const SizedBox(height: AppSpacing.xs),
          _line(context, Icons.place_outlined, trip.destAddress ?? 'Destino'),
          if ((trip.ruleReason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      trip.ruleReason!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CiervoButton(
                  label: 'Aprobar',
                  icon: Icons.check,
                  state: busy
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
