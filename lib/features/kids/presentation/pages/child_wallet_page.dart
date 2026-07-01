import 'package:flutter/material.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/kids_repository.dart';
import '../utils/child_wallet_card_view.dart';
import '../../../family_payments/presentation/pages/kid_payment_source_page.dart';
import 'child_business_payment_page.dart';

class ChildWalletPage extends StatefulWidget {
  const ChildWalletPage({required this.childId, super.key});
  final String childId;

  @override
  State<ChildWalletPage> createState() => _ChildWalletPageState();
}

class _ChildWalletPageState extends State<ChildWalletPage> {
  final _repository = getIt<KidsRepository>();
  Map<String, dynamic>? _wallet;
  List<ChildWalletCardView> _cards = const [];
  List<Map<String, dynamic>> _history = const [];
  bool _loading = true;
  String? _error;
  String? _highlightCardId;

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
    final wallet = await _repository.childWallet(widget.childId);
    final cards = await _repository.childWalletCards(widget.childId);
    final history = await _repository.childWalletHistory(widget.childId);
    if (!mounted) return;
    String? error;
    Map<String, dynamic>? walletData;
    wallet.when(
      failure: (e) => error = UserErrorMessage.from(e),
      success: (v) => walletData = v,
    );

    var parsedCards = <ChildWalletCardView>[];
    cards.when(
      success: (items) {
        parsedCards = ChildWalletCardView.listFrom(items);
      },
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    if (parsedCards.isEmpty && walletData != null) {
      parsedCards = ChildWalletCardView.listFrom(walletData);
    }

    final historyItems = <Map<String, dynamic>>[];
    history.when(
      success: (items) {
        historyItems.addAll(
          items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      },
      failure: (e) => error ??= UserErrorMessage.from(e),
    );

    setState(() {
      _loading = false;
      _wallet = walletData;
      _cards = parsedCards;
      _history = historyItems;
      _error = error;
    });
  }

  String get _walletCurrency =>
      _wallet?['currency']?.toString() ??
      CountryRegistration.currencyForCountry(
        _wallet?['countryCode']?.toString() ?? 'CO',
      );

  Future<void> _recharge(ChildWalletCardView card) async {
    if (card.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos identificar la tarjeta.')),
      );
      return;
    }
    final currency = card.currency.isNotEmpty ? card.currency : _walletCurrency;
    final controller = TextEditingController();
    final amount = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recargar ${card.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tarjeta #${card.id}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Monto ($currency)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Se debitará de tu tarjeta principal como tutor.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Recargar'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    final result = await _repository.rechargeChildWallet(
      childId: widget.childId,
      cardId: card.id,
      amount: amount,
      currency: currency,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recarga de $currency ${amount.toStringAsFixed(0)} enviada.')),
        );
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _createCard() async {
    final nameController = TextEditingController(
      text: 'Tarjeta Kids ${_cards.length + 1}',
    );
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva tarjeta Kids'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la tarjeta',
            helperText: 'Usa un nombre distinto para identificarla fácilmente.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (created != true) return;
    final displayName = nameController.text.trim();
    if (displayName.isEmpty) return;
    final result = await _repository.createChildWalletCard(
      childId: widget.childId,
      displayName: displayName,
      currency: _walletCurrency,
    );
    if (!mounted) return;
    result.when(
      success: (data) {
        final createdCard = ChildWalletCardView.fromMap(data);
        setState(() => _highlightCardId = createdCard.id.isNotEmpty ? createdCard.id : null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createdCard.id.isNotEmpty
                  ? 'Tarjeta "$displayName" creada (ID #${createdCard.id}).'
                  : 'Tarjeta "$displayName" creada.',
            ),
          ),
        );
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = _walletCurrency;
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Kids')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [CiervoLoadingState(itemCount: 4)],
              )
            : _error != null && _wallet == null
            ? ListView(
                padding: pagePaddingOf(context),
                children: [
                  CiervoErrorState(
                    title: 'No pudimos cargar la wallet',
                    description: _error!,
                    onRetry: _load,
                  ),
                ],
              )
            : ListView(
                padding: pagePaddingOf(context),
                children: [
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo disponible', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '$currency ${_num(_wallet?['availableBalance'] ?? _wallet?['balance']).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (_num(_wallet?['heldBalance']) > 0)
                          Text(
                            'Retenido: $currency ${_num(_wallet?['heldBalance']).toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CiervoCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.point_of_sale_outlined),
                      title: const Text('Pagar en comercio permitido'),
                      subtitle: const Text(
                        'Usa la wallet Kids en un comercio autorizado.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChildBusinessPaymentPage(
                            childId: widget.childId,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CiervoCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.credit_card_outlined),
                      title: const Text('Fuente de pago'),
                      subtitle: const Text(
                        'Tarjeta del tutor cuando no hay saldo Kids.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => KidPaymentSourcePage(
                            kidId: widget.childId,
                            kidName: 'Menor',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tarjetas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _createCard,
                        icon: const Icon(Icons.add_card_outlined),
                        label: const Text('Nueva tarjeta'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_cards.isEmpty)
                    const CiervoEmptyState(
                      title: 'Sin tarjetas',
                      description: 'Este menor aún no tiene tarjetas wallet.',
                      icon: Icons.credit_card_outlined,
                    )
                  else
                    ..._cards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CiervoCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                card.displayName.isNotEmpty
                                    ? card.displayName.substring(0, 1).toUpperCase()
                                    : '#',
                              ),
                            ),
                            title: Text(card.displayName),
                            subtitle: Text(
                              '${card.subtitle}\nDisponible: ${card.currency} ${card.balance.toStringAsFixed(0)}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Recargar tarjeta',
                              icon: const Icon(Icons.account_balance_wallet_outlined),
                              onPressed: card.isBlocked
                                  ? null
                                  : () => _recharge(card),
                            ),
                            tileColor: _highlightCardId == card.id
                                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Historial', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (_history.isEmpty)
                    const CiervoEmptyState(
                      title: 'Sin movimientos',
                      description: 'Aún no hay transacciones registradas.',
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    ..._history.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CiervoCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${item['description'] ?? item['type'] ?? 'Movimiento'}'),
                            subtitle: Text('${item['createdAt'] ?? ''}'),
                            trailing: Text(
                              '$currency ${_num(item['amount']).toStringAsFixed(0)}',
                            ),
                          ),
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
