import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/firebase_auth_cubit.dart';
import '../cubit/firebase_auth_state.dart';
import '../widgets/auth_sms_code_field.dart';

enum _RecoveryStep { email, codeAndPassword }

/// Recuperación de contraseña con OTP del backend Ciervo.
class PasswordRecoveryPage extends StatelessWidget {
  const PasswordRecoveryPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebaseAuthCubit(
        getIt<AuthRepository>(),
        getIt<FirebaseAuthService>(),
        getIt<LocationService>(),
      ),
      child: _PasswordRecoveryView(initialEmail: initialEmail),
    );
  }
}

class _PasswordRecoveryView extends StatefulWidget {
  const _PasswordRecoveryView({this.initialEmail});

  final String? initialEmail;

  @override
  State<_PasswordRecoveryView> createState() => _PasswordRecoveryViewState();
}

class _PasswordRecoveryViewState extends State<_PasswordRecoveryView> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _RecoveryStep _step = _RecoveryStep.email;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _error;
  DateTime? _resendAvailableAt;
  Timer? _resendTicker;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail?.trim();
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _resendTicker?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int get _resendSecondsLeft {
    final until = _resendAvailableAt;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  void _startResendCooldown() {
    _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
    _resendTicker?.cancel();
    _resendTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_resendSecondsLeft <= 0) {
        _resendTicker?.cancel();
      }
    });
    setState(() {});
  }

  Future<void> _requestCode({bool resend = false}) async {
    final emailError = InputValidators.email(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    if (resend && _resendSecondsLeft > 0) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await context
        .read<FirebaseAuthCubit>()
        .requestPasswordRecovery(_emailController.text);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }

    _startResendCooldown();
    setState(() {
      _step = _RecoveryStep.codeAndPassword;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitRecovery() async {
    final code = _codeController.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos.');
      return;
    }
    final passwordError = InputValidators.password(_passwordController.text);
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }
    final confirmError = InputValidators.passwordConfirmation(
      _passwordController.text,
      _confirmController.text,
    );
    if (confirmError != null) {
      setState(() => _error = confirmError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final cubit = context.read<FirebaseAuthCubit>();
    final recovered = await cubit.recoverPassword(
      email: _emailController.text,
      code: code,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;
    if (!recovered.success) {
      setState(() {
        _submitting = false;
        _error = recovered.message;
      });
      return;
    }

    final loggedIn = await cubit.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (loggedIn) {
      context.go(AppRoutes.root);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Contraseña actualizada. Inicia sesión con tu nueva clave.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FirebaseAuthCubit, FirebaseAuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          setState(() => _error = state.errorMessage);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recuperar contraseña'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _submitting
                ? null
                : () {
                    if (_step == _RecoveryStep.codeAndPassword) {
                      setState(() {
                        _step = _RecoveryStep.email;
                        _error = null;
                      });
                      return;
                    }
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: pagePaddingOf(context),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxContentWidthOf(context),
                  ),
                  child: switch (_step) {
                    _RecoveryStep.email => _emailStep(context),
                    _RecoveryStep.codeAndPassword => _codeStep(context),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailStep(BuildContext context) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Olvidé mi contraseña',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Te enviaremos un código de 6 dígitos a tu correo. '
            'Válido por 10 minutos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: _submitting ? 'Enviando' : 'Enviar código',
            icon: Icons.mark_email_unread_outlined,
            state: _submitting
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _submitting ? null : () => _requestCode(),
          ),
        ],
      ),
    );
  }

  Widget _codeStep(BuildContext context) {
    final email = _emailController.text.trim();
    final resendLeft = _resendSecondsLeft;

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Código y nueva contraseña',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enviamos un código a $email. Ingresa el código y tu nueva contraseña.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthSmsCodeField(controller: _codeController, enabled: !_submitting),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: (_submitting || resendLeft > 0)
                  ? null
                  : () => _requestCode(resend: true),
              child: Text(
                resendLeft > 0
                    ? 'Reenviar código en ${resendLeft}s'
                    : 'Reenviar código',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_submitting,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              helperText: 'Mínimo 8 caracteres',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscureConfirm
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: _submitting ? 'Guardando' : 'Restablecer e iniciar sesión',
            icon: Icons.check_circle_outline,
            state: _submitting
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _submitting ? null : _submitRecovery,
          ),
        ],
      ),
    );
  }
}
