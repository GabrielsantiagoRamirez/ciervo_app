import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/insufficient_balance_dialog.dart';
import '../../../chat_payments/data/chat_payments_remote_datasource.dart';
import '../../../loyalty/loyalty_purchase_helper.dart';
import '../../../receipts/presentation/pages/receipts_page.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';

class ChatPayPage extends StatefulWidget {
  const ChatPayPage({
    this.chatConversationId,
    this.initialTargetCiervoCode,
    this.initialTargetUserId,
    this.businessId,
    this.businessName,
    super.key,
  });

  final String? chatConversationId;
  final String? initialTargetCiervoCode;
  final String? initialTargetUserId;
  final int? businessId;
  final String? businessName;

  @override
  State<ChatPayPage> createState() => _ChatPayPageState();
}

class _ChatPayPageState extends State<ChatPayPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _paying = false;

  bool get _isBusinessPay =>
      widget.businessId != null && (widget.initialTargetCiervoCode == null);

  @override
  void initState() {
    super.initState();
    if (widget.initialTargetCiervoCode != null) {
      _codeController.text = widget.initialTargetCiervoCode!;
    }
    if (widget.businessName != null) {
      _descriptionController.text = 'Pago a ${widget.businessName}';
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
      child: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          final resolved = state.resolvedUser;
          final canPay = !_paying &&
              (double.tryParse(_amountController.text.replaceAll(',', '.')) ??
                      0) >
                  0 &&
              (_isBusinessPay ||
                  _codeController.text.trim().isNotEmpty ||
                  resolved != null ||
                  widget.initialTargetUserId != null);

          return Scaffold(
            appBar: AppBar(title: const Text('Pagar')),
            body: AbsorbPointer(
              absorbing: _paying,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: CiervoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isBusinessPay)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.storefront_outlined),
                          title: Text(widget.businessName ?? 'Comercio'),
                          subtitle: Text('Negocio #${widget.businessId}'),
                        )
                      else ...[
                        TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Ciervo ID del destinatario',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        CiervoButton(
                          label: 'Resolver usuario',
                          icon: Icons.person_search_outlined,
                          variant: CiervoButtonVariant.secondary,
                          onPressed: () => context
                              .read<WalletCubit>()
                              .resolveUser(_codeController.text.trim()),
                        ),
                        if (resolved != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Destinatario: ${resolved.displayName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monto (COP)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Concepto',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: _paying ? 'Procesando' : 'Pagar con wallet',
                        icon: Icons.payments_outlined,
                        state: _paying
                            ? CiervoButtonState.loading
                            : CiervoButtonState.normal,
                        onPressed: canPay ? () => _submit(context, state) : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context, WalletState state) async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    final code = _codeController.text.trim();
    final resolved = state.resolvedUser;
    final targetUserId = resolved?.userId ?? widget.initialTargetUserId;
    final targetCode = code.isNotEmpty ? code : resolved?.ciervoUserCode;

    if (!_isBusinessPay &&
        (targetUserId == null || targetUserId.isEmpty) &&
        (targetCode == null || targetCode.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa o resuelve el Ciervo ID del destinatario.'),
        ),
      );
      return;
    }

    setState(() => _paying = true);
    try {
      final response = await getIt<ChatPaymentsRemoteDataSource>().pay(
        chatConversationId: widget.chatConversationId,
        targetCiervoUserCode: targetCode,
        targetUserId: targetUserId,
        businessId: widget.businessId,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? 'Pago en chat'
            : _descriptionController.text.trim(),
      );
      if (!mounted) return;

      final receipt = response['receipt'] ?? response['Receipt'];
      final receiptId = receipt is Map
          ? '${receipt['id'] ?? receipt['Id'] ?? ''}'
          : null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago realizado correctamente.')),
      );

      if (_isBusinessPay) {
        await processLoyaltyAfterPurchase(
          context,
          amount: amount,
          businessId: widget.businessId,
          paymentIntentId: int.tryParse(
            '${response['paymentIntentId'] ?? response['intentId'] ?? ''}',
          ),
          transactionId: receiptId,
        );
      }

      if (receiptId != null && receiptId.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReceiptDetailPage(id: receiptId),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = UserErrorMessage.from(error);
      if (message.toLowerCase().contains('saldo')) {
        await _showInsufficientBalanceDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _showInsufficientBalanceDialog(BuildContext context) async {
    await showInsufficientBalanceDialog(
      context,
      chatConversationId: widget.chatConversationId,
    );
  }
}
