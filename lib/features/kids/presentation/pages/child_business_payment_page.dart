// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../family_payments/data/dtos/family_payment_dtos.dart';
import '../../../family_payments/presentation/pages/family_payment_navigation.dart';
import '../../../receipts/domain/entities/action_confirmation.dart';
import '../../../receipts/presentation/pages/action_confirmation_page.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/kids_repository.dart';

class ChildBusinessPaymentPage extends StatefulWidget {
  const ChildBusinessPaymentPage({required this.childId, super.key});

  final String childId;

  @override
  State<ChildBusinessPaymentPage> createState() =>
      _ChildBusinessPaymentPageState();
}

class _ChildBusinessPaymentPageState extends State<ChildBusinessPaymentPage> {
  final _repository = getIt<KidsRepository>();
  final _amountController = TextEditingController();

  ChildProfile? _child;
  List<Map<String, dynamic>> _businesses = const [];
  List<Map<String, dynamic>> _cards = const [];
  Map<String, dynamic>? _limits;
  Map<String, dynamic>? _wallet;
  String? _selectedBusinessId;
  String? _selectedCardId;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final childResult = await _repository.child(widget.childId);
    final businessesResult = await _repository.allowedBusinesses(widget.childId);
    final limitsResult = await _repository.spendingLimits(widget.childId);
    final walletResult = await _repository.childWallet(widget.childId);
    final cardsResult = await _repository.childWalletCards(widget.childId);

    if (!mounted) return;

