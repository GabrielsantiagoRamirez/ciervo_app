import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';

/// Modal informativo tras enviar el correo de verificación Firebase.
Future<void> showEmailVerificationInfoDialog(
  BuildContext context, {
  required String email,
  required Future<({bool success, String? errorMessage})> Function() onResend,
  VoidCallback? onAlreadyChecked,
}) async {
  final firebase = getIt<FirebaseAuthService>();
  if (firebase.isEmailVerified) {
    onAlreadyChecked?.call();
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => EmailVerificationInfoDialog(
      email: email.trim(),
      onResend: onResend,
      onAlreadyChecked: () {
        Navigator.of(dialogContext).pop();
        onAlreadyChecked?.call();
      },
    ),
  );
}

class EmailVerificationInfoDialog extends StatefulWidget {
  const EmailVerificationInfoDialog({
    required this.email,
    required this.onResend,
    required this.onAlreadyChecked,
    super.key,
  });

  final String email;
  final Future<({bool success, String? errorMessage})> Function() onResend;
  final VoidCallback onAlreadyChecked;

  @override
  State<EmailVerificationInfoDialog> createState() =>
      _EmailVerificationInfoDialogState();
}

class _EmailVerificationInfoDialogState
    extends State<EmailVerificationInfoDialog> {
  bool _resending = false;
  int _resendCooldown = 0;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
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

  Future<void> _handleResend() async {
    if (_resending || _resendCooldown > 0) return;

    final firebase = getIt<FirebaseAuthService>();
    if (firebase.isEmailVerified) {
      if (!mounted) return;
      widget.onAlreadyChecked();
      return;
    }

    setState(() {
      _resending = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    final result = await widget.onResend();
    if (!mounted) return;

    setState(() {
      _resending = false;
      _feedbackIsError = !result.success;
      _feedbackMessage = result.success
          ? 'Te reenviamos el correo de verificación.'
          : result.errorMessage ??
                'No pudimos reenviar el correo. Intenta en unos segundos.';
    });

    if (result.success) {
      _startResendCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Icon(
        Icons.mark_email_unread_outlined,
        color: colorScheme.primary,
        size: 36,
      ),
      title: const Text('Revisa tu correo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.email.isNotEmpty) ...[
              Text(
                widget.email,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              'Te enviamos un correo de verificación. Puede tardar unos minutos '
              'en llegar. Si no lo ves en tu bandeja principal, revisa también '
              'la carpeta de spam, correo no deseado o promociones.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _feedbackMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: _feedbackIsError
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        CiervoButton(
          label: 'Ya revisé',
          icon: Icons.check_circle_outline,
          variant: CiervoButtonVariant.secondary,
          onPressed: widget.onAlreadyChecked,
        ),
        const SizedBox(height: AppSpacing.sm),
        CiervoButton(
          label: _resending
              ? 'Reenviando…'
              : _resendCooldown > 0
              ? 'Reenviar en ${_resendCooldown}s'
              : 'Reenviar correo',
          icon: Icons.refresh,
          state: _resending || _resendCooldown > 0
              ? CiervoButtonState.loading
              : CiervoButtonState.normal,
          onPressed: _resending || _resendCooldown > 0 ? null : _handleResend,
        ),
      ],
    );
  }
}
