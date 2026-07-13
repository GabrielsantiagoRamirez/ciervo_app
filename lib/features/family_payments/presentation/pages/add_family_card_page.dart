import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/card_validator.dart';
import '../../../../core/utils/card_brand_detector.dart';
import '../../../../shared/widgets/card_number_field.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../data/services/mercado_pago_card_tokenizer.dart';
import '../../domain/repositories/family_payments_repository.dart';
import '../cubit/family_payment_methods_cubit.dart';
import 'mercado_pago_3ds_page.dart';

enum _AddCardStep { form, validating, authenticating, success, error }

class AddFamilyCardPage extends StatelessWidget {
  const AddFamilyCardPage({this.cubit, super.key});

  final FamilyPaymentMethodsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final view = const _AddFamilyCardView();
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: view);
    }
    return BlocProvider(
      create: (_) =>
          FamilyPaymentMethodsCubit(getIt<FamilyPaymentsRepository>()),
      child: view,
    );
  }
}

class _AddFamilyCardView extends StatefulWidget {
  const _AddFamilyCardView();

  @override
  State<_AddFamilyCardView> createState() => _AddFamilyCardViewState();
}

class _AddFamilyCardViewState extends State<_AddFamilyCardView> {
  final _numberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _documentController = TextEditingController();
  _AddCardStep _step = _AddCardStep.form;
  String? _error;
  bool _submitting = false;
  bool _obscureCvv = false;
  String _countryCode = CountryRegistration.defaultCountryCode();
  late String _identificationType =
      CountryRegistration.mercadoPagoIdentificationType(_countryCode);
  bool _resolvingCountry = true;

  @override
  void initState() {
    super.initState();
    _resolvePaymentCountry();
  }

