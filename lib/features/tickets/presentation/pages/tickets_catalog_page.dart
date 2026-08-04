// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/models/ticket_models.dart';
import '../../domain/repositories/tickets_repository.dart';

class TicketsCatalogPage extends StatefulWidget {
  const TicketsCatalogPage({super.key});

  @override
  State<TicketsCatalogPage> createState() => _TicketsCatalogPageState();
}

class _TicketsCatalogPageState extends State<TicketsCatalogPage> {
  TicketEventCategory? _category;
  late Future<_CatalogData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CatalogData> _load() async {
    final repo = getIt<TicketsRepository>();
    double? lat;
    double? lng;
    try {
      final location = await getIt<LocationService>().currentLocation();
      lat = location.latitude;
      lng = location.longitude;
    } catch (_) {}

    final pageResult = await repo.events(
      category: _category?.apiValue,
      page: 1,
      pageSize: 40,
      latitude: lat,
      longitude: lng,
    );
    final highlightsResult = await repo.highlights();
    final nearbyResult = lat != null && lng != null
        ? await repo.nearby(lat: lat, lng: lng)
        : null;
    final recommendResult = await repo.recommend(lat: lat, lng: lng);

    final errors = <String>[];
    final page = pageResult.when(
      success: (value) => value,
      failure: (error) {
        errors.add(UserErrorMessage.from(error));
        return const TicketEventsPage(page: 1, pageSize: 40, total: 0, items: []);
      },
    );
    final highlights = highlightsResult.when(
      success: (value) => value,
      failure: (_) => const <TicketEventSummary>[],
    );
    final nearby = nearbyResult?.when(
          success: (value) => value,
          failure: (_) => const <TicketEventSummary>[],
        ) ??
        const <TicketEventSummary>[];
    final recommended = recommendResult.when(
      success: (value) => value,
      failure: (_) => const <TicketEventSummary>[],
    );

    if (errors.isNotEmpty &&
        page.items.isEmpty &&
        highlights.isEmpty &&
        nearby.isEmpty) {
      throw Exception(errors.first);
    }

    return _CatalogData(
      events: page.items,
      highlights: highlights,
      nearby: nearby,
      recommended: recommended,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            tooltip: 'Mis entradas',
            onPressed: () => context.push('/tickets/wallet'),
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: _category == null,
                    onSelected: (_) {
                      setState(() {
                        _category = null;
                        _future = _load();
                      });
                    },
                  ),
                ),
                for (final category in TicketEventCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) {
                        setState(() {
                          _category = category;
                          _future = _load();
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<_CatalogData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CiervoLoadingState(itemCount: 5);
                }
                if (snapshot.hasError) {
                  return CiervoErrorState(
                    title: 'No pudimos cargar eventos',
                    description: UserErrorMessage.from(snapshot.error!),
                    onRetry: _reload,
                  );
                }
                final data = snapshot.data!;
                if (data.isEmpty) {
                  return CiervoEmptyState(
                    title: 'Sin eventos por ahora',
                    description:
                        'Prueba otra categoría o vuelve más tarde. Disponible en día, noche y 24h.',
                    icon: Icons.confirmation_number_outlined,
                    actionLabel: 'Reintentar',
                    onAction: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (data.highlights.isNotEmpty) ...[
                        Text(
                          'Destacados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: data.highlights.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) => SizedBox(
                              width: 240,
                              height: 200,
                              child: _EventCard(
                                event: data.highlights[index],
                                compact: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (data.nearby.isNotEmpty) ...[
                        Text(
                          'Cerca de ti',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...data.nearby.map((e) => _EventCard(event: e)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (data.recommended.isNotEmpty) ...[
                        Text(
                          'Para ti',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...data.recommended.map((e) => _EventCard(event: e)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Text(
                        _category == null
                            ? 'Todos los eventos'
                            : _category!.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...data.events.map((e) => _EventCard(event: e)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogData {
  const _CatalogData({
    required this.events,
    required this.highlights,
    required this.nearby,
    required this.recommended,
  });

  final List<TicketEventSummary> events;
  final List<TicketEventSummary> highlights;
  final List<TicketEventSummary> nearby;
  final List<TicketEventSummary> recommended;

  bool get isEmpty =>
      events.isEmpty &&
      highlights.isEmpty &&
      nearby.isEmpty &&
      recommended.isEmpty;
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.compact = false});

  final TicketEventSummary event;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = event.minPrice == null
        ? null
        : DisplayFormatters.formatMoney(
            event.minPrice!,
            currency: event.currency ?? 'COP',
          );
    final subtitle = [
      event.category.label,
      if (event.city?.isNotEmpty == true) event.city,
      if (event.venue?.isNotEmpty == true) event.venue,
    ].join(' · ');

    return SizedBox(
      height: compact ? double.infinity : null,
      child: Card(
      margin: EdgeInsets.only(bottom: compact ? 0 : AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/tickets/${Uri.encodeComponent(event.id)}'),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        event.category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'desde $price',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 6 : AppSpacing.sm),
              Text(
                event.title,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 15 : null,
                  height: 1.2,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (event.startsAt != null) ...[
                if (compact) const Spacer() else const SizedBox(height: 4),
                Text(
                  DisplayFormatters.formatDate(
                    event.startsAt!,
                    includeTime: true,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}
