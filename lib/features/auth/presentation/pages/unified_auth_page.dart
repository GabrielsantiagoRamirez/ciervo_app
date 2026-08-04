import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/location/admin_division_models.dart';
import '../../../../core/auth/auth_pending_registration_store.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/phone_country.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/admin_division_picker.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../widgets/email_verification_info_dialog.dart';
import '../widgets/email_verification_pending_screen.dart';
import '../widgets/auth_email_verification_step.dart';
import '../widgets/migration_splash_widget.dart';
import '../../data/dtos/account_lookup_dto.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../cubit/firebase_auth_cubit.dart';
import '../cubit/firebase_auth_state.dart';

import '../../domain/entities/auth_flow.dart';

enum _EmailStep {
  enterEmail,
  chooseExistingAction,
  verifyEmail,
  enterPassword,
  emailVerificationPending,
  registerPassword,
  registerProfile,
}

/// Pantalla única de acceso por correo electrónico.
class UnifiedAuthPage extends StatelessWidget {
  const UnifiedAuthPage({super.key, this.startEmailRegistration = false});

  final bool startEmailRegistration;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(getIt<AuthRepository>())),
        BlocProvider(
          create: (_) {
            final cubit = FirebaseAuthCubit(
              getIt<AuthRepository>(),
              getIt<FirebaseAuthService>(),
              getIt<LocationService>(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cubit.captureLocation();
            });
            return cubit;
          },
        ),
      ],
      child: _UnifiedAuthView(startEmailRegistration: startEmailRegistration),
    );
  }
}

class _UnifiedAuthView extends StatefulWidget {
  const _UnifiedAuthView({required this.startEmailRegistration});

  final bool startEmailRegistration;

  @override
  State<_UnifiedAuthView> createState() => _UnifiedAuthViewState();
}

