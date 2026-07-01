import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../family_payments/data/dtos/family_payment_dtos.dart';
import '../../../family_payments/presentation/pages/family_payment_navigation.dart';
import '../../../kid_pay_for_me/presentation/pages/kid_pay_for_me_request_page.dart';

class KidNfcPayPage extends StatefulWidget {
  const KidNfcPayPage({
    required this.businessId,
    required this.businessName,
    super.key,
  });

  final String businessId;
  final String businessName;

  @override
  State<KidNfcPayPage> createState() => _KidNfcPayPageState();
}

class _KidNfcPayPageState extends State<KidNfcPayPage> {
  final _repository = getIt<KidMeRepository>();
  final _amount = TextEditingController();
  Map<String, dynamic>? _session;
  bool _creating = false;
  bool _polling = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void dispose() {
    _amount.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  int? get _sessionId {
    final raw = _session?['id'] ?? _session?['sessionId'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  String get _qrToken {
    final payload = _session?['nfcPayload'];
    if (payload is Map) {
      final token = payload['token'];
      if (token != null && '$token'.isNotEmpty) return '$token';
    }
    return '${_session?['token'] ?? _session?['qrPayload'] ?? ''}';
  }

  String get _sessionStatus =>
      '${_session?['status'] ?? _session?['sessionStatus'] ?? ''}'.toLowerCase();

  Future<void> _createSession() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    final result = await _repository.createNfcSession(
      businessId: widget.businessId,
      amount: amount,
    );

    if (!mounted) return;
    result.when(
      success: (session) {
        setState(() {
          _session = session;
          _creating = false;
        });
        _startPolling();
      },
      failure: (error) {
        final message = UserErrorMessage.from(error).toLowerCase();
        setState(() {
          _error = UserErrorMessage.from(error);
          _creating = false;
        });
        if (message.contains('saldo') ||
            message.contains('insufficient') ||
            message.contains('fondos')) {
          _offerPayForMe();
        }
      },
    );
  }

  Future<void> _offerPayForMe() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saldo insuficiente'),
        content: const Text(
          'No tienes saldo suficiente. ¿Quieres pedirle a tu familia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pedir a mi familia'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KidPayForMeRequestPage(
            businessId: widget.businessId,
            businessName: widget.businessName,
          ),
        ),
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    final id = _sessionId;
    if (id == null || _polling) return;
    _polling = true;
    final result = await _repository.nfcSession(id);
    if (!mounted) return;
    _polling = false;
    result.when(
      success: (session) {
        setState(() => _session = session);
        final status = _sessionStatus;
        if (status.contains('used') ||
            status.contains('completed') ||
            status.contains('paid')) {
          _pollTimer?.cancel();
          final payment = session['payment'];
          if (payment is Map) {
            final detail = FamilyPaymentRecordDto.fromJson(
              Map<String, dynamic>.from(payment),
            ).toDetailDomain();
            showFamilyPaymentResultDialog(context, payment: detail);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  (session['usedParentCard'] == true ||
                          session['parentCardUsed'] == true)
                      ? 'Pago autorizado por tu tutor'
                      : 'Pago realizado',
                ),
              ),
            );
          }
          Navigator.of(context).pop(true);
        } else if (status.contains('cancel') || status.contains('expir')) {
          _pollTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La sesión NFC expiró.')),
          );
        }
      },
      failure: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago NFC Kids')),
      body: ListView(
        padding: pagePaddingOf(context),
        children: [
          CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.businessName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Acerca tu celular al terminal o muestra el código QR al comercio.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_session == null) ...[
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monto (COP)',
                prefixText: '\$ ',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            CiervoButton(
              label: _creating ? 'Preparando NFC...' : 'Activar pago NFC',
              icon: Icons.nfc,
              onPressed: _creating ? null : _createSession,
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.nfc, size: 64),
                  const SizedBox(height: AppSpacing.md),
                  if (_qrToken.isNotEmpty)
                    QrImageView(
                      data: _qrToken,
                      size: 220,
                      backgroundColor: Colors.white,
                    )
                  else
                    const Text('Esperando token de sesión...'),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Estado: ${_session?['status'] ?? 'Activa'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
