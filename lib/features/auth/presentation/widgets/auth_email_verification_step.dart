import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/repositories/auth_repository.dart';

/// Verificación de correo durante login/registro (sin sesión activa).
class AuthEmailVerificationStep extends StatefulWidget {
  const AuthEmailVerificationStep({
    required this.email,
    required this.onVerified,
    required this.onLoginInstead,
    required this.onChangeEmail,
    super.key,
  });

  final String email;
  final VoidCallback onVerified;
  final VoidCallback onLoginInstead;
  final VoidCallback onChangeEmail;

  @override
  State<AuthEmailVerificationStep> createState() =>
      _AuthEmailVerificationStepState();
}

class _AuthEmailVerificationStepState extends State<AuthEmailVerificationStep> {
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = widget.email.trim();
    final emailError = InputValidators.email(email);
    if (emailError != null) {
      setState(() {
        _message = emailError;
        _isSuccess = false;
      });
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });
    final result =
        await getIt<AuthRepository>().sendEmailVerificationCode(email);
    if (!mounted) return;
    setState(() {
      _sending = false;
      result.when(
        success: (_) {
          _codeSent = true;
          _isSuccess = true;
          _message = 'Te enviamos un código a $email.';
        },
        failure: (error) {
          _isSuccess = false;
          _message = UserErrorMessage.from(error);
        },
      );
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _message = 'Ingresa el código que recibiste.';
        _isSuccess = false;
      });
      return;
    }
    setState(() {
      _verifying = true;
      _message = null;
    });
    final result = await getIt<AuthRepository>().verifyEmailCode(
      email: widget.email.trim(),
      code: code,
    );
    if (!mounted) return;
    var verified = false;
    setState(() {
      _verifying = false;
      result.when(
        success: (_) {
          verified = true;
          _isSuccess = true;
          _message = 'Correo verificado. Ya puedes iniciar sesión.';
        },
        failure: (error) {
          _isSuccess = false;
          _message = UserErrorMessage.from(error);
        },
      );
    });
    if (verified) widget.onVerified();
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
                  'Verificar correo',
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
            'Este correo ya está registrado pero aún no está verificado. '
            'Confírmalo con el código o inicia sesión si ya lo verificaste.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: _sending ? 'Enviando…' : 'Enviar código',
            icon: Icons.mail_outline,
            state: _sending
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _sending ? null : _sendCode,
          ),
          if (_codeSent) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CiervoButton(
              label: _verifying ? 'Verificando…' : 'Confirmar código',
              icon: Icons.verified_outlined,
              state: _verifying
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _verifying ? null : _verifyCode,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: widget.onLoginInstead,
            icon: const Icon(Icons.login),
            label: const Text('Iniciar sesión con contraseña'),
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isSuccess
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
