import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../widgets/payment_request_approve_sheet.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';

class PaymentRequestsPage extends StatelessWidget {
  const PaymentRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(getIt<WalletRepository>())
        ..load()
        ..loadPaymentRequests(),
      child: DefaultTabController(
        length: 2,
        child: BlocConsumer<WalletCubit, WalletState>(
          listener: (context, state) {
            final message = state.errorMessage ?? state.successMessage;
            if (message != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Solicitudes'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Recibidas'),
                    Tab(text: 'Enviadas'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _RequestList(
                    requests: state.inboxRequests,
                    isLoading: state.status == WalletStatus.loading,
                    emptyTitle: 'Sin solicitudes recibidas',
                    onRetry: context.read<WalletCubit>().loadPaymentRequests,
                    errorMessage: state.errorMessage,
                    actions: _RequestActions.inbox,
                  ),
                  _RequestList(
                    requests: state.sentRequests,
                    isLoading: state.status == WalletStatus.loading,
                    emptyTitle: 'Sin solicitudes enviadas',
                    onRetry: context.read<WalletCubit>().loadPaymentRequests,
                    errorMessage: state.errorMessage,
                    actions: _RequestActions.sent,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _RequestActions { inbox, sent }

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.isLoading,
    required this.emptyTitle,
    required this.onRetry,
    required this.actions,
    this.errorMessage,
  });

  final List<PaymentRequest> requests;
  final bool isLoading;
  final String emptyTitle;
  final VoidCallback onRetry;
  final String? errorMessage;
  final _RequestActions actions;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CiervoLoadingState(itemCount: 4),
      );
    }
    if (errorMessage != null && requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CiervoErrorState(
          title: 'No pudimos cargar solicitudes',
          description: errorMessage!,
          onRetry: onRetry,
        ),
      );
    }
    if (requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CiervoEmptyState(
          title: emptyTitle,
          description: 'Cuando haya movimientos pendientes aparecerán aquí.',
          icon: Icons.mark_email_unread_outlined,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) =>
            _RequestTile(request: requests[index], actions: actions),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.actions});

  final PaymentRequest request;
  final _RequestActions actions;

  String get _counterpartyLine {
    if (actions == _RequestActions.inbox) {
      return DisplayFormatters.identityLine(
        username: request.requesterUsername,
        displayName: request.requesterName,
        ciervoId: request.requesterCiervoId,
      );
    }
    return DisplayFormatters.identityLine(
      username: request.payerUsername,
      displayName: request.payerName ?? request.targetName,
      ciervoId: request.payerCiervoId,
    );
  }

  String get _concept => DisplayFormatters.safeText(
    request.description,
    fallback: 'Solicitud de pago',
  );

  Future<void> _approve(BuildContext context) async {
    final cubit = context.read<WalletCubit>();
    final options = await showPaymentRequestApproveSheet(
      context,
      request: request,
      walletCards: cubit.state.cards,
    );
    if (options == null || !context.mounted) return;
    await cubit.approvePaymentRequest(
      request.id,
      useBackupCard: options.useBackupCard,
      familyPaymentCardId: options.familyPaymentCardId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final counterparty = _counterpartyLine;
    final statusLabel = DisplayFormatters.safeText(
      request.status,
      fallback: DisplayFormatters.formatStatus(request.rawStatus),
    );

    return CiervoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.request_page_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _concept,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (counterparty.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        counterparty,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                DisplayFormatters.formatMoney(
                  request.amount,
                  currency: request.currency,
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatusChip(label: statusLabel),
              if (request.expiresAt != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Vence ${DisplayFormatters.formatDate(request.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (actions == _RequestActions.inbox && request.isPending)
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: () => _approve(context),
                  child: const Text('Aprobar'),
                ),
                OutlinedButton(
                  onPressed: () => _reject(context),
                  child: const Text('Rechazar'),
                ),
              ],
            )
          else if (actions == _RequestActions.sent && request.isPending)
            OutlinedButton(
              onPressed: () =>
                  context.read<WalletCubit>().cancelPaymentRequest(request.id),
              child: const Text('Cancelar'),
            ),
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Motivo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    context.read<WalletCubit>().rejectPaymentRequest(request.id, reason);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