class _UnifiedAuthViewState extends State<_UnifiedAuthView> {
  // Correo
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _documentController = TextEditingController();
  _EmailStep _emailStep = _EmailStep.enterEmail;
  AccountLookupResult? _lookup;
  String _registerCountryCode = CountryRegistration.defaultCountryCode();
  AdminDivisionSelection? _emailAdminDivision;
  String _documentType = 'CC';
  bool _lookupLoading = false;
  bool _emailVerificationModalShown = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartupMessageIfNeeded();
    });
  }

  void _showStartupMessageIfNeeded() {
    final message = getIt<AuthStartupMessageStore>().consume();
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _presentEmailVerificationModalIfNeeded({String? email}) async {
    final firebase = getIt<FirebaseAuthService>();
    if (firebase.isEmailVerified || _emailVerificationModalShown || !mounted) {
      return;
    }

    final resolvedEmail = email ?? _emailController.text.trim();
    if (resolvedEmail.isEmpty) return;

    _emailVerificationModalShown = true;
    final cubit = context.read<FirebaseAuthCubit>();
    await showEmailVerificationInfoDialog(
      context,
      email: resolvedEmail,
      onResend: cubit.resendEmailVerificationWithFeedback,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  bool _requiresAdminDivision(String countryCode) =>
      countryCode == 'CO' || countryCode == 'CL';

  void _showFirebaseAuthSuccess(BuildContext context, FirebaseAuthState state) {
    final message = switch (state.authAction) {
      'link_legacy' => '¡Listo! Tu cuenta Ciervo Club está activa.',
      'register' => '¡Bienvenido a Ciervo Club!',
      _ => 'Sesión iniciada.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showEmailAuthFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _lookupEmail() async {
    final email = _emailController.text.trim();
    if (InputValidators.email(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido.')),
      );
      return;
    }
    setState(() => _lookupLoading = true);
    final countryCode = context.read<FirebaseAuthCubit>().state.countryCode;
    final result = await getIt<AuthRepository>().lookupAccount(
      email: email,
      countryCode: countryCode,
    );
    if (!mounted) return;
    setState(() => _lookupLoading = false);

    result.when(
      success: (lookup) {
        setState(() {
          _lookup = lookup;
          if (!lookup.exists) {
            _emailStep = _EmailStep.registerPassword;
            return;
          }
          if (widget.startEmailRegistration) {
            // En flujo de registro: cuenta existente → avisar e ir a login.
            _emailStep = _EmailStep.chooseExistingAction;
            return;
          }
          if (lookup.resolvedFlow == AuthFlow.legacyMigration) {
            _emailStep = _EmailStep.enterPassword;
            return;
          }
          if (lookup.shouldOfferEmailVerification) {
            _emailStep = _EmailStep.chooseExistingAction;
            return;
          }
          _emailStep = _EmailStep.enterPassword;
        });
      },
      failure: (_) {
        setState(() {
          _lookup = null;
          _emailStep = _EmailStep.registerPassword;
        });
      },
    );
  }

  Future<void> _submitEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa tu contraseña.')));
      return;
    }

    final cubit = context.read<FirebaseAuthCubit>();
    final isLegacyMigration = _lookup?.resolvedFlow == AuthFlow.legacyMigration;

    if (isLegacyMigration) {
      final ok = await cubit.migrateLegacyEmailWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (ok) {
        setState(() => _emailStep = _EmailStep.emailVerificationPending);
        await _presentEmailVerificationModalIfNeeded(email: email);
      }
      return;
    }

    final ok = await cubit.loginWithEmail(email: email, password: password);
    if (ok && mounted) context.go(AppRoutes.root);
  }

  Future<void> _submitRegisterPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (InputValidators.password(password) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 8 caracteres.'),
        ),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }
    setState(() => _emailStep = _EmailStep.registerProfile);
  }

  Future<void> _submitRegisterProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y apellido son requeridos.')),
      );
      return;
    }
    if (_requiresAdminDivision(_registerCountryCode) &&
        _emailAdminDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona departamento y ciudad.')),
      );
      return;
    }
    final ok = await context.read<FirebaseAuthCubit>().registerWithEmailAccount(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      countryCode: _registerCountryCode,
      identityDocument: _documentController.text,
      documentType: _documentType,
      city: _emailAdminDivision?.cityName,
      department: _emailAdminDivision?.departmentName,
      region: _emailAdminDivision?.regionName,
      province: _emailAdminDivision?.provinceName,
      cityCode: _emailAdminDivision?.cityCode,
    );
    if (!mounted) return;
    if (ok) {
      await _presentEmailVerificationModalIfNeeded(
        email: _emailController.text.trim(),
      );
      if (mounted) context.go(AppRoutes.root);
    }
  }

  void _routeExistingEmailToLogin() {
    setState(() => _emailStep = _EmailStep.enterPassword);
  }

  void _resetEmailFlow() {
    setState(() {
      _emailStep = _EmailStep.enterEmail;
      _lookup = null;
      _emailVerificationModalShown = false;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthSubmissionStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
            if (state.status == AuthSubmissionStatus.success) {
              context.go(AppRoutes.root);
            }
          },
        ),
        BlocListener<FirebaseAuthCubit, FirebaseAuthState>(
          listener: (context, state) {
            final onEmailVerificationStep =
                _emailStep == _EmailStep.emailVerificationPending;
            if (state.errorMessage != null &&
                state.status == FirebaseAuthStatus.failure &&
                !onEmailVerificationStep) {
              _showEmailAuthFailure(context, state.errorMessage!);
            }
            if (state.status == FirebaseAuthStatus.emailVerificationPending) {
              setState(() => _emailStep = _EmailStep.emailVerificationPending);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _presentEmailVerificationModalIfNeeded();
              });
            }
            if (state.status == FirebaseAuthStatus.success) {
              _showFirebaseAuthSuccess(context, state);
              context.go(AppRoutes.root);
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final firebaseState = context.watch<FirebaseAuthCubit>().state;
              final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
              final compactHeader =
                  keyboardOpen ||
                  _emailStep == _EmailStep.emailVerificationPending ||
                  (_emailStep == _EmailStep.enterPassword &&
                      _lookup?.resolvedFlow == AuthFlow.legacyMigration &&
                      firebaseState.status == FirebaseAuthStatus.migrating);
              return Padding(
                padding: pagePaddingOf(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (compactHeader)
                      _compactHeader(context)
                    else
                      _header(context),
                    if (!compactHeader) const SizedBox(height: AppSpacing.md),
                    Expanded(child: _emailTab(context)),
                    if (!compactHeader)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: CiervoButton(
                          label: 'Soy hijo/a',
                          variant: CiervoButtonVariant.secondary,
                          icon: Icons.child_care_outlined,
                          onPressed: () => context.go(AppRoutes.kidLogin),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _compactHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/notifications/ciervo_logo_gold.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Ciervo Club', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/notifications/ciervo_logo_gold.png',
            height: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ciervo Club',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Inicia sesión o crea tu cuenta',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emailTab(BuildContext context) {
    final firebaseState = context.watch<FirebaseAuthCubit>().state;
    final authState = context.watch<AuthCubit>().state;
    final loading =
        _lookupLoading || firebaseState.isLoading || authState.isLoading;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (_emailStep == _EmailStep.enterEmail)
          _emailEnterStep(context, loading),
        if (_emailStep == _EmailStep.chooseExistingAction)
          _emailExistingAccountStep(context),
        if (firebaseState.status == FirebaseAuthStatus.migrating &&
            _lookup?.resolvedFlow == AuthFlow.legacyMigration)
          CiervoCard(
            child: MigrationSplashWidget(
              title: 'Activando tu cuenta',
              subtitle:
                  'Estamos preparando tu acceso. Esto tomará unos segundos.',
              onRetry: _submitEmailPassword,
              showRetry: false,
            ),
          )
        else if (_emailStep == _EmailStep.verifyEmail)
          AuthEmailVerificationStep(
            email: _emailController.text.trim(),
            onVerified: _routeExistingEmailToLogin,
            onLoginInstead: _routeExistingEmailToLogin,
            onChangeEmail: _resetEmailFlow,
          )
        else if (_emailStep == _EmailStep.emailVerificationPending)
          EmailVerificationPendingScreen(
            email: _emailController.text.trim(),
            initialResendCooldown: context
                .read<FirebaseAuthCubit>()
                .emailVerificationResendCooldownSeconds,
            serverError: firebaseState.errorMessage,
            onConfirmed: () =>
                context.read<FirebaseAuthCubit>().completeLegacyEmailMigration(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                ),
            onResend: () => context
                .read<FirebaseAuthCubit>()
                .resendEmailVerificationWithFeedback(),
            onChangeEmail: _resetEmailFlow,
          )
        else if (_emailStep == _EmailStep.enterPassword)
          _emailPasswordStep(context, loading),
        if (_emailStep == _EmailStep.registerPassword)
          _emailRegisterPasswordStep(context, loading),
        if (_emailStep == _EmailStep.registerProfile)
          _emailRegisterProfileStep(context, loading),
      ],
    );
  }

  Widget _emailExistingAccountStep(BuildContext context) {
    final email = _emailController.text.trim();
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cuenta encontrada',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cambiar correo',
                onPressed: _resetEmailFlow,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(email, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _lookup?.emailVerified == false
                ? 'Este correo está registrado pero aún no está verificado.'
                : 'Este correo ya está registrado en Ciervo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: 'Iniciar sesión',
            icon: Icons.login,
            onPressed: _routeExistingEmailToLogin,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _emailStep = _EmailStep.verifyEmail),
            icon: const Icon(Icons.mark_email_unread_outlined),
            label: const Text('Verificar correo'),
          ),
        ],
      ),
    );
  }

  Widget _emailEnterStep(BuildContext context, bool loading) {
    final isRegister = widget.startEmailRegistration;
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isRegister ? 'Crear cuenta' : 'Tu correo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isRegister
                ? 'Ingresa tu correo para abrir el formulario de registro.'
                : 'Ingresa tu correo. Si no tienes cuenta, te guiaremos para crearla.',
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
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: loading
                ? 'Verificando'
                : (isRegister ? 'Continuar al registro' : 'Continuar'),
            icon: Icons.arrow_forward,
            state: loading
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: loading ? null : _lookupEmail,
          ),
          if (!isRegister)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _openPasswordRecovery,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emailPasswordStep(BuildContext context, bool loading) {
    final isLegacyMigration = _lookup?.resolvedFlow == AuthFlow.legacyMigration;
    final subtitle = isLegacyMigration
        ? 'Ingresa tu contraseña de Ciervo Club. Te enviaremos un correo de verificación.'
        : 'Ingresa la contraseña de tu cuenta.';

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bienvenido',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cambiar correo',
                onPressed: _resetEmailFlow,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(
            _emailController.text.trim(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Contraseña',
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : _openPasswordRecovery,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CiervoButton(
            label: loading
                ? (isLegacyMigration ? 'Activando' : 'Ingresando')
                : (isLegacyMigration ? 'Continuar' : 'Iniciar sesión'),
            icon: Icons.login,
            state: loading
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: loading ? null : _submitEmailPassword,
          ),
        ],
      ),
    );
  }

  void _openPasswordRecovery() {
    final email = _emailController.text.trim();
    final query = email.isEmpty
        ? AppRoutes.passwordRecovery
        : '${AppRoutes.passwordRecovery}?email=${Uri.encodeComponent(email)}';
    context.push(query);
  }

  Widget _emailRegisterPasswordStep(BuildContext context, bool loading) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Crear cuenta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cambiar correo',
                onPressed: _resetEmailFlow,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(_emailController.text.trim()),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Elige una contraseña segura. Te enviaremos verificación al correo.',
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
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
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: 'Siguiente',
            icon: Icons.arrow_forward,
            state: loading
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: loading ? null : _submitRegisterPassword,
          ),
        ],
      ),
    );
  }

  Widget _emailRegisterProfileStep(BuildContext context, bool loading) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Regístrate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cambiar correo',
                onPressed: _resetEmailFlow,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(_emailController.text.trim()),
          const SizedBox(height: AppSpacing.sm),
          const Text('Completa los datos de tu cuenta Ciervo Club.'),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Apellido'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _registerCountryCode,
            decoration: const InputDecoration(labelText: 'País'),
            items: PhoneCountry.options
                .map(
                  (item) => DropdownMenuItem(
                    value: item.countryCode,
                    child: Text('${item.flag} ${item.label}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _registerCountryCode = value;
                _documentType = CountryRegistration.adultDocumentOptions(
                  value,
                ).first.code;
                _emailAdminDivision = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: const InputDecoration(labelText: 'Tipo de documento'),
            items:
                CountryRegistration.adultDocumentOptions(_registerCountryCode)
                    .map(
                      (o) =>
                          DropdownMenuItem(value: o.code, child: Text(o.label)),
                    )
                    .toList(),
            onChanged: (v) =>
                setState(() => _documentType = v ?? _documentType),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _documentController,
            decoration: const InputDecoration(labelText: 'Número de documento'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_requiresAdminDivision(_registerCountryCode)) ...[
            AdminDivisionPicker(
              countryCode: _registerCountryCode,
              initialSelection: _emailAdminDivision,
              onChanged: (value) => setState(() => _emailAdminDivision = value),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          CiervoButton(
            label: loading ? 'Creando cuenta' : 'Crear cuenta',
            icon: Icons.check,
            state: loading
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: loading ? null : _submitRegisterProfile,
          ),
        ],
      ),
    );
  }
}
