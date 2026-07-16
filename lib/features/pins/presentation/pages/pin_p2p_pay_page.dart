import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../wallet/domain/entities/wallet_card.dart';
import '../../data/pin_p2p_service.dart';

class PinP2PPayPage extends StatefulWidget {
  const PinP2PPayPage({required this.card, super.key});

  final WalletCard card;

  @override
  State<PinP2PPayPage> createState() => _PinP2PPayPageState();
}

class _PinP2PPayPageState extends State<PinP2PPayPage> {
  final _p2p = getIt<PinP2PService>();
  final _paymentPinIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _busy = false;
  String? _verifyMessage;
  String? _error;

  String get _currency {
    final value = widget.card.currency.trim();
    return value.isEmpty ? 'COP' : value.toUpperCase();
  }

  @override
  void dispose() {
    _paymentPinIdController.dispose();
    _pinController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? _parseAmount() =>
      double.tryParse(_amountController.text.replaceAll(',', '.'));

  bool _validateFields() {
    final paymentPinId = _paymentPinIdController.text.trim();
    final pin = _pinController.text.trim();
    final amount = _parseAmount();
    if (paymentPinId.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Ingresa el ID de PIN y el código.');
      return false;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return false;
    }
    if (!widget.card.canSpend(amount)) {
      setState(
        () => _error =
            'Saldo disponible insuficiente '
            '($_currency ${widget.card.availableBalance.toStringAsFixed(0)}).',
      );
      return false;
    }
    return true;
  }

  Future<void> _verify() async {
    if (!_validateFields()) return;
    setState(() {
      _busy = true;
      _error = null;
      _verifyMessage = null;
    });
    final result = await _p2p.verify(
      paymentPinId: _paymentPinIdController.text.trim(),
      pin: _pinController.text.trim(),
      amount: _parseAmount(),
    );
    if (!mounted) return;
    result.when(
      success: (value) => setState(() {
        _busy = false;
        if (value.valid) {
          final name = value.payerName?.trim();
          _verifyMessage = name != null && name.isNotEmpty
              ? 'PIN válido · $name'
              : 'PIN válido. Puedes cobrar.';
        } else {
          _error = value.message ?? 'PIN incorrecto, bloqueado o expirado.';
        }
      }),
      failure: (error) => setState(() {
        _busy = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  Future<void> _pay() async {
    if (!_validateFields()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _p2p.pay(
      paymentPinId: _paymentPinIdController.text.trim(),
      pin: _pinController.text.trim(),
      amount: _parseAmount()!,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    result.when(
      success: (value) {
        setState(() => _busy = false);
        if (!value.success) {
          setState(() => _error = value.message ?? 'No se pudo completar el cobro.');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value.message ??
                  'Cobro realizado por $_currency '
                      '${(value.amount ?? _parseAmount())?.toStringAsFixed(0)}.',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      },
      failure: (error) => setState(() {
        _busy = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cobrar con PIN')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paga a otra persona con su PIN semanal Ciervo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _paymentPinIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID del PIN (paymentPinId)',
                    hintText: 'Ej. 15',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN de la otra persona',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Monto ($_currency)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
                if (_verifyMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _verifyMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: 'Verificar PIN',
                  icon: Icons.verified_outlined,
                  variant: CiervoButtonVariant.secondary,
                  onPressed: _busy ? null : _verify,
                ),
                const SizedBox(height: AppSpacing.sm),
                CiervoButton(
                  label: 'Cobrar',
                  icon: Icons.payments_outlined,
                  onPressed: _busy ? null : _pay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
