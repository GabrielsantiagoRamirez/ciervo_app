import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';

class RequestMoneyPage extends StatefulWidget {
  const RequestMoneyPage({this.initialPayerCiervoCode, super.key});

  final String? initialPayerCiervoCode;

  @override
  State<RequestMoneyPage> createState() => _RequestMoneyPageState();
}

class _RequestMoneyPageState extends State<RequestMoneyPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPayerCiervoCode != null) {
      _codeController.text = widget.initialPayerCiervoCode!;
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
          final canSubmit = _canSubmit(state);
          return Scaffold(
            appBar: AppBar(title: const Text('Paga por mi')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CiervoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        hintText: 'Ciervo ID de quien paga',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      onChanged: (_) => setState(() {}),
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
                        'Pagador: ${state.resolvedUser!.displayName}',
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
                      onChanged: (_) => setState(() {}),
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
                      label: state.isLoading ? 'Enviando' : 'Enviar solicitud',
                      icon: Icons.outgoing_mail,
                      state: state.isLoading
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: canSubmit ? () => _submit(context, state) : null,
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

  bool _canSubmit(WalletState state) {
    if (state.isLoading) return false;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final code = _codeController.text.trim();
    return amount > 0 && (code.isNotEmpty || state.resolvedUser != null);
  }

  void _submit(BuildContext context, WalletState state) {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final code = _codeController.text.trim();
    final payer = state.resolvedUser;
    if (amount <= 0 || (code.isEmpty && payer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa Ciervo ID o resuelve usuario y un monto valido.'),
        ),
      );
      return;
    }
    context.read<WalletCubit>().requestMoney(
      payerUserId: payer?.userId,
      payerCiervoUserCode:
          code.isNotEmpty ? code : payer?.ciervoUserCode,
      amount: amount,
      description: _descriptionController.text.trim().isEmpty
          ? 'Solicitud de pago'
          : _descriptionController.text.trim(),
    );
  }
}

/// Preview de solicitudes recibidas con acciones rapidas.
class PendingPaymentRequestTile extends StatelessWidget {
  const PendingPaymentRequestTile({required this.request, super.key});

  final PaymentRequest request;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.request_page_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  request.description.isEmpty
                      ? 'Solicitud ${request.status}'
                      : request.description,
                ),
              ),
              Text('${request.currency} ${request.amount.toStringAsFixed(0)}'),
            ],
          ),
          if (request.isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: () => context
                      .read<WalletCubit>()
                      .approvePaymentRequest(request.id),
                  child: const Text('Aprobar'),
                ),
                OutlinedButton(
                  onPressed: () => _reject(context),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ],
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
