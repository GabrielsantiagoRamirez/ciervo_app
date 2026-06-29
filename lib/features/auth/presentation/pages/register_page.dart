// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(getIt<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _documentType = 'CC';
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await context.read<AuthCubit>().register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          identityDocument: _documentController.text,
          documentType: _documentType,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthSubmissionStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: CiervoCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Crear cuenta',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Completa tus datos para activar tu acceso.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TextFormField(
                            controller: _firstNameController,
                            validator: (value) =>
                                InputValidators.requiredText(value ?? '', 'tu nombre'),
                            decoration: const InputDecoration(
                              hintText: 'Nombre',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _lastNameController,
                            validator: (value) =>
                                InputValidators.requiredText(value ?? '', 'tu apellido'),
                            decoration: const InputDecoration(
                              hintText: 'Apellido',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                InputValidators.email(value ?? ''),
                            decoration: const InputDecoration(
                              hintText: 'Correo electronico',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                InputValidators.phone(value ?? ''),
                            decoration: const InputDecoration(
                              hintText: 'Telefono',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            value: _documentType,
                            items: const [
                              DropdownMenuItem(value: 'CC', child: Text('Cedula')),
                              DropdownMenuItem(value: 'CE', child: Text('Cedula extranjeria')),
                              DropdownMenuItem(value: 'PASSPORT', child: Text('Pasaporte')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _documentType = value);
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Tipo de documento',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _documentController,
                            validator: (value) =>
                                InputValidators.requiredText(value ?? '', 'tu documento'),
                            decoration: const InputDecoration(
                              hintText: 'Documento',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            validator: (value) =>
                                InputValidators.password(value ?? ''),
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            validator: (value) =>
                                InputValidators.passwordConfirmation(
                              _passwordController.text,
                              value ?? '',
                            ),
                            decoration: InputDecoration(
                              hintText: 'Confirmar contraseña',
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                tooltip: _showConfirmPassword
                                    ? 'Ocultar confirmacion'
                                    : 'Mostrar confirmacion',
                                onPressed: () => setState(
                                  () => _showConfirmPassword =
                                      !_showConfirmPassword,
                                ),
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CiervoButton(
                            label: state.isLoading
                                ? 'Creando cuenta'
                                : 'Registrarme',
                            icon: Icons.app_registration,
                            state: state.isLoading
                                ? CiervoButtonState.loading
                                : CiervoButtonState.normal,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CiervoButton(
                            label: 'Ya tengo cuenta',
                            variant: CiervoButtonVariant.secondary,
                            icon: Icons.arrow_back,
                            onPressed: () => context.go(AppRoutes.login),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
