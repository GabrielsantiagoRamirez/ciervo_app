import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
// ignore: unused_import
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../financial_history/presentation/pages/financial_history_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../payments/presentation/pages/payments_history_page.dart';
import '../../../pins/presentation/pages/pins_page.dart';
import '../../../receipts/presentation/pages/receipts_page.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/premium_wallet_dashboard.dart';
import '../widgets/wallet_nfc_section.dart';
import 'payment_requests_page.dart';
import 'recharge_by_ciervo_id_page.dart';
import 'recharge_page.dart';
import 'request_money_page.dart';
import 'transfer_page.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(getIt<WalletRepository>())..load(),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletCubit, WalletState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<WalletCubit>();
        return Scaffold(
          backgroundColor: state.status == WalletStatus.loaded ||
                  state.status == WalletStatus.empty
              ? const Color(0xFF0D0D0D)
              : null,
          appBar: state.status == WalletStatus.loaded
              ? null
              : AppBar(
                  title: const Text('Wallet'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsPage(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.receipt_long_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ReceiptsPage(),
                        ),
                      ),
                    ),
                  ],
                ),
          body: RefreshIndicator(
            onRefresh: cubit.load,
            child: state.status == WalletStatus.loaded
                ? PremiumWalletDashboard(state: state)
                : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverToBoxAdapter(child: _body(context, state)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, WalletState state) {
    final cubit = context.read<WalletCubit>();
    return switch (state.status) {
      WalletStatus.initial ||
      WalletStatus.loading => const CiervoLoadingState(itemCount: 5),
      WalletStatus.empty => Column(
        children: [
          const CiervoEmptyState(
            title: 'Sin tarjetas',
            description: 'Tu wallet aun no tiene tarjetas disponibles.',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          const _RequestCiervoCard(),
        ],
      ),
      WalletStatus.failure => CiervoErrorState(
        title: 'No pudimos cargar tu wallet',
        description: state.errorMessage ?? 'Intenta nuevamente.',
        onRetry: cubit.load,
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceSummary(state: state),
          const SizedBox(height: AppSpacing.lg),
          _QuickActions(state: state),
          WalletNfcSection(selectedCard: state.selectedCard),
          const SizedBox(height: AppSpacing.lg),
          Text('Tarjetas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 224,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final card = state.cards[index];
                return _WalletCardTile(
                  card: card,
                  selected: state.selectedCard?.id == card.id,
                  onTap: () => cubit.selectCard(card),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _RequestCiervoCard(),
          const SizedBox(height: AppSpacing.lg),
          if (state.selectedCard != null)
            _CardActions(card: state.selectedCard!),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Solicitudes pendientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PendingRequests(requests: state.inboxRequests),
          const SizedBox(height: AppSpacing.lg),
          Text('Movimientos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (state.transactions.isEmpty)
            const CiervoEmptyState(
              title: 'Sin movimientos',
              description: 'Esta tarjeta aun no tiene transacciones.',
              icon: Icons.swap_vert_rounded,
            )
          else
            ...state.transactions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TransactionTile(transaction: item),
              ),
            ),
        ],
      ),
    };
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    final primary =
        state.cards.where((card) => card.isPrimary).firstOrNull ??
        state.selectedCard ??
        (state.cards.isEmpty ? null : state.cards.first);
    final totalAvailable = state.cards.fold<double>(
      0,
      (sum, card) => sum + card.availableBalance,
    );
    final totalHeld = state.cards.fold<double>(
      0,
      (sum, card) => sum + card.heldBalance,
    );
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo disponible',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _money(
              primary?.availableBalance ?? totalAvailable,
              primary?.currency ?? 'COP',
            ),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          if (totalHeld > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Retenido: ${_money(totalHeld, primary?.currency ?? 'COP')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Balance total: ${_money(primary?.balance ?? totalAvailable + totalHeld, primary?.currency ?? 'COP')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            primary == null
                ? 'Sin tarjeta principal'
                : 'Tarjeta principal: ${primary.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.state});
  final WalletState state;

  @override
  Widget build(BuildContext context) {
    final card = state.selectedCard;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _ActionChipButton(
          label: 'Recargar',
          icon: Icons.add_card_outlined,
          onTap: card == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RechargePage(card: card),
                  ),
                ),
        ),
        _ActionChipButton(
          label: 'Transferir',
          icon: Icons.send_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => TransferPage(card: card)),
          ),
        ),
        _ActionChipButton(
          label: 'Recargar ID',
          icon: Icons.person_add_alt_1_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const RechargeByCiervoIdPage(),
            ),
          ),
        ),
        _ActionChipButton(
          label: 'Paga por mi',
          icon: Icons.request_page_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RequestMoneyPage()),
          ),
        ),
        _ActionChipButton(
          label: 'Solicitudes',
          icon: Icons.mark_email_unread_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PaymentRequestsPage(),
            ),
          ),
        ),
        _ActionChipButton(
          label: 'PIN Ciervo',
          icon: Icons.pin_outlined,
          onTap: card == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PinsPage(card: card),
                  ),
                ),
        ),
        _ActionChipButton(
          label: 'Recibos',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ReceiptsPage())),
        ),
        _ActionChipButton(
          label: 'Pagos MP',
          icon: Icons.payments_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PaymentsHistoryPage(),
            ),
          ),
        ),
        _ActionChipButton(
          label: 'Historial',
          icon: Icons.timeline_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FinancialHistoryPage(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingRequests extends StatelessWidget {
  const _PendingRequests({required this.requests});

  final List<PaymentRequest> requests;

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r.isPending).take(3).toList();
    if (pending.isEmpty) {
      return const CiervoEmptyState(
        title: 'Sin solicitudes pendientes',
        description: 'Aqui veras solicitudes por aprobar o rechazar.',
        icon: Icons.mark_email_read_outlined,
      );
    }
    return Column(
      children: [
        ...pending.map(
          (request) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: PendingPaymentRequestTile(request: request),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PaymentRequestsPage(),
              ),
            ),
            child: const Text('Ver todas'),
          ),
        ),
      ],
    );
  }
}

