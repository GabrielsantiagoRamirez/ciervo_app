import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../data/repositories/kid_auth_repository_impl.dart';

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
    if (username.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa usuario y PIN.')),
      );
      return;
    }
    setState(() => _loading = true);
    final result = await getIt<KidAuthRepository>().kidLogin(
      username: username,
      pin: pin,
    );
    if (!mounted) return;
    await result.when(
      success: (session) async {
        await getIt<SessionManager>().saveTokens(session.tokens);
        if (!mounted) return;
        context.go(AppRoutes.root);
      },
      failure: (error) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
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
                    label: 'Crear cuenta',
                    variant: CiervoButtonVariant.secondary,
                    icon: Icons.person_add_alt_1,
                    onPressed: _loading
                        ? null
                        : () => context.go(AppRoutes.kidRegister),
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
