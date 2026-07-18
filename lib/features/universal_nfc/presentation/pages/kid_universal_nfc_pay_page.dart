import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/session/auth_token_claims.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../domain/entities/payment_quote.dart';
import '../../domain/entities/universal_nfc_payment.dart';
import '../../domain/repositories/universal_nfc_repository.dart';
import '../utils/nfc_payment_ui.dart';
import '../widgets/payment_quote_summary_card.dart';
import '../widgets/saved_payment_method_tile.dart';
import 'universal_nfc_session_page.dart';

enum _KidNfcStep { amount, summary }

/// Pago NFC Universal para cuenta Kids (wallet + aprobación tutor si aplica).
class KidUniversalNfcPayPage extends StatefulWidget {
  const KidUniversalNfcPayPage({
    required this.businessId,
    required this.businessName,
    this.merchantId,
    super.key,
  });

  final String businessId;
  final String businessName;
  final int? merchantId;

  @override
  State<KidUniversalNfcPayPage> createState() => _KidUniversalNfcPayPageState();
}

class _KidUniversalNfcPayPageState extends State<KidUniversalNfcPayPage> {
  final _nfcRepository = getIt<UniversalNfcRepository>();
  final _kidRepository = getIt<KidMeRepository>();
  final _amountController = TextEditingController();

  _KidNfcStep _step = _KidNfcStep.amount;
  PaymentQuote? _quote;
  static const _walletMethod = SavedPaymentMethod(
    id: 'wallet',
    type: 'wallet',
    brand: 'Ciervo',
    status: 'active',
    isDefault: true,
    isTokenized: false,
    displayName: 'Mi billetera Kids',
  );
  int? _childProfileId;
  String _currency = CountryRegistration.currencyForCountry(
    CountryRegistration.defaultCountryCode(),
  );
  String _country = CountryRegistration.defaultCountryCode();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amount =>
      double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), ''));

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    final token = await getIt<SessionManager>().accessToken();
    if (token != null) {
      _childProfileId = AuthTokenClaims.fromJwt(token).childProfileId;
    }

    final profileResult = await _kidRepository.profile();
    if (!mounted) return;
    profileResult.when(
      success: (profile) {
        _country = profile.countryCode.toUpperCase();
        _currency = CountryRegistration.currencyForCountry(_country);
        _childProfileId ??= int.tryParse(profile.childProfileId);
      },
      failure: (_) {},
    );

    if (!mounted) return;
    setState(() => _loading = false);
  }

  int? get _merchantId => widget.merchantId ?? int.tryParse(widget.businessId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con NFC'),
        leading: _step == _KidNfcStep.amount
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _loading ? null : _goBack,
              ),
      ),
      body: SafeArea(
        child: _loading && _step == _KidNfcStep.amount
            ? const CiervoLoadingState()
            : ListView(
                padding: pagePaddingOf(context),
                children: [
                  _heroHeader(context, isDark),
                  const SizedBox(height: AppSpacing.lg),
                  switch (_step) {
                    _KidNfcStep.amount => _amountStep(context),
                    _KidNfcStep.summary => _summaryStep(context),
                  },
                ],
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
                      widget.businessName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Acerca tu dispositivo al datáfono. Si tu tutor debe aprobar, te avisaremos.',
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
            CiervoCard(
              padding: EdgeInsets.zero,
              child: SavedPaymentMethodTile(
                method: _walletMethod,
                selected: true,
                onTap: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
              state: _loading
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _loading ? null : _loadQuote,
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
              subtitle: widget.businessName,
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
                label: 'Pedir a mi tutor',
                variant: CiervoButtonVariant.secondary,
                icon: Icons.family_restroom_outlined,
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
      _step = _KidNfcStep.amount;
    });
  }

  Future<void> _loadQuote() async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _nfcRepository.nfcQuote(
      amount: amount,
      currency: _currency,
      paymentMethodId: _walletMethod.id,
      childProfileId: _childProfileId,
    );

    if (!mounted) return;
    result.when(
      success: (quote) => setState(() {
        _quote = quote;
        _currency = quote.currency;
        _step = _KidNfcStep.summary;
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
    if (amount == null || amount <= 0) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _nfcRepository.createIntent(
      amount: amount,
      currency: _currency,
      paymentMethodId: _walletMethod.id,
      merchantName: widget.businessName,
      merchantId: _merchantId,
      childProfileId: _childProfileId,
      idempotencyKey: IdempotencyKey.generate('kid-universal-nfc'),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    await result.when(
      success: (payment) async {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => UniversalNfcSessionPage(
              payment: payment,
              merchantLabel: widget.businessName,
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
