import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kids/domain/repositories/kids_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../data/durable_pin_service.dart';
import '../../domain/entities/ciervo_pin.dart';
import '../../domain/entities/durable_user_pin.dart';
import '../../domain/repositories/pins_repository.dart';
import '../../../wallet/domain/entities/wallet_card.dart';
import '../pages/pin_p2p_pay_page.dart';
import '../widgets/durable_pin_help_dialog.dart';

class PinsPage extends StatefulWidget {
  const PinsPage({required this.card, super.key});

  final WalletCard card;

  @override
  State<PinsPage> createState() => _PinsPageState();
}

class _PinsPageState extends State<PinsPage> {
  final _repository = getIt<PinsRepository>();
  final _durable = getIt<DurablePinService>();

  List<CiervoPin> _pins = const [];
  DurableUserPin? _durablePin;
  bool _loading = true;
  bool _rotating = false;
  bool _codeVisible = false;
  String? _error;
  String? _ownerUserId;

  String get _currency {
    final value = widget.card.currency.trim();
    return value.isEmpty ? 'COP' : value.toUpperCase();
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

    final profileResult = await getIt<ProfileRepository>().getMe();
    final ownerId = profileResult.when(
      success: (profile) => profile.id,
      failure: (_) => '',
    );
    _ownerUserId = ownerId;

    if (ownerId.isNotEmpty) {
      final durableResult = await _durable.ensureActive(
        ownerUserId: ownerId,
        walletCardId: widget.card.id,
        currency: _currency,
      );
      durableResult.when(
        success: (pin) => _durablePin = pin,
        failure: (error) => _error = UserErrorMessage.from(error),
      );
    }

    final result = await _repository.myPins();
    if (!mounted) return;
    setState(() {
      result.when(
        success: (items) => _pins = items,
        failure: (error) => _error ??= UserErrorMessage.from(error),
      );
      _loading = false;
    });

    if (_durablePin != null && mounted) {
      await maybeShowDurablePinHelpOnFirstView(context);
    }
  }

  Future<void> _refreshDurable({bool forceRefresh = false}) async {
    final ownerId = _ownerUserId;
    if (ownerId == null || ownerId.isEmpty || _rotating) return;
    setState(() => _rotating = true);
    final result = await _durable.ensureActive(
      ownerUserId: ownerId,
      walletCardId: widget.card.id,
      currency: _currency,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    result.when(
      success: (pin) => setState(() {
        _durablePin = pin;
        _codeVisible = true;
        _rotating = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _rotating = false;
      }),
    );
  }

  Future<void> _createPaymentPin() async {
    final businessIdController = TextEditingController();
    final amountController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN para un pago en comercio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reserva saldo para un comercio concreto. Vence en 30 minutos.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: businessIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID comercio'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Monto ($_currency)'),
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
                      'Saldo disponible insuficiente '
                      '($_currency ${widget.card.availableBalance.toStringAsFixed(0)}).',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              await _submitPaymentPin(businessId: businessId, amount: amount);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPaymentPin({
    required String businessId,
    required double amount,
  }) async {
    final kidId = getIt<SelectedKidContext>().kidId;
    String? childWalletCardId;
    if (kidId != null) {
      final cards = await getIt<KidsRepository>().childWalletCards(kidId);
      cards.when(
        success: (items) {
          for (final item in items) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final isPrimary = map['isPrimary'] == true;
              final id = '${map['id'] ?? map['cardId'] ?? ''}';
              if (id.isNotEmpty && (isPrimary || childWalletCardId == null)) {
                childWalletCardId = id;
                if (isPrimary) break;
              }
            }
          }
        },
        failure: (_) {},
      );
      if (childWalletCardId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El menor no tiene tarjeta wallet disponible.'),
          ),
        );
        return;
      }
    }

    final result = await _repository.createPin(
      walletCardId: widget.card.id,
      businessId: businessId,
      amount: amount,
      currency: _currency,
      kidsMode: kidId != null,
      childProfileId: kidId,
      childWalletCardId: childWalletCardId,
    );
    if (!mounted) return;
    result.when(
      success: (pin) async {
        if ((pin.pin ?? '').isNotEmpty) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('PIN de pago en comercio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pin.pin!,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Guárdalo ahora. Este PIN puntual no se vuelve a mostrar.',
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
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
    );
  }

  Future<void> _cancelPin(CiervoPin pin) async {
    final result = await _repository.cancelPin(pin.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN cancelado.')));
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
    );
  }

  String _formatExpiry(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final durable = _durablePin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN Ciervo'),
        actions: [
          IconButton(
            tooltip: '¿Para qué sirve?',
            onPressed: () => showDurablePinHelpDialog(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: AppSpacing.lg),
                  CiervoLoadingState(itemCount: 3),
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
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tu PIN Ciervo',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  showDurablePinHelpDialog(context),
                              child: const Text('¿Para qué sirve?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Para comercios afiliados o cobros persona a persona. '
                          'Se renueva cada semana.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (durable == null)
                          const Text('No pudimos cargar tu PIN semanal.')
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _codeVisible ? durable.code : '••••••••',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(letterSpacing: 6),
                                ),
                              ),
                              IconButton(
                                tooltip: _codeVisible ? 'Ocultar' : 'Mostrar',
                                onPressed: () => setState(
                                  () => _codeVisible = !_codeVisible,
                                ),
                                icon: Icon(
                                  _codeVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: durable.code),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('PIN copiado.'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'ID PIN: ${durable.paymentPinId ?? '—'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Vigente hasta ${_formatExpiry(durable.expiresAt)}',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        CiervoButton(
                          label: durable == null
                              ? 'Obtener PIN'
                              : 'Actualizar PIN',
                          icon: Icons.autorenew,
                          onPressed: _rotating
                              ? null
                              : () => _refreshDurable(forceRefresh: true),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        CiervoButton(
                          label: 'Cobrar a otra persona',
                          icon: Icons.person_outline,
                          variant: CiervoButtonVariant.secondary,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<bool>(
                              builder: (_) => PinP2PPayPage(card: widget.card),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PINs de comercio (puntual)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _createPaymentPin,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_pins.isEmpty)
                    const CiervoCard(
                      child: Text('No tienes PINs de comercio activos.'),
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
