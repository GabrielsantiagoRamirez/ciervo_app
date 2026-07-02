import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/firebase/phone_country.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import 'auth_sms_code_field.dart';

/// Pantalla de ingreso de código OTP de 6 dígitos.
class OtpCodeScreen extends StatefulWidget {
  const OtpCodeScreen({
    super.key,
    required this.phoneE164,
    required this.controller,
    required this.isLoading,
    required this.onConfirm,
    required this.onResend,
  });

  final String phoneE164;
  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onConfirm;
  final VoidCallback onResend;

  @override
  State<OtpCodeScreen> createState() => _OtpCodeScreenState();
}

class _OtpCodeScreenState extends State<OtpCodeScreen> {
  static const _resendCooldownSeconds = 60;

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
        return;
      }
      setState(() => _cooldownRemaining -= 1);
    });
  }

  void _handleResend() {
    widget.onResend();
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masked = PhoneCountry.maskForOtp(widget.phoneE164);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ingresa el código', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enviamos un código de 6 dígitos a $masked.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthSmsCodeField(
          controller: widget.controller,
          enabled: !widget.isLoading,
          onCompleted: widget.isLoading ? null : widget.onConfirm,
        ),
        const SizedBox(height: AppSpacing.lg),
        CiervoButton(
          label: widget.isLoading ? 'Verificando' : 'Confirmar',
          icon: Icons.verified_outlined,
          state: widget.isLoading
              ? CiervoButtonState.loading
              : CiervoButtonState.normal,
          onPressed: widget.isLoading
              ? null
              : () => widget.onConfirm(widget.controller.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _cooldownRemaining > 0 || widget.isLoading
              ? null
              : _handleResend,
          child: Text(
            _cooldownRemaining > 0
                ? 'Reenviar código (${_cooldownRemaining}s)'
                : 'Reenviar código',
          ),
        ),
      ],
    );
  }
}
