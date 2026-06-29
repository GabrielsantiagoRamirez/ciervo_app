import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';

class DeliverySettlementAccountPage extends StatefulWidget {
  const DeliverySettlementAccountPage({super.key, this.profile});

  final DeliveryProfile? profile;

  @override
  State<DeliverySettlementAccountPage> createState() =>
      _DeliverySettlementAccountPageState();
}

class _DeliverySettlementAccountPageState
    extends State<DeliverySettlementAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _accountType = TextEditingController();
  final _accountNumber = TextEditingController();
  final _holderName = TextEditingController();
  final _documentNumber = TextEditingController();
  final _walletProvider = TextEditingController();
  final _walletNumber = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bank.dispose();
    _accountType.dispose();
    _accountNumber.dispose();
    _holderName.dispose();
    _documentNumber.dispose();
    _walletProvider.dispose();
    _walletNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cuenta de liquidacion')),
    body: AbsorbPointer(
      absorbing: _saving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.profile != null) ...[
              _CurrentSettlementStatus(profile: widget.profile!),
              const SizedBox(height: AppSpacing.lg),
            ],
            _field(_bank, 'Banco'),
            _field(_accountType, 'Tipo de cuenta'),
            _field(_accountNumber, 'Numero de cuenta'),
            _field(_holderName, 'Titular'),
            _field(_documentNumber, 'Documento'),
            _field(_walletProvider, 'Nequi/Daviplata/MercadoPago opcional',
                required: false),
            _field(_walletNumber, 'Numero billetera opcional',
                required: false),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: _saving ? 'Guardando' : 'Guardar cuenta',
              icon: Icons.account_balance_outlined,
              state:
                  _saving ? CiervoButtonState.loading : CiervoButtonState.normal,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (value) =>
                    value == null || value.trim().isEmpty ? 'Requerido' : null
              : null,
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await getIt<DeliveryRepository>().updateSettlementAccount(
      DeliverySettlementAccount(
        bank: _bank.text.trim(),
        accountType: _accountType.text.trim(),
        accountNumber: _accountNumber.text.trim(),
        holderName: _holderName.text.trim(),
        documentNumber: _documentNumber.text.trim(),
        walletProvider: _walletProvider.text.trim(),
        walletNumber: _walletNumber.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu cuenta fue enviada a revision. Cuando sea aprobada podras ponerte online y recibir domicilios.',
          ),
        ),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

class _CurrentSettlementStatus extends StatelessWidget {
  const _CurrentSettlementStatus({required this.profile});

  final DeliveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final status = profile.settlementAccountVerificationStatus ??
        (profile.hasSettlementAccount ? 'Pending' : 'Sin registrar');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado: $status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (profile.settlementAccountRejectionReason != null)
          Text('Motivo: ${profile.settlementAccountRejectionReason}'),
        const SizedBox(height: AppSpacing.sm),
        if (profile.maskedAccountNumber != null)
          Text('Cuenta: ${profile.maskedAccountNumber}'),
        if (profile.maskedDocumentNumber != null)
          Text('Documento: ${profile.maskedDocumentNumber}'),
        if (profile.maskedPhone != null)
          Text('Telefono: ${profile.maskedPhone}'),
        if (profile.maskedMercadoPago != null)
          Text('Mercado Pago: ${profile.maskedMercadoPago}'),
        if (status == 'Rejected')
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Se abrio una conversacion de soporte para ayudarte a corregir la cuenta.',
            ),
          ),
      ],
    );
  }
}
