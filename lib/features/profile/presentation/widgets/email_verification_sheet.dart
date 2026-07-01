import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../cubit/profile_cubit.dart';

Future<void> showEmailVerificationSheet(
  BuildContext context, {
  required String email,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
      ),
      child: _EmailVerificationSheet(email: email.trim()),
    ),
  );
}

class _EmailVerificationSheet extends StatefulWidget {
  const _EmailVerificationSheet({required this.email});

  final String email;

  @override
  State<_EmailVerificationSheet> createState() =>
      _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<_EmailVerificationSheet> {
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _message = null;
    });
    final result =
        await getIt<AuthRepository>().sendEmailVerificationCode(widget.email);
    if (!mounted) return;
    setState(() {
      _sending = false;
      result.when(
        success: (_) {
          _codeSent = true;
          _message = 'Te enviamos un código a ${widget.email}. Revisa tu bandeja.';
        },
        failure: (error) {
          _message = UserErrorMessage.from(error);
        },
      );
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = 'Ingresa el código que recibiste.');
      return;
    }
    setState(() {
      _verifying = true;
      _message = null;
    });
    await context.read<ProfileCubit>().verifyEmailWithCode(code);
    if (!mounted) return;
    setState(() => _verifying = false);
    final error = context.read<ProfileCubit>().state.errorMessage;
    if (error != null && error.isNotEmpty) {
      setState(() => _message = error);
      return;
    }
    if (context.read<ProfileCubit>().state.profile?.emailVerified == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo verificado correctamente.')),
      );
    }
  }

  Future<void> _openEmailApp() async {
    final uri = Uri(scheme: 'mailto');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verificar correo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Te enviaremos un código a tu correo. También puedes abrir tu app de email '
              'y usar el enlace o código que llegue de Ciervo Club.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: _sending ? 'Enviando…' : 'Enviar código al correo',
              icon: Icons.mail_outline,
              state: _sending ? CiervoButtonState.loading : CiervoButtonState.normal,
              onPressed: _sending ? null : _sendCode,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _openEmailApp,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir mi correo'),
            ),
            if (_codeSent) ...[
              const SizedBox(height: AppSpacing.lg),
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
                state:
                    _verifying ? CiervoButtonState.loading : CiervoButtonState.normal,
                onPressed: _verifying ? null : _verifyCode,
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _message!.contains('enviamos')
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
