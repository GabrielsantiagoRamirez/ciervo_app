import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../data/services/mercado_pago_card_tokenizer.dart';
import '../../domain/repositories/family_payments_repository.dart';
import '../cubit/family_payment_methods_cubit.dart';
import 'mercado_pago_3ds_page.dart';

enum _AddCardStep { form, validating, authenticating, success, error }

class AddFamilyCardPage extends StatefulWidget {
  const AddFamilyCardPage({super.key});

  @override
  State<AddFamilyCardPage> createState() => _AddFamilyCardPageState();
}

class _AddFamilyCardPageState extends State<AddFamilyCardPage> {
  final _numberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _documentController = TextEditingController();
  _AddCardStep _step = _AddCardStep.form;
  String? _error;

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

  Future<void> _submit() async {
    setState(() {
      _step = _AddCardStep.validating;
      _error = null;
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
        failure: (error) => throw MercadoPagoTokenizationException(
          'No pudimos obtener la configuración de Mercado Pago.',
        ),
      );

      final month = int.tryParse(_monthController.text.trim());
      final year = int.tryParse(_yearController.text.trim());
      if (month == null || year == null) {
        throw MercadoPagoTokenizationException('Fecha de expiración inválida.');
      }

      final cardToken = await getIt<MercadoPagoCardTokenizer>().createCardToken(
        publicKey: publicKey,
        cardNumber: _numberController.text,
        securityCode: _cvvController.text,
        expirationMonth: month,
        expirationYear: year,
        cardholderName: _nameController.text,
        identificationType: 'CC',
        identificationNumber: _documentController.text.trim(),
      );

      if (!mounted) return;
      final cubit = context.read<FamilyPaymentMethodsCubit>();
      final flow = await cubit.addCard(
        cardToken: cardToken,
        alias: _aliasController.text.trim().isEmpty
            ? null
            : _aliasController.text.trim(),
      );

      if (flow.requires3ds) {
        setState(() => _step = _AddCardStep.authenticating);
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => MercadoPago3dsPage(
              cardId: flow.cardId,
              verificationUrl: flow.verificationUrl,
            ),
          ),
        );
        if (verified != true) {
          setState(() {
            _step = _AddCardStep.error;
            _error = 'No se completó la autenticación 3DS.';
          });
          return;
        }
      } else {
        final verified = await cubit.verifyCard(flow.cardId);
        if (!verified) {
          setState(() {
            _step = _AddCardStep.error;
            _error = 'No pudimos validar la tarjeta.';
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() => _step = _AddCardStep.success);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _step = _AddCardStep.error;
        _error = MercadoPagoTokenizationException.fromObject(error).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FamilyPaymentMethodsCubit(getIt<FamilyPaymentsRepository>()),
      child: Scaffold(
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
      ),
    );
  }

  Widget _formView(BuildContext context) {
    return SingleChildScrollView(
      padding: pagePaddingOf(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
          child: CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tus datos se tokenizan con Mercado Pago. CIERVO nunca recibe el número completo ni el CVV.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _aliasController,
                  decoration: const InputDecoration(
                    labelText: 'Alias (opcional)',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Número de tarjeta',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _monthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mes'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Año'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _cvvController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'CVV'),
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
                TextField(
                  controller: _documentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Documento del titular',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: 'Agregar tarjeta',
                  icon: Icons.lock_outline,
                  onPressed: _submit,
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
            Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text('Error', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(_error ?? 'No pudimos agregar la tarjeta.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              onPressed: () => setState(() => _step = _AddCardStep.form),
            ),
          ],
        ),
      ),
    );
  }
}