class _WalletCardTile extends StatelessWidget {
  const _WalletCardTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });
  final WalletCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 272,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: CiervoCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: colorScheme.primary),
                  const Spacer(),
                  if (card.isPrimary) const _StatusPill(label: 'Principal'),
                  if (selected)
                    Icon(Icons.check_circle, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                card.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                card.mask ?? card.id,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _money(card.availableBalance, card.currency),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (card.heldBalance > 0)
                Text(
                  'Retenido: ${_money(card.heldBalance, card.currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(card.status, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCiervoCard extends StatelessWidget {
  const _RequestCiervoCard();

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.add_card_outlined),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solicitar Tarjeta Ciervo'),
                SizedBox(height: AppSpacing.xxs),
                Text('Disponible próximamente'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Solicitar Tarjeta Ciervo'),
                content: const Text(
                  'Estamos conectando la solicitud de nuevas tarjetas.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.card});
  final WalletCard card;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletCubit>();
    return CiervoCard(
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _ActionChipButton(
            label: 'Principal',
            icon: Icons.star_outline,
            onTap: () => cubit.setPrimary(card.id),
          ),
          _ActionChipButton(
            label: card.isBlocked ? 'Desbloquear' : 'Bloquear',
            icon: card.isBlocked
                ? Icons.lock_open_outlined
                : Icons.lock_outline,
            onTap: () => _confirm(
              context,
              card.isBlocked ? 'Desbloquear tarjeta' : 'Bloquear tarjeta',
              card.isBlocked
                  ? () => cubit.unblock(card.id)
                  : () => cubit.block(card.id),
            ),
          ),
          _ActionChipButton(
            label: 'Eliminar',
            icon: Icons.delete_outline,
            onTap: () => _confirm(
              context,
              'Eliminar tarjeta',
              () => cubit.delete(card.id),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    VoidCallback action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Confirma esta accion para continuar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) action();
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.direction.toLowerCase().contains('debit');
    return CiervoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
            color: isDebit ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isEmpty
                      ? transaction.type
                      : transaction.description,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  transaction.createdAt?.toLocal().toString() ??
                      transaction.direction,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _money(transaction.amount, transaction.currency),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}

String _money(double amount, String currency) =>
    '$currency ${amount.toStringAsFixed(0)}';