    String? error;
    childResult.when(
      success: (value) => _child = value,
      failure: (e) => error = UserErrorMessage.from(e),
    );
    businessesResult.when(
      success: (items) {
        _businesses = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where(_isAllowedBusiness)
            .toList();
      },
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    limitsResult.when(
      success: (value) => _limits = value,
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    walletResult.when(
      success: (value) => _wallet = value,
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    cardsResult.when(
      success: (items) {
        _cards = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _selectedCardId ??= _primaryCardId(_cards);
      },
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    _selectedBusinessId ??=
        _businesses.isNotEmpty ? _businessId(_businesses.first) : null;

    setState(() {
      _loading = false;
      _error = error;
    });
  }

  bool _isAllowedBusiness(Map<String, dynamic> item) {
    final allowed = item['isAllowed'];
    if (allowed is bool) return allowed;
    return true;
  }

  String _businessId(Map<String, dynamic> item) =>
      (item['businessId'] ?? item['id'] ?? '').toString();

  String _businessName(Map<String, dynamic> item) =>
      (item['name'] ?? item['displayName'] ?? 'Comercio').toString();

  String? _primaryCardId(List<Map<String, dynamic>> cards) {
    for (final card in cards) {
      if (card['isPrimary'] == true || card['primary'] == true) {
        return (card['id'] ?? card['cardId']).toString();
      }
    }
    if (cards.isEmpty) return null;
    return (cards.first['id'] ?? cards.first['cardId']).toString();
  }

  Map<String, dynamic>? get _selectedCard {
    if (_selectedCardId == null) return null;
    for (final card in _cards) {
      if ('${card['id'] ?? card['cardId']}' == _selectedCardId) return card;
    }
    return null;
  }

  double get _availableBalance {
    final card = _selectedCard;
    if (card != null) {
      return _num(
        card['availableBalance'] ?? card['balance'],
      );
    }
    return _num(_wallet?['availableBalance'] ?? _wallet?['balance']);
  }

  String? _validatePayment(double amount) {
    if (_selectedBusinessId == null || _selectedBusinessId!.isEmpty) {
      return 'Selecciona un comercio permitido.';
    }
    if (amount <= 0) return 'Ingresa un monto valido.';
    if (_businesses.every((b) => _businessId(b) != _selectedBusinessId)) {
      return 'Este comercio no esta permitido para el menor.';
    }
    if (_availableBalance < amount) {
      return 'Saldo disponible insuficiente (COP ${_availableBalance.toStringAsFixed(0)}).';
    }
    final daily = _num(_limits?['dailyLimit'] ?? _limits?['daily']);
    final weekly = _num(_limits?['weeklyLimit'] ?? _limits?['weekly']);
    final monthly = _num(_limits?['monthlyLimit'] ?? _limits?['monthly']);
    if (daily > 0 && amount > daily) {
      return 'Supera el limite diario (COP ${daily.toStringAsFixed(0)}).';
    }
    if (weekly > 0 && amount > weekly) {
      return 'Supera el limite semanal (COP ${weekly.toStringAsFixed(0)}).';
    }
    if (monthly > 0 && amount > monthly) {
      return 'Supera el limite mensual (COP ${monthly.toStringAsFixed(0)}).';
    }
    return null;
  }

  Future<void> _pay() async {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto valido.')),
      );
      return;
    }
    final validation = _validatePayment(amount);
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation)),
      );
      return;
    }

    final business = _businesses.firstWhere(
      (item) => _businessId(item) == _selectedBusinessId,
    );
    final businessName = _businessName(business);
    final childName = _child?.fullName ?? 'Menor';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Text(
          'Pagar COP ${amount.toStringAsFixed(0)} en $businessName con la wallet de $childName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar pago'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _paying = true);
    final idempotencyKey =
        'kids-pay-${widget.childId}-$_selectedBusinessId-${DateTime.now().microsecondsSinceEpoch}';
    final result = await _repository.payKidsBusiness(
      childProfileId: widget.childId,
      businessId: _selectedBusinessId!,
      amount: amount,
      walletCardId: _selectedCardId,
      idempotencyKey: idempotencyKey,
    );
    if (!mounted) return;
    setState(() => _paying = false);

    await result.when(
      success: (payload) async {
        final detail = FamilyPaymentRecordDto.fromJson(payload).toDetailDomain();
        if (detail.usedParentCard) {
          await showFamilyPaymentResultDialog(context, payment: detail);
          if (mounted) _load();
          return;
        }
        final confirmation = ActionConfirmation.fromJson(
          payload,
          fallbackTitle: 'Pago Kids confirmado',
          fallbackCode: payload['paymentId']?.toString() ??
              payload['transactionId']?.toString() ??
              payload['id']?.toString(),
        );
        final userCode = confirmation.userCiervoCode ??
            await resolveCurrentCiervoUserCode();
        if (!mounted) return;
        await showCiervoPaymentReceipt(
          context,
          confirmation: ActionConfirmation(
            title: confirmation.title,
            confirmationCode: confirmation.confirmationCode,
            userCiervoCode: userCode,
            businessName: confirmation.businessName ?? businessName,
            amount: confirmation.amount ?? amount,
            currency: confirmation.currency ?? 'COP',
            status: confirmation.status ?? 'Completado',
            publicReceiptUrl: confirmation.publicReceiptUrl ??
                payload['receiptUrl']?.toString() ??
                payload['publicReceiptUrl']?.toString(),
            shareDescription:
                'Pago realizado con la wallet Kids de $childName.',
          ),
          referenceLabel: 'Comercio',
          referenceValue: businessName,
        );
        if (mounted) _load();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago en comercio')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [CiervoLoadingState(itemCount: 4)],
              )
            : _error != null && _child == null
            ? ListView(
                padding: pagePaddingOf(context),
                children: [
                  CiervoErrorState(
                    title: 'No pudimos cargar el pago',
                    description: _error!,
                    onRetry: _load,
                  ),
                ],
              )
            : ListView(
                padding: pagePaddingOf(context),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxContentWidthOf(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CiervoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _child?.fullName ?? 'Menor',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Saldo disponible: COP ${_availableBalance.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: AppColors.primary),
                                ),
                                if (_num(_wallet?['heldBalance']) > 0)
                                  Text(
                                    'Retenido: COP ${_num(_wallet?['heldBalance']).toStringAsFixed(0)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_limits != null &&
                              (_num(_limits?['dailyLimit']) > 0 ||
                                  _num(_limits?['weeklyLimit']) > 0 ||
                                  _num(_limits?['monthlyLimit']) > 0))
                            CiervoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Límites de gasto',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  if (_num(_limits?['dailyLimit']) > 0)
                                    Text(
                                      'Diario: COP ${_num(_limits?['dailyLimit']).toStringAsFixed(0)}',
                                    ),
                                  if (_num(_limits?['weeklyLimit']) > 0)
                                    Text(
                                      'Semanal: COP ${_num(_limits?['weeklyLimit']).toStringAsFixed(0)}',
                                    ),
                                  if (_num(_limits?['monthlyLimit']) > 0)
                                    Text(
                                      'Mensual: COP ${_num(_limits?['monthlyLimit']).toStringAsFixed(0)}',
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          if (_businesses.isEmpty)
                            const CiervoEmptyState(
                              title: 'Sin comercios permitidos',
                              description:
                                  'Configura comercios permitidos antes de pagar.',
                              icon: Icons.storefront_outlined,
                            )
                          else ...[
                            CiervoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Comercio permitido',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  DropdownButtonFormField<String>(
                                    value: _selectedBusinessId,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.store_outlined),
                                      hintText: 'Selecciona comercio',
                                    ),
                                    items: _businesses
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: _businessId(item),
                                            child: Text(_businessName(item)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _paying
                                        ? null
                                        : (value) => setState(
                                              () => _selectedBusinessId = value,
                                            ),
                                  ),
                                  if (_cards.length > 1) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'Tarjeta Kids',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    DropdownButtonFormField<String>(
                                      value: _selectedCardId,
                                      decoration: const InputDecoration(
                                        prefixIcon:
                                            Icon(Icons.credit_card_outlined),
                                      ),
                                      items: _cards
                                          .map(
                                            (card) => DropdownMenuItem(
                                              value:
                                                  '${card['id'] ?? card['cardId']}',
                                              child: Text(
                                                '${card['displayName'] ?? 'Tarjeta Kids'} · COP ${_num(card['availableBalance'] ?? card['balance']).toStringAsFixed(0)}',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _paying
                                          ? null
                                          : (value) => setState(
                                                () => _selectedCardId = value,
                                              ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.md),
                                  TextField(
                                    controller: _amountController,
                                    enabled: !_paying,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Monto (COP)',
                                      prefixIcon: Icon(Icons.payments_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  CiervoButton(
                                    label: _paying
                                        ? 'Procesando pago'
                                        : 'Pagar en comercio',
                                    icon: Icons.point_of_sale_outlined,
                                    state: _paying
                                        ? CiervoButtonState.loading
                                        : CiervoButtonState.normal,
                                    onPressed: _paying ? null : _pay,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
