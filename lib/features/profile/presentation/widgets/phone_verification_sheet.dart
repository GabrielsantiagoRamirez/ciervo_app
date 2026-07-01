import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../cubit/profile_cubit.dart';

Future<void> showPhoneVerificationSheet(
  BuildContext context, {
  required String phone,
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
      child: _PhoneVerificationSheet(phone: phone),
    ),
  );
}

class _PhoneVerificationSheet extends StatefulWidget {
  const _PhoneVerificationSheet({required this.phone});

  final String phone;

  @override
  State<_PhoneVerificationSheet> createState() => _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<_PhoneVerificationSheet> {
  bool _syncing = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _syncPhone() async {
    setState(() {
      _syncing = true;
      _message = null;
    });
    try {
      final firebase = getIt<FirebaseAuthService>();
      if (!firebase.isSignedIn) {
        setState(() {
          _syncing = false;
          _isSuccess = false;
          _message =
              'Inicia sesión con tu número para confirmar la verificación.';
        });
        return;
      }
      final token = await firebase.freshIdToken();
      final result = await getIt<AuthRepository>().firebaseSyncVerification(
        firebaseIdToken: token,
      );
      if (!mounted) return;
      await result.when(
        success: (_) async {
          await context.read<ProfileCubit>().loadProfile();
        },
        failure: (error) async {
          setState(() {
            _syncing = false;
            _isSuccess = false;
            _message = UserErrorMessage.from(error);
          });
        },
      );
      if (!mounted) return;
      setState(() => _syncing = false);
      final verified =
          context.read<ProfileCubit>().state.profile?.phoneVerified == true;
      if (verified) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teléfono verificado correctamente.')),
        );
        return;
      }
      setState(() {
        _isSuccess = false;
        _message =
            'Aún no pudimos confirmar el teléfono. Cierra sesión, vuelve a entrar con SMS e intenta de nuevo.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _isSuccess = false;
        _message = UserErrorMessage.from(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: CiervoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verificar teléfono',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.phone,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Si iniciaste sesión con código SMS, confirma aquí para marcar tu número como verificado.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: _syncing ? 'Confirmando…' : 'Confirmar mi número',
              icon: Icons.verified_outlined,
              state: _syncing
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _syncing ? null : _syncPhone,
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (_isSuccess
                          ? colorScheme.primaryContainer
                          : colorScheme.errorContainer)
                      .withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _isSuccess
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
