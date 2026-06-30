import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../receipts/domain/entities/action_confirmation.dart';
import '../../../receipts/presentation/pages/action_confirmation_page.dart';
import '../../../wallet/domain/entities/wallet_card.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/pages/recharge_page.dart';
import '../../data/secure_shipment_repository.dart';
import '../../domain/models/secure_shipment.dart';
import '../widgets/shipment_status_chip.dart' show ShipmentStatusChip, showSecureShipmentPinModal;

class SecureShipmentDetailPage extends StatefulWidget {
  const SecureShipmentDetailPage({required this.publicId, super.key});

  final String publicId;

  @override
  State<SecureShipmentDetailPage> createState() =>
      _SecureShipmentDetailPageState();
}

class _SecureShipmentDetailPageState extends State<SecureShipmentDetailPage> {
  final _repository = getIt<SecureShipmentRepository>();
  SecureShipment? _shipment;
  String? _currentUserId;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  final _pinInput = TextEditingController();
  DateTime? _pinBlockedUntil;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pinInput.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final profile = await getIt<ProfileRepository>().getMe();
    profile.when(
      success: (p) => _currentUserId = p.id,
      failure: (_) {},
    );
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getShipment(widget.publicId);
    if (!mounted) return;
    result.when(
      success: (s) => setState(() {
        _shipment = s;
        _loading = false;
      }),
      failure: (e) => setState(() {
        _error = UserErrorMessage.from(e);
        _loading = false;
      }),
    );
  }

  SecureShipmentRole get _role =>
      _shipment?.roleFor(_currentUserId) ?? SecureShipmentRole.none;

  String get _statusKey =>
      (_shipment?.statusName ?? '').replaceAll('_', '').toLowerCase();

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() => _run(() async {
        final result = await _repository.acceptShipment(widget.publicId);
        if (!mounted) return;
        result.when(
          success: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Envío aceptado.')),
            );
            _load();
            _showHoldDialog();
          },
          failure: (e) => _showError(UserErrorMessage.from(e)),
        );
      });

  Future<void> _reject() => _run(() async {
        final result = await _repository.rejectShipment(widget.publicId);
        if (!mounted) return;
        result.when(
          success: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Envío rechazado.')),
            );
            _load();
          },
          failure: (e) => _showError(UserErrorMessage.from(e)),
        );
      });

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar envío'),
        content: const Text(
          'Se liberará la retención de fondos si existe. ¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final result = await _repository.cancelShipment(widget.publicId);
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Envío cancelado.')),
          );
          _load();
        },
        failure: (e) => _showError(UserErrorMessage.from(e)),
      );
    });
  }

  Future<void> _showHoldDialog() async {
    final cardsResult = await getIt<WalletRepository>().cards();
    if (!mounted) return;
    final cards = cardsResult.when(
      success: (c) => c,
      failure: (_) => <WalletCard>[],
    );
    if (cards.isEmpty) {
      _showError('Necesitas una tarjeta wallet para retener fondos.');
      return;
    }
    WalletCard? selected = cards.firstWhere(
      (c) => c.isPrimary,
      orElse: () => cards.first,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Retener fondos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Retendremos ${_shipment?.currency ?? 'COP'} '
                '${_shipment?.totalAmount.toStringAsFixed(0) ?? '0'} '
                'de tu wallet hasta confirmar la entrega.',
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<WalletCard>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Tarjeta wallet'),
                items: cards
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} · ${c.availableBalance.toStringAsFixed(0)}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => selected = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Después')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retener')),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == null) return;

    await _run(() async {
      final result = await _repository.createHold(
        publicId: widget.publicId,
        walletCardId: selected!.id,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fondos retenidos correctamente.')),
          );
          _load();
        },
        failure: (e) {
          final msg = UserErrorMessage.from(e).toLowerCase();
          if (msg.contains('saldo') || msg.contains('insufficient')) {
            _offerRecharge(selected!);
          } else {
            _showError(UserErrorMessage.from(e));
          }
        },
      );
    });
  }

  Future<void> _offerRecharge(WalletCard card) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saldo insuficiente'),
        content: const Text('Recarga tu wallet para retener el monto del envío.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Recargar')),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RechargePage(card: card)),
      );
    }
  }

  Future<void> _generatePin() => _run(() async {
        final result = await _repository.generatePins(publicId: widget.publicId);
        if (!mounted) return;
        result.when(
          success: (pinResult) async {
            if (pinResult.pin != null && pinResult.pin!.isNotEmpty) {
              await showSecureShipmentPinModal(
                context,
                pin: pinResult.pin!,
                expiresAt: pinResult.expiresAt,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    pinResult.pinHint != null
                        ? 'PIN ya entregado · termina en ${pinResult.pinHint}'
                        : 'PIN generado. Revisa tus notificaciones.',
                  ),
                ),
              );
            }
            _load();
          },
          failure: (e) => _showError(UserErrorMessage.from(e)),
        );
      });

  Future<void> _validatePin(String role) async {
    if (_pinBlockedUntil != null &&
        DateTime.now().isBefore(_pinBlockedUntil!)) {
      _showError('PIN bloqueado temporalmente. Intenta más tarde.');
      return;
    }
    final pin = _pinInput.text.trim();
    if (pin.length < 4) {
      _showError('Ingresa tu PIN de entrega.');
      return;
    }
    await _run(() async {
      final result = await _repository.validatePin(
        publicId: widget.publicId,
        pin: pin,
        role: role,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          _pinInput.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN validado.')),
          );
          _load();
        },
        failure: (e) {
          final msg = UserErrorMessage.from(e).toLowerCase();
          if (msg.contains('bloque') || msg.contains('15')) {
            setState(() {
              _pinBlockedUntil = DateTime.now().add(const Duration(minutes: 15));
            });
          }
          _showError(UserErrorMessage.from(e));
        },
      );
    });
  }

  Future<void> _synchronize() => _run(() async {
        final result = await _repository.synchronizePins(publicId: widget.publicId);
        if (!mounted) return;
        result.when(
          success: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entrega confirmada.')),
            );
            _load();
          },
          failure: (e) => _showError(UserErrorMessage.from(e)),
        );
      });

  Future<void> _executePayment() => _run(() async {
        final result = await _repository.executePayment(publicId: widget.publicId);
        if (!mounted) return;
        result.when(
          success: (_) async {
            await _showReceipt();
            _load();
          },
          failure: (e) => _showError(UserErrorMessage.from(e)),
        );
      });

  Future<void> _showReceipt() async {
    final result = await _repository.getReceipt(widget.publicId);
    if (!mounted) return;
    result.when(
      success: (data) {
        final now = DateTime.now();
        showCiervoPaymentReceipt(
          context,
          confirmation: ActionConfirmation(
            title: 'Pago de envío seguro liberado',
            confirmationCode: '${data['receiptId'] ?? widget.publicId}',
            businessName: _shipment?.receiverName ?? 'Envío seguro',
            amount: _shipment?.totalAmount,
            currency: _shipment?.currency ?? 'COP',
            status: 'Pago realizado con éxito',
            date: now.toIso8601String(),
            time: now.toIso8601String(),
            shareDescription:
                'Tu envío seguro ${widget.publicId} fue liquidado correctamente.',
          ),
        );
      },
      failure: (e) => _showError(UserErrorMessage.from(e)),
    );
  }

  Future<void> _openDispute() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Abrir disputa'),
          content: TextField(
            controller: c,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos qué ocurrió',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    await _run(() async {
      final result = await _repository.openDispute(
        publicId: widget.publicId,
        reason: reason,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Disputa registrada. Fondos congelados.')),
          );
          _load();
        },
        failure: (e) => _showError(UserErrorMessage.from(e)),
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.publicId)),
      body: _loading
          ? const CiervoLoadingState(itemCount: 5)
          : _error != null && _shipment == null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (_shipment!.hasActiveDispute)
                    _Banner(
                      text:
                          'Disputa activa — fondos congelados. Soporte CIERVO revisará el caso.',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DisplayLabels.secureShipmentStatus(
                                  _shipment!.statusName,
                                ),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ShipmentStatusChip(statusName: _shipment!.statusName),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${_shipment!.currency} ${_shipment!.totalAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (_shipment!.hasActiveHold)
                          const Text('Fondos en custodia'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoSection(
                    title: 'Ruta',
                    lines: [
                      'Origen: ${_shipment!.originAddress}',
                      'Destino: ${_shipment!.destinationAddress}',
                      if (_shipment!.trackingNumber != null)
                        'Guía: ${_shipment!.trackingNumber}',
                      if (_shipment!.logisticsCompany != null)
                        'Transportadora: ${_shipment!.logisticsCompany}',
                    ],
                  ),
                  if (_shipment!.observations != null)
                    _InfoSection(
                      title: 'Notas',
                      lines: [_shipment!.observations!],
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._buildActions(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildActions() {
    final s = _shipment!;
    final widgets = <Widget>[];

    if (_role == SecureShipmentRole.receiver &&
        _statusKey.contains('pendingacceptance')) {
      widgets.addAll([
        CiervoButton(
          label: _busy ? 'Procesando...' : 'Aceptar envío',
          icon: Icons.check_circle_outline,
          onPressed: _busy ? null : _accept,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _busy ? null : _reject,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Rechazar'),
        ),
      ]);
    }

    if (_role == SecureShipmentRole.receiver &&
        (_statusKey.contains('accepted') ||
            (_statusKey.contains('pending') && !s.hasActiveHold))) {
      widgets.add(
        CiervoButton(
          label: 'Retener fondos en wallet',
          icon: Icons.account_balance_wallet_outlined,
          onPressed: _busy ? null : _showHoldDialog,
        ),
      );
    }

    if (_statusKey.contains('fundsheld') ||
        (_statusKey.contains('pinsgenerated') && !s.pinsGenerated)) {
      widgets.add(
        CiervoButton(
          label: 'Generar mi PIN de entrega',
          icon: Icons.pin_outlined,
          onPressed: _busy ? null : _generatePin,
        ),
      );
    }

    if (_statusKey.contains('pinsgenerated') ||
        _statusKey.contains('senderpinvalidated') ||
        _statusKey.contains('receiverpinvalidated')) {
      widgets.addAll([
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _pinInput,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Ingresa PIN de entrega',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_role == SecureShipmentRole.sender)
          CiervoButton(
            label: 'Validar PIN emisor',
            icon: Icons.verified_outlined,
            onPressed: _busy ? null : () => _validatePin('Sender'),
          ),
        if (_role == SecureShipmentRole.receiver)
          CiervoButton(
            label: 'Validar PIN receptor',
            icon: Icons.verified_outlined,
            onPressed: _busy ? null : () => _validatePin('Receiver'),
          ),
        TextButton(
          onPressed: _busy ? null : _generatePin,
          child: const Text('Regenerar PIN'),
        ),
      ]);
    }

    if (_role == SecureShipmentRole.sender &&
        (_statusKey.contains('senderpinvalidated') ||
            _statusKey.contains('receiverpinvalidated'))) {
      widgets.add(
        CiervoButton(
          label: 'Confirmar entrega (sync PIN)',
          icon: Icons.handshake_outlined,
          onPressed: _busy ? null : _synchronize,
        ),
      );
    }

    if (_role == SecureShipmentRole.sender &&
        _statusKey.contains('deliveryconfirmed') &&
        !s.hasActiveDispute) {
      widgets.add(
        CiervoButton(
          label: 'Liberar pago al comercio',
          icon: Icons.payments_outlined,
          onPressed: _busy ? null : _executePayment,
        ),
      );
    }

    if (_statusKey.contains('paymentreleased') ||
        _statusKey.contains('completed')) {
      widgets.add(
        CiervoButton(
          label: 'Ver recibo',
          icon: Icons.receipt_long_outlined,
          onPressed: _busy ? null : _showReceipt,
        ),
      );
    }

    if (!s.hasActiveDispute &&
        !_statusKey.contains('cancelled') &&
        !_statusKey.contains('completed') &&
        !_statusKey.contains('refunded')) {
      widgets.add(const SizedBox(height: AppSpacing.md));
      widgets.add(
        OutlinedButton.icon(
          onPressed: _busy ? null : _openDispute,
          icon: const Icon(Icons.report_problem_outlined),
          label: const Text('Reportar problema'),
        ),
      );
    }

    if (_role == SecureShipmentRole.sender &&
        (_statusKey.contains('pendingacceptance') ||
            _statusKey.contains('accepted'))) {
      widgets.add(const SizedBox(height: AppSpacing.sm));
      widgets.add(
        OutlinedButton.icon(
          onPressed: _busy ? null : _cancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar envío'),
        ),
      );
    }

    return widgets;
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.lines});
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CiervoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l),
                )),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(text, style: TextStyle(color: color)),
      ),
    );
  }
}