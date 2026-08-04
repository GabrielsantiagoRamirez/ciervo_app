// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/models/ticket_models.dart';
import '../../domain/repositories/tickets_repository.dart';

class TicketCheckoutPage extends StatefulWidget {
  const TicketCheckoutPage({
    required this.eventId,
    required this.quantity,
    this.ticketTypeId,
    this.holdId,
    this.seatIds = const [],
    super.key,
  });

  final String eventId;
  final int quantity;
  final String? ticketTypeId;
  final String? holdId;
  final List<String> seatIds;

  @override
  State<TicketCheckoutPage> createState() => _TicketCheckoutPageState();
}

class _TicketCheckoutPageState extends State<TicketCheckoutPage> {
  late Future<TicketEventDetail> _future;
  TicketPaymentMethod _method = TicketPaymentMethod.ciervoBalance;
  bool _busy = false;
  String? _error;

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

  Future<void> _pay(TicketEventDetail detail) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = getIt<TicketsRepository>();
    final createResult = await repo.createTicket(
      CreateTicketCommand(
        eventId: detail.id,
        tickets: widget.quantity,
        seatIds: widget.seatIds,
        holdId: widget.holdId,
        ticketTypeId: widget.ticketTypeId,
        idempotencyKey: IdempotencyKey.generate(),
      ),
    );
    if (!mounted) return;
    await createResult.when(
      success: (order) async {
        final payResult = await repo.payTicket(
          PayTicketCommand(
            ticketId: order.ticketId,
            paymentMethod: _method,
            idempotencyKey: IdempotencyKey.generate(),
          ),
        );
        if (!mounted) return;
        await payResult.when(
          success: (paid) async {
            setState(() => _busy = false);
            if (!mounted) return;
            context.go('/tickets/wallet/${Uri.encodeComponent(paid.ticketId)}');
          },
          failure: (error) async {
            setState(() {
              _busy = false;
              _error = UserErrorMessage.from(error);
            });
          },
        );
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
      appBar: AppBar(title: const Text('Pagar entradas')),
      body: FutureBuilder<TicketEventDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CiervoLoadingState(itemCount: 3);
          }
          if (snapshot.hasError) {
            return CiervoErrorState(
              title: 'No pudimos preparar el pago',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                detail.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Cantidad: ${widget.quantity}'),
              if (widget.seatIds.isNotEmpty)
                Text('Asientos: ${widget.seatIds.join(', ')}'),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Método de pago',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...TicketPaymentMethod.values.map(
                (method) => RadioListTile<TicketPaymentMethod>(
                  value: method,
                  groupValue: _method,
                  title: Text(method.label),
                  subtitle: method == TicketPaymentMethod.points
                      ? const Text('Solo si tienes puntos suficientes')
                      : null,
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _method = value);
                        },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tarjeta o transferencia bancaria no están disponibles en Tickets.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: AppSpacing.xl),
              CiervoButton(
                label: _busy ? 'Procesando…' : 'Pagar',
                icon: Icons.lock_outline,
                onPressed: _busy ? null : () => _pay(detail),
              ),
            ],
          );
        },
      ),
    );
  }
}
