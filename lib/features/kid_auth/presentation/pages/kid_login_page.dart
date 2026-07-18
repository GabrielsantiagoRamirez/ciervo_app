import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/device/device_installation_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/version/app_version_service.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../kids_v2/data/repositories/kids_v2_repositories.dart'
    as kids_v2;
import '../../../kids_v2/domain/models/kids_v2_models.dart';

class KidLoginPage extends StatefulWidget {
  const KidLoginPage({super.key});

  @override
  State<KidLoginPage> createState() => _KidLoginPageState();
}

class _KidLoginPageState extends State<KidLoginPage> {
  final _username = TextEditingController();
  final _pin = TextEditingController();
  bool _loading = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final pin = _pin.text.trim();
    if (username.isEmpty ||
        username.length > 50 ||
        pin.length < 4 ||
        pin.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa el usuario y usa un PIN de 4 a 12 dígitos.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final installation = getIt<DeviceInstallationService>();
    final result = await getIt<kids_v2.KidsAuthRepository>().login(
      KidPinLoginCommand(
        username: username,
        pin: pin,
        deviceId: await installation.deviceId(),
        platform: installation.platform,
        appVersion: await getIt<AppVersionService>().version(),
      ),
    );
    if (!mounted) return;
    result.when(
      success: (_) => context.go(AppRoutes.root),
      failure: (error) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_kidAuthError(error))));
      },
    );
  }

  Future<void> _submitFirebase() async {
    final firebase = getIt<FirebaseAuthService>();
    final credentials = firebase.currentUser == null
        ? await _firebaseCredentials()
        : null;
    if (firebase.currentUser == null && credentials == null) return;
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      if (credentials != null) {
        await firebase.signInWithEmail(
          email: credentials.$1,
          password: credentials.$2,
        );
      }
      final installation = getIt<DeviceInstallationService>();
      final deviceId = await installation.deviceId();
      final result = await getIt<kids_v2.KidsAuthRepository>().login(
        KidFirebaseLoginCommand(
          firebaseIdToken: await firebase.freshIdToken(),
          deviceId: deviceId,
          platform: installation.platform,
          appVersion: await getIt<AppVersionService>().version(),
        ),
      );
      if (!mounted) return;
      result.when(
        success: (_) => context.go(AppRoutes.root),
        failure: (error) async {
          setState(() => _loading = false);
          if (_isDeviceRegistrationError(error)) {
            await _showDeviceRegistrationInfo(
              firebaseUid: firebase.currentUser?.uid,
              deviceId: deviceId,
              error: error,
            );
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_kidAuthError(error))));
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
    }
  }

  Future<(String, String)?> _firebaseCredentials() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Firebase Kids'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo aprobado'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = (email.text.trim(), password.text);
              if (value.$1.isNotEmpty && value.$2.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    email.dispose();
    password.dispose();
    return result;
  }

  String _kidAuthError(Object error) {
    if (error is AppException) {
      final source = '${error.code} ${error.message}'.toUpperCase();
      if (source.contains('PENDING')) {
        return 'Este dispositivo está pendiente de aprobación del tutor.';
      }
      if (source.contains('REVOKED')) {
        return 'El tutor revocó este dispositivo. Solicita un nuevo registro.';
      }
      if (source.contains('DEVICE') &&
          (source.contains('APPROV') || source.contains('AUTHORIZED'))) {
        return 'Este dispositivo todavía no está aprobado por el tutor.';
      }
    }
    return UserErrorMessage.from(error);
  }

  bool _isDeviceRegistrationError(Object error) {
    if (error is! AppException) return false;
    final source = '${error.code} ${error.message}'.toUpperCase();
    return source.contains('DEVICE') &&
            (source.contains('PENDING') ||
                source.contains('APPROV') ||
                source.contains('AUTHORIZED') ||
                source.contains('REGISTER')) ||
        source.contains('REVOKED');
  }

  Future<void> _showDeviceRegistrationInfo({
    required String? firebaseUid,
    required String deviceId,
    required Object error,
  }) {
    final uid = firebaseUid?.trim();
    final registrationText = [
      if (uid?.isNotEmpty == true) 'Firebase UID: $uid',
      'Device ID: $deviceId',
    ].join('\n');
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.phonelink_lock_outlined),
        title: const Text('Aprobación del tutor necesaria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_kidAuthError(error)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Comparte estos datos con tu tutor para que registre y apruebe exactamente este dispositivo:',
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(registrationText),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: registrationText));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Datos del dispositivo copiados.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copiar datos'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soy hijo/a')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CiervoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ingresa con tu cuenta Kids',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Usa el usuario y PIN que te dio tu tutor.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _pin,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscurePin = !_obscurePin),
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CiervoButton(
                    label: _loading ? 'Ingresando' : 'Entrar',
                    icon: Icons.login,
                    state: _loading
                        ? CiervoButtonState.loading
                        : CiervoButtonState.normal,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CiervoButton(
                    label: 'Entrar con Firebase Kids',
                    icon: Icons.verified_user_outlined,
                    variant: CiervoButtonVariant.secondary,
                    onPressed: _loading ? null : _submitFirebase,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'La cuenta y el dispositivo Kids deben ser registrados y aprobados por el tutor principal.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
