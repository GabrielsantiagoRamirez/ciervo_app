import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../receipts/domain/entities/action_confirmation.dart';
import '../../../receipts/presentation/pages/action_confirmation_page.dart';
import '../../domain/entities/universal_nfc_payment.dart';
import '../../domain/repositories/universal_nfc_repository.dart';
import '../utils/nfc_payment_ui.dart';

class UniversalNfcSessionPage extends StatefulWidget {
  const UniversalNfcSessionPage({
    required this.payment,
    required this.merchantLabel,
    super.key,
  });

  final UniversalNfcPayment payment;
  final String merchantLabel;

  @override
  State<UniversalNfcSessionPage> createState() =>
      _UniversalNfcSessionPageState();
}

class _UniversalNfcSessionPageState extends State<UniversalNfcSessionPage> {
  final _repository = getIt<UniversalNfcRepository>();
  late UniversalNfcPayment _payment;
  Timer? _pollTimer;
  bool _confirming = false;
  bool _cancelling = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_finished || _confirming) return;
    final result = await _repository.payment(_payment.paymentIntentId);
    if (!mounted) return;
    result.when(
      success: (payment) {
        setState(() => _payment = payment);
        if (payment.isApproved) {
          _onSuccess();
        } else if (payment.isRejected ||
            payment.isCancelled ||
            payment.isExpired ||
            payment.isFailed) {
          _onFailure(payment);
        }
      },
      failure: (_) {},
    );
  }

  Future<void> _confirmTap() async {
    if (_finished || !_payment.isPendingNfcTap) return;
    setState(() => _confirming = true);
    final result = await _repository.confirm(_payment.paymentIntentId);
    if (!mounted) return;
    setState(() => _confirming = false);
    result.when(
      success: (payment) {
        setState(() => _payment = payment);
        if (payment.isApproved || payment.approved == true) {
          _onSuccess(payment: payment);
        } else if (payment.isRejected || payment.isFailed) {
          _onFailure(payment);
        }
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  Future<void> _cancel() async {
    if (_finished || _cancelling) return;
    setState(() => _cancelling = true);
    await _repository.cancel(_payment.paymentIntentId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    Navigator.of(context).pop(false);
  }

  void _onSuccess({UniversalNfcPayment? payment}) {
    if (_finished) return;
    _finished = true;
    _pollTimer?.cancel();
    final p = payment ?? _payment;
    final now = DateTime.now();
    showCiervoPaymentReceipt(
      context,
      confirmation: ActionConfirmation(
        title: 'Pago NFC confirmado',
        confirmationCode: p.receiptId ?? p.paymentIntentId,
        businessName: p.merchantName ?? widget.merchantLabel,
        amount: p.total ?? p.amount,
        currency: p.currency,
        status: 'Pago realizado con éxito',
        date: now.toIso8601String(),
        time: now.toIso8601String(),
        shareDescription: 'Pagaste con NFC Universal en CIERVO.',
      ),
      onDone: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop(true);
      },
    );
  }

  void _onFailure(UniversalNfcPayment payment) {
    if (_finished) return;
    _finished = true;
    _pollTimer?.cancel();
    final message =
        payment.message ?? NfcPaymentUi.rejectReasonMessage(payment.reason);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primary : theme.colorScheme.primary;
    final qrToken = _payment.qrToken;
    final statusLabel = NfcPaymentUi.statusLabel(_payment.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(statusLabel),
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
      body: ListView(
        padding: pagePaddingOf(context),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CiervoCard(
                    showGradientOverlay: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.merchantLabel,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          NfcPaymentUi.formatMoney(
                            _payment.total ?? _payment.amount,
                            _payment.currency,
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(statusLabel, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_payment.isPendingParentApproval) ...[
                    _waitingPanel(
                      context,
                      icon: Icons.family_restroom_outlined,
                      title: 'Esperando aprobación del tutor',
                      subtitle:
                          'Tu tutor recibirá una notificación para autorizar este pago.',
                    ),
                  ] else if (_payment.isPendingNfcTap) ...[
                    Icon(Icons.nfc, size: 88, color: accent),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      Platform.isIOS
                          ? 'Acerca tu celular al datáfono o muestra el código QR.'
                          : 'Acerca tu celular al datáfono. Si no funciona, usa el QR.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (qrToken.isNotEmpty)
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: QrImageView(data: qrToken, size: 220),
                          ),
                        ),
                      )
                    else
                      const CiervoCard(
                        child: Text('Generando token de sesión...'),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: _confirming
                          ? 'Confirmando...'
                          : 'Ya acerqué mi celular',
                      icon: Icons.check_circle_outline,
                      state: _confirming
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: _confirming || _finished ? null : _confirmTap,
                    ),
                  ] else
                    _waitingPanel(
                      context,
                      icon: Icons.hourglass_top_outlined,
                      title: 'Procesando pago',
                      subtitle: 'Mantén esta pantalla abierta un momento.',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitingPanel(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 72, color: theme.colorScheme.secondary),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        const CircularProgressIndicator(),
      ],
    );
  }
}
