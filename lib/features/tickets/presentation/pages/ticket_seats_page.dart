import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/models/ticket_models.dart';
import '../../domain/repositories/tickets_repository.dart';

class TicketSeatsPage extends StatefulWidget {
  const TicketSeatsPage({
    required this.eventId,
    required this.quantity,
    this.ticketTypeId,
    super.key,
  });

  final String eventId;
  final int quantity;
  final String? ticketTypeId;

  @override
  State<TicketSeatsPage> createState() => _TicketSeatsPageState();
}

class _TicketSeatsPageState extends State<TicketSeatsPage> {
  late Future<List<TicketSeat>> _future;
  final Set<String> _selected = {};
  String? _holdId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    final holdId = _holdId;
    if (holdId != null && holdId.isNotEmpty) {
      getIt<TicketsRepository>().releaseSeats(widget.eventId, holdId);
    }
    super.dispose();
  }

  Future<List<TicketSeat>> _load() async {
    final result = await getIt<TicketsRepository>().seats(widget.eventId);
    return result.when(
      success: (value) => value,
      failure: (error) => throw error,
    );
  }

  Future<void> _reserveAndContinue() async {
    if (_selected.length != widget.quantity) {
      setState(
        () => _error =
            'Selecciona exactamente ${widget.quantity} asiento(s).',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await getIt<TicketsRepository>().reserveSeats(
      widget.eventId,
      _selected.toList(),
    );
    if (!mounted) return;
    await result.when(
      success: (hold) async {
        _holdId = hold.holdId;
        setState(() => _busy = false);
        final encodedId = Uri.encodeComponent(widget.eventId);
        final heldId = hold.holdId;
        // Evita release automático al salir hacia checkout: transferimos hold.
        _holdId = null;
        await context.push(
          Uri(
            path: '/tickets/$encodedId/checkout',
            queryParameters: {
              'qty': '${widget.quantity}',
              if (widget.ticketTypeId != null) 'typeId': widget.ticketTypeId!,
              if (heldId.isNotEmpty) 'holdId': heldId,
              'seats': _selected.join(','),
            },
          ).toString(),
        );
        // Si vuelve sin pagar, intenta liberar.
        if (heldId.isNotEmpty && mounted) {
          await getIt<TicketsRepository>().releaseSeats(
            widget.eventId,
            heldId,
          );
        }
      },
      failure: (error) async {
        setState(() {
          _busy = false;
          _error = UserErrorMessage.from(error);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir asientos')),
      body: FutureBuilder<List<TicketSeat>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CiervoLoadingState(itemCount: 4);
          }
          if (snapshot.hasError) {
            return CiervoErrorState(
              title: 'No pudimos cargar asientos',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final seats = snapshot.data ?? const <TicketSeat>[];
          if (seats.isEmpty) {
            return CiervoEmptyState(
              title: 'Sin plano de asientos',
              description:
                  'Este evento no tiene asientos numerados. Continúa al pago.',
              icon: Icons.event_seat_outlined,
              actionLabel: 'Ir al checkout',
              onAction: () {
                final encodedId = Uri.encodeComponent(widget.eventId);
                context.push(
                  Uri(
                    path: '/tickets/$encodedId/checkout',
                    queryParameters: {
                      'qty': '${widget.quantity}',
                      if (widget.ticketTypeId != null)
                        'typeId': widget.ticketTypeId!,
                    },
                  ).toString(),
                );
              },
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Selecciona ${widget.quantity} asiento(s). '
                  'Elegidos: ${_selected.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: seats.length,
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    final selected = _selected.contains(seat.id);
                    final enabled = seat.available || selected;
                    return InkWell(
                      onTap: !enabled || _busy
                          ? null
                          : () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(seat.id);
                                } else if (_selected.length < widget.quantity) {
                                  _selected.add(seat.id);
                                }
                              });
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: !seat.available
                              ? scheme.surfaceContainerHighest
                              : selected
                              ? scheme.primary
                              : scheme.surfaceContainerHigh,
                          border: Border.all(
                            color: selected
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          seat.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: selected
                                ? scheme.onPrimary
                                : seat.available
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    _error!,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CiervoButton(
                  label: _busy ? 'Reservando…' : 'Continuar',
                  onPressed: _busy ? null : _reserveAndContinue,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
