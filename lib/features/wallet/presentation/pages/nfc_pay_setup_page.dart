import 'package:flutter/material.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/insufficient_balance_dialog.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../pages/nfc_pay_session_page.dart';
import '../utils/nfc_navigation.dart';

class NfcPaySetupPage extends StatefulWidget {
  const NfcPaySetupPage({
    this.initialBusinessId,
    this.initialBusinessName,
    this.initialAmount,
    this.initialWalletCardId,
    this.initialDescription,
    super.key,
  });

  final int? initialBusinessId;
  final String? initialBusinessName;
  final double? initialAmount;
  final String? initialWalletCardId;
  final String? initialDescription;

  @override
  State<NfcPaySetupPage> createState() => _NfcPaySetupPageState();
}

class _NfcPaySetupPageState extends State<NfcPaySetupPage> {
  final _businessIdController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  WalletCard? _selectedCard;
  List<WalletCard> _cards = const [];
  String _currency = 'COP';
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBusinessId != null) {
      _businessIdController.text = '${widget.initialBusinessId}';
    }
    if (widget.initialBusinessName != null) {
      _businessNameController.text = widget.initialBusinessName!;
    }
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    _loadCards();
  }

  Future<void> _loadCards() async {
    final country = CountryRegistration.defaultCountryCode();
    final currency = CountryRegistration.currencyForCountry(country);
    final cardsResult = await getIt<WalletRepository>().cards();
    if (!mounted) return;
    cardsResult.when(
      success: (items) {
        WalletCard? selected;
        if (widget.initialWalletCardId != null) {
          selected = items
              .where((c) => c.id == widget.initialWalletCardId)
              .firstOrNull;
        }
        selected ??=
            items.where((c) => c.isPrimary).firstOrNull ?? items.firstOrNull;
        setState(() {
          _cards = items;
          _selectedCard = selected;
          _currency = selected?.currency.trim().isNotEmpty == true
              ? selected!.currency.toUpperCase()
              : currency;
          _loading = false;
        });
      },
      failure: (_) => setState(() => _loading = false),
    );
  }

  @override
  void dispose() {
    _businessIdController.dispose();
    _businessNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final businessId = int.tryParse(_businessIdController.text.trim());
    final businessName = _businessNameController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final description = _descriptionController.text.trim();
    final card = _selectedCard;

    if (businessId == null || businessId <= 0) {
      _showError('Ingresa un ID de comercio válido.');
      return;
    }
    if (businessName.isEmpty) {
      _showError('Ingresa el nombre del comercio como referencia.');
      return;
    }
    if (amount <= 0) {
      _showError('Ingresa un monto mayor a cero.');
      return;
    }
    if (card == null) {
      _showError('Selecciona un método de pago.');
      return;
    }
    if (!card.canSpend(amount)) {
      await showInsufficientBalanceDialog(
        context,
        amount: amount,
        currency: card.currency,
        businessId: businessId,
        description:
            'No tienes saldo suficiente en Wallet Ciervo. Recarga tu wallet o usa tarjeta de respaldo al aprobar una solicitud de pago.',
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await getIt<WalletRepository>().createNfcSession(
      walletCardId: card.id,
      businessId: businessId,
      amount: amount,
      currency: _currency,
      description: description.isEmpty ? 'Pago en $businessName' : description,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    await result.when(
      success: (session) async {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => NfcPaySessionPage(
              session: session,
              businessName: businessName.isEmpty
                  ? 'Comercio #$businessId'
                  : businessName,
            ),
          ),
        );
      },
      failure: (error) => handleNfcError(context, error),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _paymentMethodLabel(WalletCard card) {
    final kind = card.name.toLowerCase().contains('okbus')
        ? 'Tarjeta OKBuses'
        : card.isPrimary
        ? 'Wallet Ciervo'
        : card.name;
    return '$kind · ${DisplayFormatters.formatMoney(card.availableBalance, currency: card.currency)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago NFC CIERVO')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _submitting,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirma antes de acercar tu celular',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'El pago NFC se debita de tu wallet CIERVO. '
                            'La tarjeta de respaldo familiar solo aplica al aprobar solicitudes de pago.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _businessIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ID comercio',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre comercio (referencia)',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto ($_currency)',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion',
                        hintText: 'Ej: Almuerzo, entrada, producto',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_cards.isEmpty)
                      const Text('No hay métodos de pago disponibles.')
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCard?.id,
                        decoration: const InputDecoration(
                          labelText: 'Método de pago',
                          prefixIcon: Icon(Icons.credit_card_outlined),
                        ),
                        items: _cards
                            .map(
                              (card) => DropdownMenuItem(
                                value: card.id,
                                child: Text(_paymentMethodLabel(card)),
                              ),
                            )
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (value) => setState(
                                () => _selectedCard = _cards
                                    .where((c) => c.id == value)
                                    .firstOrNull,
                              ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: _submitting
                          ? 'Preparando NFC...'
                          : 'Activar pago NFC',
                      icon: Icons.nfc,
                      state: _submitting
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
