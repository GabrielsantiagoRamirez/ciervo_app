import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../data/datasources/payment_approvals_remote_datasource.dart';

class PaymentApprovalRequestPage extends StatefulWidget {
  const PaymentApprovalRequestPage({
    this.chatConversationId,
    this.businessId,
    super.key,
  });

  final String? chatConversationId;
  final int? businessId;

  @override
  State<PaymentApprovalRequestPage> createState() =>
      _PaymentApprovalRequestPageState();
}

class _PaymentApprovalRequestPageState extends State<PaymentApprovalRequestPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar aprobacion')),
      body: AbsorbPointer(
        absorbing: _sending,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tu tutor o responsable recibira la solicitud para autorizar este pago.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto (COP)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: _sending ? 'Enviando' : 'Enviar solicitud',
                  icon: Icons.verified_user_outlined,
                  state: _sending
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _sending ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto valido.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await getIt<PaymentApprovalsRemoteDataSource>().createRequest(
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? 'Solicitud de aprobacion'
            : _descriptionController.text.trim(),
        chatConversationId: widget.chatConversationId,
        businessId: widget.businessId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada a tu tutor.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
