import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../data/chat_payments_remote_datasource.dart';

class ChatGiftPage extends StatefulWidget {
  const ChatGiftPage({
    this.conversationId,
    this.initialTargetCiervoCode,
    this.initialTargetUserId,
    super.key,
  });

  final String? conversationId;
  final String? initialTargetCiervoCode;
  final String? initialTargetUserId;

  @override
  State<ChatGiftPage> createState() => _ChatGiftPageState();
}

class _ChatGiftPageState extends State<ChatGiftPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _giftType = 'Money';
  bool _sending = false;

  static const _giftTypes = <String, String>{
    'Money': 'Dinero',
    'GiftCard': 'Tarjeta regalo',
    'Coupon': 'Cupon',
    'Benefit': 'Beneficio',
    'Event': 'Evento',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialTargetCiervoCode != null) {
      _codeController.text = widget.initialTargetCiervoCode!;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar regalo')),
      body: AbsorbPointer(
        absorbing: _sending,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _giftType,
                  decoration: const InputDecoration(labelText: 'Tipo de regalo'),
                  items: _giftTypes.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: _sending
                      ? null
                      : (value) => setState(() => _giftType = value ?? 'Money'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Ciervo ID del destinatario',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
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
                    labelText: 'Mensaje (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: _sending ? 'Enviando' : 'Enviar regalo',
                  icon: Icons.card_giftcard_outlined,
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
    final code = _codeController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0 || (code.isEmpty && widget.initialTargetUserId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa Ciervo ID o selecciona destinatario y un monto valido.'),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await getIt<ChatPaymentsRemoteDataSource>().sendGift(
        chatConversationId: widget.conversationId,
        targetCiervoUserCode: code,
        targetUserId: widget.initialTargetUserId,
        amount: amount,
        giftType: _giftType,
        message: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regalo enviado correctamente.')),
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