  Future<void> _resolvePaymentCountry() async {
    try {
      final configResult = await getIt<PaymentsRepository>().config();
      final fromConfig = configResult.when(
        success: (config) =>
            CountryRegistration.countryCodeFromCurrency(config.currency),
        failure: (_) => null,
      );
      if (!mounted) return;
      final resolved = fromConfig ?? CountryRegistration.defaultCountryCode();
      setState(() {
        _countryCode = resolved;
        _identificationType =
            CountryRegistration.mercadoPagoIdentificationType(resolved);
        _resolvingCountry = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingCountry = false);
    }
  }

  void _onCountryChanged(String countryCode) {
    setState(() {
      _countryCode = countryCode;
      _identificationType =
          CountryRegistration.mercadoPagoIdentificationType(countryCode);
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _aliasController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  String? _validateForm() {
    final numberError = CardValidator.validateCardNumber(
      _numberController.text,
    );
    if (numberError != null) return numberError;
    try {
      MercadoPagoCardExpiration.parse(
        _monthController.text,
        _yearController.text,
      );
    } catch (error) {
      return MercadoPagoTokenizationException.fromObject(error).message;
    }
    final cvvError = CardValidator.validateCvv(_cvvController.text);
    if (cvvError != null) return cvvError;
    final nameError = CardValidator.validateHolderName(_nameController.text);
    if (nameError != null) return nameError;
    if (_documentController.text.trim().isEmpty) {
      return 'Ingresa el documento del titular.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final validationError = _validateForm();
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() {
      _step = _AddCardStep.validating;
      _error = null;
      _submitting = true;
    });

    try {
      final configResult = await getIt<PaymentsRepository>().config();
      final publicKey = configResult.when(
        success: (config) {
          if (!config.enabled) {
            throw MercadoPagoTokenizationException(
              'Mercado Pago no está habilitado en este momento.',
            );
          }
          return config.publicKey;
        },
        failure: (_) => throw MercadoPagoTokenizationException(
          'No pudimos obtener la configuración de Mercado Pago.',
        ),
      );

      final expiration = MercadoPagoCardExpiration.parse(
        _monthController.text,
        _yearController.text,
      );

      final cardToken = await getIt<MercadoPagoCardTokenizer>().createCardToken(
        publicKey: publicKey,
        cardNumber: _numberController.text,
        securityCode: _cvvController.text,
        expirationMonth: expiration.month,
        expirationYear: expiration.year,
        cardholderName: _nameController.text,
        identificationType: _identificationType,
        identificationNumber: _documentController.text.trim(),
      );

      if (!mounted) return;
      final cubit = context.read<FamilyPaymentMethodsCubit>();
      final digits = _numberController.text.replaceAll(RegExp(r'\D'), '');
      final brand = CardBrandDetector.apiBrandCode(
        CardBrandDetector.detect(digits),
      );
      final last4 = digits.length >= 4
          ? digits.substring(digits.length - 4)
          : digits;

      final flow = await cubit.addCard(
        cardToken: cardToken,
        brand: brand,
        last4: last4,
        expiryMonth: expiration.month,
        expiryYear: expiration.year,
        holderName: _nameController.text.trim(),
        alias: _aliasController.text.trim().isEmpty
            ? null
            : _aliasController.text.trim(),
      );

      if (flow.cardId.isEmpty) {
        throw MercadoPagoTokenizationException(
          'La tarjeta se procesó pero no recibimos confirmación del servidor. '
          'Revisa Métodos de pago en unos segundos.',
        );
      }

      if (flow.requires3ds) {
        setState(() => _step = _AddCardStep.authenticating);
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: MercadoPago3dsPage(
                cardId: flow.cardId,
                verificationUrl: flow.verificationUrl,
              ),
            ),
          ),
        );
        if (verified != true) {
          setState(() {
            _step = _AddCardStep.error;
            _error =
                cubit.state.errorMessage ??
                'No se completó la autenticación 3DS.';
            _submitting = false;
          });
          return;
        }
      } else {
        final verified = await cubit.verifyCard(flow.cardId);
        if (!verified) {
          setState(() {
            _step = _AddCardStep.error;
            _error =
                cubit.state.errorMessage ?? 'No pudimos validar la tarjeta.';
            _submitting = false;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _step = _AddCardStep.success;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarjeta registrada correctamente.')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _step = _AddCardStep.error;
        _error = MercadoPagoTokenizationException.fromObject(error).message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar tarjeta')),
      body: switch (_step) {
        _AddCardStep.validating => _statusView(
          context,
          title: 'Validando...',
          subtitle: 'Estamos verificando tu tarjeta de forma segura.',
        ),
        _AddCardStep.authenticating => _statusView(
          context,
          title: 'Autenticando...',
          subtitle: 'Completa la verificación de tu banco.',
        ),
        _AddCardStep.success => _statusView(
          context,
          title: 'Tarjeta agregada',
          subtitle: 'Tu tarjeta quedó lista para pagos familiares.',
          success: true,
        ),
        _AddCardStep.error => _errorView(context),
        _ => _formView(context),
      },
    );
  }

  Widget _formView(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: pagePaddingOf(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
          child: CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tus datos se tokenizan con Mercado Pago según el país de tu cuenta. '
                  'CIERVO nunca recibe el número completo ni el CVV.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  key: ValueKey('country-$_countryCode'),
                  initialValue: _countryCode,
                  decoration: const InputDecoration(
                    labelText: 'País de la tarjeta / Mercado Pago',
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: CountryRegistration.paymentCountryCodes
                      .map(
                        (code) => DropdownMenuItem(
                          value: code,
                          child: Text(
                            '${CountryRegistration.countryLabel(code)} '
                            '(${CountryRegistration.currencyForCountry(code)})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _resolvingCountry || _submitting
                      ? null
                      : (value) {
                          if (value != null) _onCountryChanged(value);
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _aliasController,
                  decoration: const InputDecoration(
                    labelText: 'Alias (opcional)',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CardNumberField(controller: _numberController),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _monthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Mes (MM)',
                          hintText: 'MM',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Año (AA)',
                          hintText: 'AA',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _cvvController,
                        obscureText: _obscureCvv,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          suffixIcon: IconButton(
                            tooltip: _obscureCvv
                                ? 'Mostrar CVV'
                                : 'Ocultar CVV',
                            onPressed: () =>
                                setState(() => _obscureCvv = !_obscureCvv),
                            icon: Icon(
                              _obscureCvv
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del titular',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  key: ValueKey('doc-$_countryCode-$_identificationType'),
                  initialValue: _identificationType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de documento',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: CountryRegistration.adultDocumentOptions(_countryCode)
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.code,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _identificationType = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _documentController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Documento del titular',
                    prefixIcon: const Icon(Icons.numbers_outlined),
                    helperText: CountryRegistration.documentHelperText(
                      _countryCode,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: 'Agregar tarjeta',
                  icon: Icons.lock_outline,
                  state: _submitting
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusView(
    BuildContext context, {
    required String title,
    required String subtitle,
    bool success = false,
  }) {
    return Center(
      child: Padding(
        padding: pagePaddingOf(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.hourglass_top,
              size: 56,
              color: success
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle, textAlign: TextAlign.center),
            if (!success) ...[
              const SizedBox(height: AppSpacing.lg),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: pagePaddingOf(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No pudimos agregar la tarjeta',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Intenta nuevamente en unos segundos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              onPressed: () => setState(() {
                _step = _AddCardStep.form;
                _error = null;
                _submitting = false;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
