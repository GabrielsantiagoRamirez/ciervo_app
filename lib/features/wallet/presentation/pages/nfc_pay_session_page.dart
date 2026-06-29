import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../receipts/presentation/pages/receipts_page.dart';
import '../../domain/entities/nfc_models.dart';
import '../../domain/repositories/wallet_repository.dart';

class NfcPaySessionPage extends StatefulWidget {
  const NfcPaySessionPage({
    required this.session,
    required this.businessName,
    this.isDelivery = false,
    super.key,
  });

  final NfcSession session;
  final String businessName;
  final bool isDelivery;

  @override
  State<NfcPaySessionPage> createState() => _NfcPaySessionPageState();
}

class _NfcPaySessionPageState extends State<NfcPaySessionPage> {
  late NfcSession _session;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _cancelling = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _startCountdown();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  void _startCountdown() {
    final expiresAt = _session.expiresAt;
    if (expiresAt == null) {
      _remaining = const Duration(seconds: 60);
    } else {
      _remaining = expiresAt.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    }
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds <= 0) {
          _remaining = Duration.zero;
          _countdownTimer?.cancel();
        } else {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  Future<void> _poll() async {
    if (_finished || _cancelling) return;
    final result = await getIt<WalletRepository>().nfcSession(_session.id);
    if (!mounted) return;
    result.when(
      success: (session) {
        setState(() => _session = session);
        if (session.isUsed) {
          _onCompleted(success: true);
        } else if (session.isCancelled || session.isExpired) {
          _onCompleted(success: false);
        }
      },
      failure: (_) {},
    );
  }

  void _onCompleted({required bool success}) {
    if (_finished) return;
    _finished = true;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    if (!mounted) return;
    if (success) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pago confirmado'),
          content: Text(
            widget.isDelivery
                ? 'Tu pedido fue pagado con NFC CIERVO.'
                : 'El comercio cobro correctamente tu pago NFC.',
          ),
          actions: [
            if (_session.receiptId != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReceiptsPage(),
                    ),
                  );
                  Navigator.of(context).pop(true);
                },
                child: const Text('Ver recibos'),
              ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).pop(true);
              },
              child: const Text('Listo'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La sesion NFC expiro o fue cancelada.')),
      );
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    await getIt<WalletRepository>().cancelNfcSession(_session.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _qrData =>
      _session.nfcPayload?.token.isNotEmpty == true
          ? _session.nfcPayload!.token
          : _session.token;

  @override
  Widget build(BuildContext context) {
    final amount = _session.amount;
    final currency = _session.currency ?? 'COP';
    final seconds = _remaining.inSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca tu celular'),
        actions: [
          TextButton(
            onPressed: _cancelling || _finished ? null : _cancel,
            child: _cancelling
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cancelar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CiervoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.businessName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (amount != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$currency ${amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text('Expira en ${seconds}s'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Icon(
              Icons.nfc,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              Platform.isIOS
                  ? 'En iOS muestra este codigo QR al comercio si el terminal no lee NFC del celular.'
                  : 'Acerca tu celular al terminal CIERVO. Si no funciona, usa el codigo QR.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: QrImageView(
                data: _qrData,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const CiervoCard(
              child: Text(
                'Esperando confirmacion del comercio... '
                'No cierres esta pantalla hasta que el cobro se complete.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: 'Cancelar sesion NFC',
              variant: CiervoButtonVariant.secondary,
              icon: Icons.close,
              state: _cancelling
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _cancelling || _finished ? null : _cancel,
            ),
          ],
        ),
      ),
    );
  }
}
