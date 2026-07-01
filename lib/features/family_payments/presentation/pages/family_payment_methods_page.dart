import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/family_payments_repository.dart';
import '../cubit/family_payment_methods_cubit.dart';
import '../cubit/family_payment_methods_state.dart';
import '../../domain/entities/family_payment_card.dart';
import '../widgets/family_payment_card_tile.dart';
import 'add_family_card_page.dart';
import 'mercado_pago_3ds_page.dart';

class FamilyPaymentMethodsPage extends StatelessWidget {
  const FamilyPaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FamilyPaymentMethodsCubit(getIt<FamilyPaymentsRepository>())
        ..load(),
      child: const _FamilyPaymentMethodsView(),
    );
  }
}

class _FamilyPaymentMethodsView extends StatelessWidget {
  const _FamilyPaymentMethodsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FamilyPaymentMethodsCubit, FamilyPaymentMethodsState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Métodos de pago')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddFamilyCardPage()),
              );
              if (added == true && context.mounted) {
                context.read<FamilyPaymentMethodsCubit>().load();
              }
            },
            icon: const Icon(Icons.add_card),
            label: const Text('Agregar tarjeta'),
          ),
          body: RefreshIndicator(
            onRefresh: context.read<FamilyPaymentMethodsCubit>().load,
            child: ListView(
              padding: pagePaddingOf(context),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Tarjetas Visa/Mastercard registradas para respaldar pagos de tus hijos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.status == FamilyPaymentMethodsStatus.loading)
                  const CiervoLoadingState(itemCount: 3)
                else if (state.status == FamilyPaymentMethodsStatus.failure)
                  CiervoErrorState(
                    title: 'No pudimos cargar tus tarjetas',
                    description: state.errorMessage ?? 'Intenta nuevamente.',
                    onRetry: context.read<FamilyPaymentMethodsCubit>().load,
                  )
                else if (state.cards.isEmpty)
                  const CiervoEmptyState(
                    title: 'Sin tarjetas registradas',
                    description:
                        'Agrega una tarjeta Visa o Mastercard para respaldar pagos familiares.',
                    icon: Icons.credit_card_off_outlined,
                  )
                else
                  ...state.cards.map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FamilyPaymentCardTile(
                              card: card,
                              onTap: () => _openActions(context, card),
                            ),
                            const Divider(height: 1),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                if (!card.isPrimary)
                                  OutlinedButton(
                                    onPressed: state.actionCardId == card.id
                                        ? null
                                        : () => context
                                            .read<FamilyPaymentMethodsCubit>()
                                            .setPrimary(card.id),
                                    child: const Text('Principal'),
                                  ),
                                if (!card.isBackup)
                                  OutlinedButton(
                                    onPressed: state.actionCardId == card.id
                                        ? null
                                        : () => context
                                            .read<FamilyPaymentMethodsCubit>()
                                            .setBackup(card.id),
                                    child: const Text('Respaldo'),
                                  ),
                                OutlinedButton(
                                  onPressed: state.actionCardId == card.id
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EditFamilyCardAliasPage(
                                                card: card,
                                              ),
                                            ),
                                          ),
                                  child: const Text('Editar alias'),
                                ),
                                OutlinedButton(
                                  onPressed: state.actionCardId == card.id
                                      ? null
                                      : () => context
                                          .read<FamilyPaymentMethodsCubit>()
                                          .freeze(card.id),
                                  child: Text(
                                    card.isFrozen ? 'Descongelar' : 'Congelar',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openActions(
    BuildContext context,
    FamilyPaymentCard card,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar alias'),
              onTap: () => Navigator.pop(context, 'alias'),
            ),
            if (!card.isPrimary)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Marcar como principal'),
                onTap: () => Navigator.pop(context, 'primary'),
              ),
            if (!card.isBackup)
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Marcar como respaldo'),
                onTap: () => Navigator.pop(context, 'backup'),
              ),
            ListTile(
              leading: Icon(
                card.isFrozen ? Icons.ac_unit : Icons.ac_unit_outlined,
              ),
              title: Text(card.isFrozen ? 'Descongelar tarjeta' : 'Congelar tarjeta'),
              onTap: () => Navigator.pop(context, 'freeze'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar tarjeta'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    final cubit = context.read<FamilyPaymentMethodsCubit>();
    switch (action) {
      case 'alias':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditFamilyCardAliasPage(card: card),
          ),
        );
      case 'primary':
        await cubit.setPrimary(card.id);
      case 'backup':
        await cubit.setBackup(card.id);
      case 'freeze':
        if (card.isFrozen) {
          await cubit.unfreeze(card.id);
        } else {
          await cubit.freeze(card.id);
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar tarjeta'),
            content: const Text(
              'Esta tarjeta dejará de estar disponible como fuente de pago.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (confirmed == true) await cubit.deleteCard(card.id);
    }
  }
}
