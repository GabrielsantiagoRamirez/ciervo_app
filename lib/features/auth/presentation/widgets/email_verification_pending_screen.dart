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
    super.key,
  });

  final String email;
  final Future<bool> Function() onConfirmed;
  final Future<bool> Function() onResend;
  final VoidCallback onChangeEmail;

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen> {
  bool _checking = false;
  bool _resending = false;
  int _resendCooldown = 0;
  String? _message;
  bool _isSuccess = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
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

  Future<void> _pollAndConfirm() async {
    setState(() {
      _checking = true;
      _message = null;
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
        _message =
            'Aún no confirmamos tu correo. Abre el enlace del mensaje e intenta de nuevo.';
      });
      return;
    }

    final ok = await widget.onConfirmed();
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!ok) {
        _isSuccess = false;
        _message = 'No pudimos activar tu cuenta. Intenta de nuevo.';
      }
    });
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _message = null;
    });
    final ok = await widget.onResend();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _isSuccess = ok;
      _message = ok
          ? 'Te reenviamos el correo de confirmación.'
          : 'No pudimos reenviar el correo. Intenta en unos segundos.';
    });
    if (ok) _startResendCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confirma tu correo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cambiar correo',
                onPressed: widget.onChangeEmail,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(widget.email, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Revisa tu bandeja de entrada y confirma tu cuenta. '
            'Luego pulsa "Ya confirmé".',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isSuccess ? colorScheme.primary : colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
