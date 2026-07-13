import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../domain/entities/payment_quote.dart';
import '../../domain/entities/universal_nfc_payment.dart';
import '../../domain/repositories/universal_nfc_repository.dart';
import '../utils/nfc_payment_ui.dart';
import '../widgets/payment_quote_summary_card.dart';
import '../widgets/saved_payment_method_tile.dart';
import 'universal_nfc_session_page.dart';

enum _UniversalNfcStep { amount, methods, summary }

class UniversalNfcPayPage extends StatefulWidget {
  const UniversalNfcPayPage({super.key});

  @override
  State<UniversalNfcPayPage> createState() => _UniversalNfcPayPageState();
}

class _UniversalNfcPayPageState extends State<UniversalNfcPayPage> {
  final _repository = getIt<UniversalNfcRepository>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();

  _UniversalNfcStep _step = _UniversalNfcStep.amount;
  List<SavedPaymentMethod> _methods = const [];
  SavedPaymentMethod? _selectedMethod;
  PaymentQuote? _quote;
  bool _loading = false;
  String? _error;
  String _currency = CountryRegistration.currencyForCountry(
    CountryRegistration.defaultCountryCode(),
  );

  @override
  void initState() {
    super.initState();
    _resolveCurrency();
  }

  Future<void> _resolveCurrency() async {
    try {
      final config = await getIt<PaymentsRepository>().config();
      if (!mounted) return;
      config.when(
        success: (value) {
          final currency = value.currency.trim().toUpperCase();
          if (currency.isNotEmpty) {
            setState(() => _currency = currency);
          }
        },
        failure: (_) {},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  double? get _amount =>
      double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), ''));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con NFC'),
        leading: _step == _UniversalNfcStep.amount
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _loading ? null : _goBack,
              ),
      ),
      body: SafeArea(
        child: _loading && _step != _UniversalNfcStep.summary
            ? const CiervoLoadingState()
            : RefreshIndicator(
                onRefresh: _step == _UniversalNfcStep.methods
                    ? _loadMethods
                    : () async {},
                child: ListView(
                  padding: pagePaddingOf(context),
                  children: [
                    _heroHeader(context, isDark),
                    const SizedBox(height: AppSpacing.lg),
                    switch (_step) {
                      _UniversalNfcStep.amount => _amountStep(context),
                      _UniversalNfcStep.methods => _methodsStep(context),
                      _UniversalNfcStep.summary => _summaryStep(context),
                    },
                  ],
                ),
              ),
      ),
    );
  }

  Widget _heroHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final accent = isDark ? AppColors.primary : theme.colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
        child: CiervoCard(
          showGradientOverlay: isDark,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.nfc, size: 36, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFC Universal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ingresa el monto del datáfono y paga con tu medio Ciervo '
                      '(wallet o tarjeta tokenizada, p. ej. Cuenta RUT Visa). '
                      'Funciona aunque el comercio no esté en Ciervo.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountStep(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                suffixText: _currency,
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Comercio (opcional)',
                prefixIcon: Icon(Icons.storefront_outlined),
                helperText: 'Referencia para tu historial.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            CiervoButton(
              label: 'Continuar',
              icon: Icons.arrow_forward,
              onPressed: _continueToMethods,
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodsStep(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return CiervoErrorState(
        title: 'No pudimos cargar métodos de pago',
        description: _error!,
        onRetry: _loadMethods,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Método de pago', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (_methods.isEmpty)
              const CiervoCard(
                child: Text(
                  'No hay métodos disponibles. Recarga tu wallet o agrega una tarjeta.',
                ),
              )
            else
              CiervoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _methods
                      .map(
                        (method) => SavedPaymentMethodTile(
                          method: method,
                          selected: _selectedMethod?.id == method.id,
                          onTap: () => setState(() => _selectedMethod = method),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            CiervoButton(
              label: 'Ver resumen',
              icon: Icons.receipt_long_outlined,
              state: _loading
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _methods.isEmpty || _loading ? null : _loadQuote,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStep(BuildContext context) {
    final quote = _quote;
    if (quote == null) {
      return const CiervoLoadingState(itemCount: 2);
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaymentQuoteSummaryCard(
              quote: quote,
              subtitle: _merchantController.text.trim().isEmpty
                  ? null
                  : _merchantController.text.trim(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            CiervoButton(
              label: _loading ? 'Preparando NFC...' : 'Confirmar y pagar',
              icon: Icons.nfc,
              state: _loading
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: !quote.sufficientFunds || _loading
                  ? null
                  : _createIntent,
            ),
            if (!quote.sufficientFunds) ...[
              const SizedBox(height: AppSpacing.sm),
              CiervoButton(
                label: 'Ir a recargar wallet',
                variant: CiervoButtonVariant.secondary,
                icon: Icons.account_balance_wallet_outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _goBack() {
    setState(() {
      _error = null;
      _step = switch (_step) {
        _UniversalNfcStep.summary => _UniversalNfcStep.methods,
        _UniversalNfcStep.methods => _UniversalNfcStep.amount,
        _ => _UniversalNfcStep.amount,
      };
    });
  }

  Future<void> _continueToMethods() async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }
    setState(() {
      _error = null;
      _step = _UniversalNfcStep.methods;
    });
    await _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.paymentMethods();
    if (!mounted) return;
    result.when(
      success: (methods) {
        final active = methods.where((m) => m.isActive).toList();
        setState(() {
          _methods = active;
          _selectedMethod =
              active.where((m) => m.isDefault).firstOrNull ??
              active.firstOrNull;
          _loading = false;
        });
      },
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _loadQuote() async {
    final amount = _amount;
    final method = _selectedMethod;
    if (amount == null || amount <= 0 || method == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _repository.nfcQuote(
      amount: amount,
      currency: _currency,
      paymentMethodId: method.id,
    );

    if (!mounted) return;
    result.when(
      success: (quote) => setState(() {
        _quote = quote;
        _currency = quote.currency;
        _step = _UniversalNfcStep.summary;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _createIntent() async {
    final amount = _amount;
    final method = _selectedMethod;
    if (amount == null || amount <= 0 || method == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final merchant = _merchantController.text.trim();
    final result = await _repository.createIntent(
      amount: amount,
      currency: _currency,
      paymentMethodId: method.id,
      merchantName: merchant.isEmpty ? null : merchant,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    await result.when(
      success: (payment) async {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => UniversalNfcSessionPage(
              payment: payment,
              merchantLabel: merchant.isEmpty ? 'Comercio' : merchant,
            ),
          ),
        );
      },
      failure: (error) {
        final message = UserErrorMessage.from(error);
        if (message.toLowerCase().contains('nfc') ||
            message.toLowerCase().contains('plan')) {
          setState(
            () => _error = NfcPaymentUi.rejectReasonMessage('NfcNotAvailable'),
          );
        } else {
          setState(() => _error = message);
        }
      },
    );
  }
}
