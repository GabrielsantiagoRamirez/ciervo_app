import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/currency_selector.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';

enum _PayerLookupMode { ciervoId, atHandle }

enum _PayWithMethod { digitalCard, physicalCard, pin, atHandle }

class RequestMoneyPage extends StatefulWidget {
  const RequestMoneyPage({
    this.initialPayerCiervoCode,
    this.chatConversationId,
    this.businessId,
    this.bookingId,
    this.initialAmount,
    this.initialCurrency,
    this.payerOptional = false,
    super.key,
  });

  final String? initialPayerCiervoCode;
  final String? chatConversationId;
  final int? businessId;
  final int? bookingId;
  final double? initialAmount;
  final String? initialCurrency;
  final bool payerOptional;

  @override
  State<RequestMoneyPage> createState() => _RequestMoneyPageState();
}

class _RequestMoneyPageState extends State<RequestMoneyPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _currency = CountryRegistration.currencyForCountry(
    CountryRegistration.defaultCountryCode(),
  );
  _PayerLookupMode _lookupMode = _PayerLookupMode.ciervoId;
  _PayWithMethod _payWith = _PayWithMethod.digitalCard;

  @override
  void initState() {
    super.initState();
    if (widget.initialPayerCiervoCode != null) {
      _codeController.text = widget.initialPayerCiervoCode!;
      if (widget.initialPayerCiervoCode!.trim().startsWith('@')) {
        _lookupMode = _PayerLookupMode.atHandle;
      }
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
    if (widget.initialCurrency != null && widget.initialCurrency!.isNotEmpty) {
      _currency = widget.initialCurrency!;
    } else {
      _resolveCurrencyFromProfile();
    }
    if (widget.bookingId != null) {
      _descriptionController.text =
          '¿Me ayudas con esta reserva #${widget.bookingId}?';
    }
  }

  Future<void> _resolveCurrencyFromProfile() async {
    final result = await getIt<ProfileRepository>().getMe();
    if (!mounted) return;
    result.when(
      success: (profile) {
        final country = (profile.countryCode ?? '').trim();
        if (country.isEmpty) return;
        setState(() {
          _currency = CountryRegistration.currencyForCountry(country);
        });
      },
      failure: (_) {},
    );
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
      child: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          final message = state.errorMessage ?? state.successMessage;
          if (message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final canSubmit = _canSubmit(state);
          return Scaffold(
            appBar: AppBar(title: const Text('Pinduck')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CiervoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.payerOptional) ...[
                      Text(
                        'Tu tutor recibirá la solicitud en el chat familiar.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ] else ...[
                      Text(
                        'Quién paga',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Usa CIERVO ID (CIERVO-XXXX) o @usuario del cliente.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<_PayerLookupMode>(
                        segments: const [
                          ButtonSegment(
                            value: _PayerLookupMode.ciervoId,
                            label: Text('CIERVO ID'),
                            icon: Icon(Icons.badge_outlined),
                          ),
                          ButtonSegment(
                            value: _PayerLookupMode.atHandle,
                            label: Text('@usuario'),
                            icon: Icon(Icons.alternate_email),
                          ),
                        ],
                        selected: {_lookupMode},
                        onSelectionChanged: (value) {
                          setState(() => _lookupMode = value.first);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: _lookupMode == _PayerLookupMode.atHandle
                              ? '@usuario'
                              : 'CIERVO-XXXXXXXX',
                          prefixIcon: Icon(
                            _lookupMode == _PayerLookupMode.atHandle
                                ? Icons.alternate_email
                                : Icons.badge_outlined,
                          ),
                          helperText:
                              'Debajo del CIERVO ID: identifica quién paga.',
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
                            .resolveUser(_normalizePayerQuery()),
                      ),
                      if (state.resolvedUser != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Pagador: ${state.resolvedUser!.displayName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Método de cobro preferido',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ChoiceChip(
                          selected: _payWith == _PayWithMethod.digitalCard,
                          label: const Text('Tarjeta digital'),
                          avatar: const Icon(Icons.credit_card, size: 18),
                          onSelected: (_) => setState(
                            () => _payWith = _PayWithMethod.digitalCard,
                          ),
                        ),
                        ChoiceChip(
                          selected: _payWith == _PayWithMethod.physicalCard,
                          label: const Text('Tarjeta física'),
                          avatar: const Icon(Icons.nfc, size: 18),
                          onSelected: (_) => setState(
                            () => _payWith = _PayWithMethod.physicalCard,
                          ),
                        ),
                        ChoiceChip(
                          selected: _payWith == _PayWithMethod.pin,
                          label: const Text('PIN'),
                          avatar: const Icon(Icons.password, size: 18),
                          onSelected: (_) =>
                              setState(() => _payWith = _PayWithMethod.pin),
                        ),
                        ChoiceChip(
                          selected: _payWith == _PayWithMethod.atHandle,
                          label: const Text('@'),
                          avatar: const Icon(Icons.alternate_email, size: 18),
                          onSelected: (_) => setState(
                            () => _payWith = _PayWithMethod.atHandle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Monto',
                        prefixIcon: const Icon(Icons.attach_money),
                        helperText:
                            'Ejemplo: ${DisplayFormatters.formatMoney(20000, currency: _currency)}',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CurrencySelector(
                      value: _currency,
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Descripción',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: state.isLoading ? 'Enviando' : 'Enviar solicitud',
                      icon: Icons.outgoing_mail,
                      state: state.isLoading
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: canSubmit
                          ? () => _submit(context, state)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _normalizePayerQuery() {
    final raw = _codeController.text.trim();
    if (_lookupMode == _PayerLookupMode.atHandle) {
      if (raw.isEmpty) return raw;
      return raw.startsWith('@') ? raw : '@$raw';
    }
    return raw;
  }

  bool _canSubmit(WalletState state) {
    if (state.isLoading) return false;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return false;
    if (widget.payerOptional) return true;
    final code = _normalizePayerQuery();
    return code.isNotEmpty || state.resolvedUser != null;
  }

  void _submit(BuildContext context, WalletState state) {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final code = _normalizePayerQuery();
    final payer = state.resolvedUser;
    if (amount <= 0 ||
        (!widget.payerOptional && code.isEmpty && payer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.payerOptional
                ? 'Ingresa un monto válido.'
                : 'Ingresa CIERVO ID o @usuario y un monto válido.',
          ),
        ),
      );
      return;
    }
    final methodApi = switch (_payWith) {
      _PayWithMethod.digitalCard => 'digital_card',
      _PayWithMethod.physicalCard => 'physical_card',
      _PayWithMethod.pin => 'pin',
      _PayWithMethod.atHandle => 'at_handle',
    };
    final baseDescription = _descriptionController.text.trim().isEmpty
        ? 'Solicitud de pago'
        : _descriptionController.text.trim();
    context.read<WalletCubit>().requestMoney(
      payerUserId: payer?.userId,
      payerCiervoUserCode: code.isNotEmpty ? code : payer?.ciervoUserCode,
      amount: amount,
      description: baseDescription,
      chatConversationId: widget.chatConversationId,
      businessId: widget.businessId,
      bookingId: widget.bookingId,
      currency: _currency,
      preferredPaymentMethod: methodApi,
    );
  }
}

/// Preview de solicitudes recibidas con acciones rapidas.
class PendingPaymentRequestTile extends StatelessWidget {
  const PendingPaymentRequestTile({required this.request, super.key});

  final PaymentRequest request;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.request_page_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  request.description.isEmpty
                      ? 'Solicitud ${request.status}'
                      : request.description,
                ),
              ),
              Text(
                DisplayFormatters.formatMoney(
                  request.amount,
                  currency: request.currency,
                ),
              ),
            ],
          ),
          if (request.isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: () => context
                      .read<WalletCubit>()
                      .approvePaymentRequest(request.id),
                  child: const Text('Aprobar'),
                ),
                OutlinedButton(
                  onPressed: () => _reject(context),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Motivo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    context.read<WalletCubit>().rejectPaymentRequest(request.id, reason);
  }
}
