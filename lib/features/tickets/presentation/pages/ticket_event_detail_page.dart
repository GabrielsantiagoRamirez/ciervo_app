// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/models/ticket_models.dart';
import '../../domain/repositories/tickets_repository.dart';

class TicketEventDetailPage extends StatefulWidget {
  const TicketEventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  State<TicketEventDetailPage> createState() => _TicketEventDetailPageState();
}

class _TicketEventDetailPageState extends State<TicketEventDetailPage> {
  late Future<TicketEventDetail> _future;
  TicketType? _selectedType;
  int _quantity = 1;
  bool _checkingSeats = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TicketEventDetail> _load() async {
    final result = await getIt<TicketsRepository>().eventDetail(widget.eventId);
    return result.when(
      success: (value) => value,
      failure: (error) => throw error,
    );
  }

  void _ensureSelection(TicketEventDetail detail) {
    if (_selectedType != null) return;
    if (detail.ticketTypes.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedType != null) return;
      setState(() => _selectedType = detail.ticketTypes.first);
    });
  }

  Future<void> _continue(TicketEventDetail detail) async {
    final encodedId = Uri.encodeComponent(detail.id);
    setState(() => _checkingSeats = true);
    final seatsResult = await getIt<TicketsRepository>().seats(detail.id);
    if (!mounted) return;
    setState(() => _checkingSeats = false);

    final seats = seatsResult.when(
      success: (value) => value,
      failure: (_) => const <TicketSeat>[],
    );

    if (seats.isNotEmpty || detail.hasSeatingPlan) {
      final query = <String, String>{
        'qty': '$_quantity',
        if (_selectedType != null) 'typeId': _selectedType!.id,
      };
      await context.push(
        Uri(
          path: '/tickets/$encodedId/seats',
          queryParameters: query,
        ).toString(),
      );
      return;
    }

    await context.push(
      Uri(
        path: '/tickets/$encodedId/checkout',
        queryParameters: {
          'qty': '$_quantity',
          if (_selectedType != null) 'typeId': _selectedType!.id,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Evento')),
      body: FutureBuilder<TicketEventDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CiervoLoadingState(itemCount: 4);
          }
          if (snapshot.hasError) {
            return CiervoErrorState(
              title: 'No pudimos cargar el evento',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final detail = snapshot.data!;
          _ensureSelection(detail);
          final price = _selectedType?.price ?? detail.minPrice;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                detail.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  detail.category.label,
                  if (detail.city != null) detail.city!,
                  if (detail.venue != null) detail.venue!,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (detail.startsAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DisplayFormatters.formatDate(
                    detail.startsAt!,
                    includeTime: true,
                  ),
                ),
              ],
              if (detail.description?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.md),
                Text(detail.description!),
              ],
              if (detail.ticketTypes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tipo de entrada',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...detail.ticketTypes.map(
                  (type) => RadioListTile<String>(
                    value: type.id,
                    groupValue: _selectedType?.id,
                    title: Text(type.name),
                    subtitle: Text(
                      DisplayFormatters.formatMoney(
                        type.price,
                        currency: type.currency,
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedType = detail.ticketTypes.firstWhere(
                          (item) => item.id == value,
                        );
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cantidad',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _quantity <= 1
                        ? null
                        : () => setState(() => _quantity--),
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_quantity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _quantity >= 10
                        ? null
                        : () => setState(() => _quantity++),
                    icon: const Icon(Icons.add),
                  ),
                  const Spacer(),
                  if (price != null)
                    Text(
                      DisplayFormatters.formatMoney(
                        price * _quantity,
                        currency: detail.currency,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              CiervoButton(
                label: _checkingSeats ? 'Preparando…' : 'Continuar',
                icon: Icons.confirmation_number_outlined,
                onPressed: _checkingSeats ? null : () => _continue(detail),
              ),
            ],
          );
        },
      ),
    );
  }
}
