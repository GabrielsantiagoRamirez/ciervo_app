import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/currency_selector.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({this.card, this.initialCiervoCode, super.key});
  final WalletCard? card;
  final String? initialCiervoCode;

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _currency = 'COP';

  @override
  void initState() {
    super.initState();
    if (widget.initialCiervoCode != null) {
      _codeController.text = widget.initialCiervoCode!;
    }
    if (widget.card?.currency.isNotEmpty == true) {
      _currency = widget.card!.currency;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(getIt<WalletRepository>()),
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
            appBar: AppBar(title: const Text('Transferir')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CiervoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        hintText: 'Ciervo ID del destinatario',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Resolver usuario',
                      icon: Icons.person_search_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: () => context.read<WalletCubit>().resolveUser(
                        _codeController.text.trim(),
                      ),
                    ),
                    if (state.resolvedUser != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Destinatario: ${state.resolvedUser!.displayName}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Monto',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CurrencySelector(
                      value: _currency,
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Descripcion',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: state.isLoading
                          ? 'Procesando'
                          : 'Confirmar transferencia',
                      icon: Icons.send_outlined,
                      state: state.isLoading
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: () => _confirmTransfer(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmTransfer(BuildContext context) async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (_codeController.text.trim().isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa Ciervo ID y monto valido.')),
      );
      return;
    }
    final card = widget.card;
    if (card != null && !card.canSpend(amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo disponible insuficiente (COP ${card.availableBalance.toStringAsFixed(0)}).',
          ),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar transferencia'),
        content: Text(
          'Enviar $_currency ${amount.toStringAsFixed(0)} a ${_codeController.text.trim()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<WalletCubit>().transfer(
      targetCiervoUserCode: _codeController.text.trim(),
      amount: amount,
      description: _descriptionController.text.trim(),
      walletCardId: widget.card?.id,
      currency: _currency,
    );
  }
}
