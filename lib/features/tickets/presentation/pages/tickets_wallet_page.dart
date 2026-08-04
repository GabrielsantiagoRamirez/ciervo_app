// ignore_for_file: unnecessary_underscores, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/models/ticket_models.dart';
import '../../domain/repositories/tickets_repository.dart';

class TicketsWalletPage extends StatefulWidget {
  const TicketsWalletPage({super.key});

  @override
  State<TicketsWalletPage> createState() => _TicketsWalletPageState();
}

class _TicketsWalletPageState extends State<TicketsWalletPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<_WalletData> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<_WalletData> _load() async {
    final repo = getIt<TicketsRepository>();
    final active = await repo.walletTickets();
    final history = await repo.walletHistory();
    final errors = <String>[];
    final activeItems = active.when(
      success: (value) => value,
      failure: (error) {
        errors.add(UserErrorMessage.from(error));
        return const <WalletTicket>[];
      },
    );
    final historyItems = history.when(
      success: (value) => value,
      failure: (error) {
        errors.add(UserErrorMessage.from(error));
        return const <WalletTicket>[];
      },
    );
    if (errors.isNotEmpty && activeItems.isEmpty && historyItems.isEmpty) {
      throw Exception(errors.first);
    }
    return _WalletData(active: activeItems, history: historyItems);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis entradas'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Historial'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Explorar',
            onPressed: () => context.push('/tickets'),
            icon: const Icon(Icons.explore_outlined),
          ),
        ],
      ),
      body: FutureBuilder<_WalletData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CiervoLoadingState(itemCount: 4);
          }
          if (snapshot.hasError) {
            return CiervoErrorState(
              title: 'No pudimos cargar tus entradas',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          return TabBarView(
            controller: _tabs,
            children: [
              _TicketList(
                items: data.active,
                emptyTitle: 'Sin entradas activas',
                emptyDescription:
                    'Cuando compres cine, conciertos u otros eventos aparecerán aquí.',
                onRefresh: _reload,
              ),
              _TicketList(
                items: data.history,
                emptyTitle: 'Sin historial',
                emptyDescription:
                    'Tus entradas usadas o canceladas saldrán aquí.',
                onRefresh: _reload,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletData {
  const _WalletData({required this.active, required this.history});

  final List<WalletTicket> active;
  final List<WalletTicket> history;
}

class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.items,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.onRefresh,
  });

  final List<WalletTicket> items;
  final String emptyTitle;
  final String emptyDescription;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return CiervoEmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: Icons.confirmation_number_outlined,
        actionLabel: 'Explorar eventos',
        onAction: () => context.push('/tickets'),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final ticket = items[index];
          return Card(
            child: ListTile(
              title: Text(ticket.title),
              subtitle: Text(
                [
                  ticket.ticketId,
                  ticket.status,
                  if (ticket.startsAt != null)
                    DisplayFormatters.formatDate(
                      ticket.startsAt!,
                      includeTime: true,
                    ),
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/tickets/wallet/${Uri.encodeComponent(ticket.ticketId)}',
              ),
            ),
          );
        },
      ),
    );
  }
}

class TicketWalletDetailPage extends StatefulWidget {
  const TicketWalletDetailPage({required this.ticketId, super.key});

  final String ticketId;

  @override
  State<TicketWalletDetailPage> createState() => _TicketWalletDetailPageState();
}

class _TicketWalletDetailPageState extends State<TicketWalletDetailPage> {
  late Future<WalletTicket> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<WalletTicket> _load() async {
    final result = await getIt<TicketsRepository>().walletTicket(
      widget.ticketId,
    );
    return result.when(
      success: (value) => value,
      failure: (error) => throw error,
    );
  }

  Future<void> _cancel(WalletTicket ticket) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar entrada'),
        content: const Text('¿Seguro que quieres cancelar esta entrada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final result = await getIt<TicketsRepository>().cancelTicket(
      ticket.ticketId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entrada cancelada.')));
        setState(() => _future = _load());
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  Future<void> _refund(WalletTicket ticket) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar reembolso'),
        content: const Text('¿Quieres solicitar el reembolso de esta entrada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, reembolsar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final result = await getIt<TicketsRepository>().refundTicket(
      ticket.ticketId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reembolso solicitado.')));
        setState(() => _future = _load());
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de entrada')),
      body: FutureBuilder<WalletTicket>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CiervoLoadingState(itemCount: 3);
          }
          if (snapshot.hasError) {
            return CiervoErrorState(
              title: 'No pudimos cargar la entrada',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final ticket = snapshot.data!;
          final qr = ticket.qr ?? ticket.ticketId;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                ticket.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('${ticket.ticketId} · ${ticket.status}'),
              if (ticket.venue != null) Text(ticket.venue!),
              if (ticket.startsAt != null)
                Text(
                  DisplayFormatters.formatDate(
                    ticket.startsAt!,
                    includeTime: true,
                  ),
                ),
              if (ticket.seatIds.isNotEmpty)
                Text('Asientos: ${ticket.seatIds.join(', ')}'),
              if (ticket.amount != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DisplayFormatters.formatMoney(
                    ticket.amount!,
                    currency: ticket.currency,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.primary),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: qr.startsWith('CIERVO-TICKET-')
                        ? qr
                        : 'CIERVO-TICKET-$qr',
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_busy) ...[
                CiervoButton(
                  label: 'Cancelar entrada',
                  variant: CiervoButtonVariant.secondary,
                  onPressed: () => _cancel(ticket),
                ),
                const SizedBox(height: AppSpacing.sm),
                CiervoButton(
                  label: 'Solicitar reembolso',
                  variant: CiervoButtonVariant.secondary,
                  onPressed: () => _refund(ticket),
                ),
              ] else
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
