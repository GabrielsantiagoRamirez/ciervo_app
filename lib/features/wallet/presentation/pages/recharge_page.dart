import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../../../receipts/domain/entities/action_confirmation.dart';
import '../../../receipts/presentation/pages/action_confirmation_page.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({required this.card, super.key});
  final WalletCard card;

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final _amountController = TextEditingController();
  String? _lastIntentId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(getIt<WalletRepository>()),
      child: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) async {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          if (state.rechargeIntent?.isSucceeded == true &&
              state.successMessage != null &&
              state.successMessage!.contains('acreditada')) {
            final amount =
                double.tryParse(
                  _amountController.text.replaceAll(',', '.'),
                ) ??
                0;
            final userCode = await resolveCurrentCiervoUserCode();
            if (!context.mounted) return;
            await showCiervoPaymentReceipt(
              context,
              confirmation: ActionConfirmation(
                title: 'Recarga confirmada',
                confirmationCode:
                    state.rechargeIntent?.id ?? _lastIntentId ?? '',
                userCiervoCode: userCode,
                amount: amount > 0 ? amount : null,
                currency: widget.card.currency,
                status: 'Pago realizado con éxito',
                shareDescription:
                    'Tu saldo CIERVO fue recargado correctamente.',
              ),
              referenceLabel: 'Tarjeta',
              referenceValue: widget.card.name,
            );
            return;
          }
          if (state.successMessage != null &&
              state.successMessage!.contains('Recarga') &&
              state.rechargeIntent?.isSucceeded != true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
          }
          final url = state.rechargeIntent?.checkoutUrl;
          final intentId = state.rechargeIntent?.id;
          if (url != null && url.isNotEmpty && intentId != _lastIntentId) {
            _lastIntentId = intentId;
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          }
        },
        builder: (context, state) {
          final intentId = state.rechargeIntent?.id ?? _lastIntentId;
          return Scaffold(
            appBar: AppBar(title: const Text('Recargar')),
            body: Stack(
              children: [
                AbsorbPointer(
                  absorbing: state.isLoading,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.card.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Disponible: ${widget.card.currency} ${widget.card.availableBalance.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Monto a recargar',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CiervoButton(
                            label: state.isLoading
                                ? 'Creando recarga'
                                : 'Continuar a Mercado Pago',
                            icon: Icons.open_in_new,
                            state: state.isLoading
                                ? CiervoButtonState.loading
                                : CiervoButtonState.normal,
                            onPressed: () {
                              final amount =
                                  double.tryParse(
                                    _amountController.text.replaceAll(',', '.'),
                                  ) ??
                                  0;
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingresa un monto valido.'),
                                  ),
                                );
                                return;
                              }
                              context.read<WalletCubit>().createRechargeIntent(
                                widget.card.id,
                                amount,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CiervoButton(
                            label: 'Ya pague, consultar estado',
                            variant: CiervoButtonVariant.secondary,
                            icon: Icons.refresh,
                            onPressed: intentId == null
                                ? null
                                : () => context
                                    .read<WalletCubit>()
                                    .pollRechargeIntent(intentId),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.isLoading)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.88),
                      ),
                      child: const CiervoBrandLoader(
                        message: 'Creando recarga segura',
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
