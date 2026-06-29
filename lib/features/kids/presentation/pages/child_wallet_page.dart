import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/kids_repository.dart';
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
  List<Map<String, dynamic>> _cards = const [];
  List<Map<String, dynamic>> _history = const [];
  bool _loading = true;
  String? _error;

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
    wallet.when(failure: (e) => error = UserErrorMessage.from(e), success: (v) => _wallet = v);
    cards.when(
      success: (items) => _cards = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    history.when(
      success: (items) => _history = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Future<void> _recharge(String cardId) async {
    final controller = TextEditingController();
    final amount = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recargar wallet del menor'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto (COP)'),
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
      cardId: cardId,
      amount: amount,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recarga enviada.')),
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
                          'COP ${_num(_wallet?['availableBalance'] ?? _wallet?['balance']).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (_num(_wallet?['heldBalance']) > 0)
                          Text(
                            'Retenido: COP ${_num(_wallet?['heldBalance']).toStringAsFixed(0)}',
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
                  const SizedBox(height: AppSpacing.lg),
                  Text('Tarjetas', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (_cards.isEmpty)
                    const CiervoEmptyState(
                      title: 'Sin tarjetas',
                      description: 'Este menor aun no tiene tarjetas wallet.',
                      icon: Icons.credit_card_outlined,
                    )
                  else
                    ..._cards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CiervoCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${card['displayName'] ?? 'Tarjeta Kids'}'),
                            subtitle: Text(
                              'Disponible: COP ${_num(card['availableBalance'] ?? card['balance']).toStringAsFixed(0)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_card_outlined),
                              onPressed: () => _recharge('${card['id'] ?? card['cardId']}'),
                            ),
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
                      description: 'Aun no hay transacciones registradas.',
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
                              'COP ${_num(item['amount']).toStringAsFixed(0)}',
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
