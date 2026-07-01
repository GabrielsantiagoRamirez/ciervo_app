import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../cubit/profile_cubit.dart';

Future<void> showEmailVerificationSheet(
  BuildContext context, {
  String? email,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
      ),
      child: _EmailVerificationSheet(initialEmail: email?.trim() ?? ''),
    ),
  );
}

class _EmailVerificationSheet extends StatefulWidget {
  const _EmailVerificationSheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_EmailVerificationSheet> createState() =>
      _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<_EmailVerificationSheet> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  String? _message;
  bool _isSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? _validatedEmail() {
    final email = _emailController.text.trim();
    return InputValidators.email(email);
  }

  Future<void> _sendCode() async {
    final emailError = _validatedEmail();
    if (emailError != null) {
      setState(() {
        _message = emailError;
        _isSuccessMessage = false;
      });
      return;
    }
    final email = _emailController.text.trim();

    setState(() {
      _sending = true;
      _message = null;
    });
    final result = await getIt<AuthRepository>().sendEmailVerificationCode(email);
    if (!mounted) return;
    setState(() {
      _sending = false;
      result.when(
        success: (_) {
          _codeSent = true;
          _isSuccessMessage = true;
          _message = 'Te enviamos un código a $email. Revisa tu bandeja.';
        },
        failure: (error) {
          _isSuccessMessage = false;
          _message = UserErrorMessage.from(error);
        },
      );
    });
  }

  Future<void> _verifyCode() async {
    final emailError = _validatedEmail();
    if (emailError != null) {
      setState(() {
        _message = emailError;
        _isSuccessMessage = false;
      });
      return;
    }
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _message = 'Ingresa el código que recibiste.';
        _isSuccessMessage = false;
      });
      return;
    }
    setState(() {
      _verifying = true;
      _message = null;
    });
    final email = _emailController.text.trim();
    final auth = getIt<AuthRepository>();
    final profileCubit = context.read<ProfileCubit>();
    final result = await auth.verifyEmailCode(email: email, code: code);
    if (!mounted) return;
    await result.when(
      success: (_) async {
        await profileCubit.syncFirebaseVerification();
        await profileCubit.loadProfile();
      },
      failure: (error) async {
        setState(() {
          _verifying = false;
          _isSuccessMessage = false;
          _message = UserErrorMessage.from(error);
        });
      },
    );
    if (!mounted) return;
    setState(() => _verifying = false);
    final profile = profileCubit.state.profile;
    if (profile?.emailVerified == true) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verificar correo',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Confirma tu correo para recibir el código de verificación.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CiervoButton(
                label: _sending ? 'Enviando…' : 'Enviar código al correo',
                icon: Icons.mail_outline,
                state: _sending
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
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
                  state: _verifying
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _verifying ? null : _verifyCode,
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (_isSuccessMessage
                            ? colorScheme.primaryContainer
                            : colorScheme.errorContainer)
                        .withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: _isSuccessMessage
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
