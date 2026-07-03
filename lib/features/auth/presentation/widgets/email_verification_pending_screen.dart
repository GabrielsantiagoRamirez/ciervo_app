import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';

/// Pantalla de espera mientras el usuario confirma su correo en Firebase.
class EmailVerificationPendingScreen extends StatefulWidget {
  const EmailVerificationPendingScreen({
    required this.email,
    required this.onConfirmed,
    required this.onResend,
    required this.onChangeEmail,
    this.serverError,
    this.initialResendCooldown = 0,
    super.key,
  });

  final String email;
  final Future<bool> Function() onConfirmed;
  final Future<({bool success, String? errorMessage})> Function() onResend;
  final VoidCallback onChangeEmail;
  final String? serverError;
  final int initialResendCooldown;

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen> {
  bool _checking = false;
  bool _resending = false;
  int _resendCooldown = 0;
  String? _localMessage;
  bool _isSuccess = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialResendCooldown > 0) {
      _startResendCooldown(widget.initialResendCooldown);
    }
  }

  @override
  void didUpdateWidget(covariant EmailVerificationPendingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serverError != oldWidget.serverError && widget.serverError != null) {
      _localMessage = null;
      _isSuccess = false;
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    setState(() => _resendCooldown = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  String? get _visibleMessage => widget.serverError ?? _localMessage;

  Future<void> _pollAndConfirm() async {
    setState(() {
      _checking = true;
      _localMessage = null;
      _isSuccess = false;
    });

    final firebase = getIt<FirebaseAuthService>();
    var verified = false;
    for (var attempt = 0; attempt < 10; attempt++) {
      await firebase.reloadUser();
      if (firebase.isEmailVerified) {
        verified = true;
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (!verified) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _isSuccess = false;
        _localMessage =
            'Aún no confirmamos tu correo. Abre el enlace del mensaje e intenta de nuevo.';
      });
      return;
    }

    final ok = await widget.onConfirmed();
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!ok && widget.serverError == null) {
        _isSuccess = false;
        _localMessage = 'No pudimos activar tu cuenta. Intenta de nuevo.';
      }
    });
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _localMessage = null;
      _isSuccess = false;
    });
    final result = await widget.onResend();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _isSuccess = result.success;
      _localMessage = result.success
          ? 'Te reenviamos el correo de verificación.'
          : result.errorMessage ??
              'No pudimos reenviar el correo. Intenta en unos segundos.';
    });
    if (result.success) _startResendCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final message = _visibleMessage;
    final isError = message != null && !_isSuccess;

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confirma tu correo',
                  style: textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cambiar correo',
                onPressed: widget.onChangeEmail,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.email,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Abre el enlace de confirmación y luego pulsa "Ya confirmé". '
                        'Si no lo encuentras, revisa spam o promociones.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: _checking ? 'Verificando…' : 'Ya confirmé',
            icon: Icons.verified_outlined,
            state: _checking
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _checking ? null : _pollAndConfirm,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _resendCooldown > 0 || _resending ? null : _resend,
            icon: const Icon(Icons.refresh),
            label: Text(
              _resending
                  ? 'Reenviando…'
                  : _resendCooldown > 0
                      ? 'Reenviar en ${_resendCooldown}s'
                      : 'Reenviar correo',
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (isError
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer)
                    .withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: isError
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
