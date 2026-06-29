import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/ciervo_pin.dart';
import '../../domain/repositories/pins_repository.dart';
import '../../../wallet/domain/entities/wallet_card.dart';

class PinsPage extends StatefulWidget {
  const PinsPage({required this.card, super.key});

  final WalletCard card;

  @override
  State<PinsPage> createState() => _PinsPageState();
}

class _PinsPageState extends State<PinsPage> {
  final _repository = getIt<PinsRepository>();
  List<CiervoPin> _pins = const [];
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
    final result = await _repository.myPins();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _pins = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _createPin() async {
    final businessIdController = TextEditingController();
    final amountController = TextEditingController();
    final created = await showDialog<CiervoPin?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear PIN Ciervo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: businessIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID comercio'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (COP)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );
              final businessId = businessIdController.text.trim();
              if (amount == null || amount <= 0 || businessId.isEmpty) return;
              if (!widget.card.canSpend(amount)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Saldo disponible insuficiente (COP ${widget.card.availableBalance.toStringAsFixed(0)}).',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              final kidId = getIt<SelectedKidContext>().kidId;
              final result = await _repository.createPin(
                walletCardId: widget.card.id,
                businessId: businessId,
                amount: amount,
                kidsMode: kidId != null,
              );
              if (!context.mounted) return;
              result.when(
                success: (pin) async {
                  if ((pin.pin ?? '').isNotEmpty) {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Tu PIN Ciervo'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pin.pin!,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Guardalo ahora. No volvera a mostrarse en la app.',
                            ),
                          ],
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Entendido'),
                          ),
                        ],
                      ),
                    );
                  }
                  _load();
                },
                failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(UserErrorMessage.from(error))),
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (created != null) _load();
  }

  Future<void> _cancelPin(CiervoPin pin) async {
    final result = await _repository.cancelPin(pin.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN cancelado.')),
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
      appBar: AppBar(title: const Text('PIN Ciervo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPin,
        icon: const Icon(Icons.pin_outlined),
        label: const Text('Crear PIN'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const CiervoLoadingState(itemCount: 3),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(_error!),
                    ),
                  if (_pins.isEmpty)
                    CiervoCard(
                      child: Text('No tienes PINs activos.'),
                    )
                  else
                    ..._pins.map(
                      (pin) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CiervoCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${pin.currency} ${pin.amount.toStringAsFixed(0)}',
                            ),
                            subtitle: Text(
                              '${pin.displayStatus}'
                              '${pin.expiresAt != null ? ' · vence ${pin.expiresAt}' : ''}',
                            ),
                            trailing: pin.canCancel
                                ? IconButton(
                                    icon: const Icon(Icons.cancel_outlined),
                                    onPressed: () => _cancelPin(pin),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
