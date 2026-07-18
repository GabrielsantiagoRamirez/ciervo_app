import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/move_trip.dart';
import '../../domain/repositories/move_repository.dart';
import '../utils/move_labels.dart';
import 'move_trip_page.dart';

class MoveTripsHistoryPage extends StatefulWidget {
  const MoveTripsHistoryPage({super.key});

  @override
  State<MoveTripsHistoryPage> createState() => _MoveTripsHistoryPageState();
}

class _MoveTripsHistoryPageState extends State<MoveTripsHistoryPage> {
  late Future<List<MoveTrip>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MoveTrip>> _load() async {
    final result = await getIt<MoveRepository>().listTrips(pageSize: 30);
    return result.when(success: (trips) => trips, failure: Future.error);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de viajes')),
      body: FutureBuilder<List<MoveTrip>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CiervoLoadingState();
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CiervoErrorState(
                title: 'No pudimos cargar tu historial',
                description: UserErrorMessage.from(snapshot.error!),
                onRetry: _reload,
              ),
            );
          }
          final trips = snapshot.data ?? const [];
          if (trips.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoEmptyState(
                title: 'Sin viajes',
                description: 'Cuando hagas tu primer viaje aparecerá aquí.',
                icon: Icons.local_taxi_outlined,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: trips.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _TripTile(trip: trips[index]),
            ),
          );
        },
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});

  final MoveTrip trip;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MoveLabels.tripStatusColor(
            trip.status,
          ).withValues(alpha: 0.2),
          child: Icon(
            Icons.local_taxi,
            color: MoveLabels.tripStatusColor(trip.status),
          ),
        ),
        title: Text(trip.destAddress ?? 'Viaje ${trip.publicCode ?? trip.id}'),
        subtitle: Text(
          '${MoveLabels.tripStatus(trip.status)} · '
          '${DisplayFormatters.formatBackendDate(trip.createdAt)}',
        ),
        trailing: trip.agreedFare != null
            ? Text(
                DisplayFormatters.formatMoney(
                  trip.agreedFare,
                  currency: trip.currency ?? 'COP',
                ),
                style: Theme.of(context).textTheme.titleSmall,
              )
            : const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MoveTripPage(tripId: trip.id),
          ),
        ),
      ),
    );
  }
}
