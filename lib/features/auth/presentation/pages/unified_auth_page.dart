import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/country_registration.dart';
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
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../widgets/email_verification_info_dialog.dart';
import '../widgets/email_verification_pending_screen.dart';
import '../widgets/auth_email_verification_step.dart';
import '../widgets/migration_splash_widget.dart';
import '../widgets/otp_code_screen.dart';
import '../../data/dtos/account_lookup_dto.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../cubit/firebase_auth_cubit.dart';
import '../cubit/firebase_auth_state.dart';

import '../../domain/entities/auth_flow.dart';

enum _PhoneStep {
  entry,
  migrationSplash,
  otp,
  profile,
}

enum _EmailStep {
  enterEmail,
  chooseExistingAction,
  verifyEmail,
  enterPassword,
  emailVerificationPending,
  registerPassword,
  registerProfile,
}

/// Pantalla única de acceso: teléfono (Firebase SMS) o correo (lookup + login/registro).
class UnifiedAuthPage extends StatelessWidget {
  const UnifiedAuthPage({
    super.key,
    this.startEmailRegistration = false,
  });

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

class _UnifiedAuthViewState extends State<_UnifiedAuthView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Teléfono
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  String _phoneCountryCode = CountryRegistration.defaultCountryCode();
  _PhoneStep _phoneStep = _PhoneStep.entry;
  bool _phoneLookupLoading = false;
  bool _migrationTimedOut = false;

  // Correo
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _cityController = TextEditingController();
  _EmailStep _emailStep = _EmailStep.enterEmail;
  AccountLookupResult? _lookup;
  String _registerCountryCode = CountryRegistration.defaultCountryCode();
  String _documentType = 'CC';
  bool _lookupLoading = false;
  bool _emailVerificationModalShown = false;
  Timer? _migrationTimeoutTimer;

  void _startMigrationTimeoutTimer() {
    _migrationTimeoutTimer?.cancel();
    _migrationTimeoutTimer = Timer(const Duration(seconds: 90), () {
      if (!mounted || _phoneStep != _PhoneStep.migrationSplash) return;
      setState(() => _migrationTimedOut = true);
    });
  }

  void _cancelMigrationTimeoutTimer() {
    _migrationTimeoutTimer?.cancel();
    _migrationTimeoutTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startEmailRegistration ? 1 : 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingRegistrationIfNeeded();
      _showStartupMessageIfNeeded();
    });
  }

  void _applyPendingRegistrationIfNeeded() {
    final pending = getIt<AuthPendingRegistrationStore>();
    if (!pending.hasPending || !mounted) return;

    context.read<FirebaseAuthCubit>().restorePendingPhoneRegistration(
          phoneNational: pending.phoneNational!,
          phoneE164: pending.phoneE164 ?? '',
          countryCode: pending.countryCode ?? CountryRegistration.defaultCountryCode(),
        );
    setState(() {
      _phoneCountryCode =
          pending.countryCode ?? CountryRegistration.defaultCountryCode();
      _phoneStep = _PhoneStep.profile;
    });
    pending.clear();
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
    _cancelMigrationTimeoutTimer();
    _tabs.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _registerPhoneController.dispose();
    _documentController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String _nationalPhoneDigits() => PhoneCountry.nationalDigits(
        countryCode: _phoneCountryCode,
        rawInput: _phoneController.text,
      );

  void _showFirebaseAuthSuccess(BuildContext context, FirebaseAuthState state) {
    final message = switch (state.authAction) {
      'link_legacy' => '¡Listo! Tu cuenta Ciervo Club está activa.',
      'register' => '¡Bienvenido a Ciervo Club!',
      _ => 'Sesión iniciada.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handlePhoneVerified(
    BuildContext context,
    FirebaseAuthState state,
  ) async {
    if (state.shouldFirebaseLogin) {
      final email = _emailController.text.trim();
      final ok = await context.read<FirebaseAuthCubit>().firebaseLoginExisting(
            email: email.contains('@') ? email : null,
          );
      if (ok && context.mounted) {
        // Navegación en listener success + toast authAction.
      }
      return;
    }
    if (!context.mounted) return;
    setState(() => _phoneStep = _PhoneStep.profile);
  }

  Future<void> _startPhoneSmsFlow(BuildContext context) async {
    if (_phoneStep == _PhoneStep.otp) return;

    final national = _nationalPhoneDigits();
    if (national.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu número de teléfono.')),
      );
      return;
    }

    final e164 = PhoneCountry.toE164(
      countryCode: _phoneCountryCode,
      nationalNumber: national,
    );
    final phoneLabel = PhoneCountry.formatForDisplay(e164);

    setState(() => _phoneLookupLoading = true);
    final result = await getIt<AuthRepository>().lookupAccount(
      phone: national,
      countryCode: _phoneCountryCode,
    );
    if (!mounted) return;
    setState(() => _phoneLookupLoading = false);

    AccountLookupResult? lookup;
    result.when(
      success: (value) => lookup = value,
      failure: (_) => lookup = null,
    );

    if (!context.mounted) return;

    if (lookup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos verificar tu número. Intenta de nuevo.'),
        ),
      );
      return;
    }

    final resolved = lookup!;
    setState(() {
      _migrationTimedOut = false;
    });

    if (resolved.resolvedFlow == AuthFlow.legacyMigration) {
      setState(() {
        _phoneStep = _PhoneStep.migrationSplash;
        _migrationTimedOut = false;
      });
      _startMigrationTimeoutTimer();
      if (!context.mounted) return;
      await context.read<FirebaseAuthCubit>().sendPhoneCode(
            countryCode: _phoneCountryCode,
            nationalNumber: national,
            lookup: resolved,
          );
      return;
    }

    if (resolved.exists) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Iniciar sesión'),
          content: Text(
            'Encontramos tu cuenta con $phoneLabel. '
            'Te enviaremos un código para entrar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar código'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    } else {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Crear cuenta'),
          content: Text(
            'No encontramos cuenta con $phoneLabel. '
            '¿Quieres crear una cuenta nueva?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    await context.read<FirebaseAuthCubit>().sendPhoneCode(
          countryCode: _phoneCountryCode,
          nationalNumber: national,
          lookup: resolved,
        );
  }

  void _showPhoneAuthFailure(BuildContext context, String message) {
    final blocked = message.toLowerCase().contains('blocked') ||
        message.toLowerCase().contains('demasiados intentos');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        action: blocked
            ? SnackBarAction(
                label: 'Usar correo',
                textColor: Colors.white,
                onPressed: () => _tabs.animateTo(1),
              )
            : null,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu contraseña.')),
      );
      return;
    }

    final cubit = context.read<FirebaseAuthCubit>();
    final isLegacyMigration =
        _lookup?.resolvedFlow == AuthFlow.legacyMigration;

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

    final ok = await cubit.loginWithEmail(
      email: email,
      password: password,
    );
    if (ok && mounted) context.go(AppRoutes.root);
  }

  Future<void> _submitRegisterPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (InputValidators.password(password) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres.')),
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
    if (_registerPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El teléfono es requerido para tu cuenta.')),
      );
      return;
    }
    final registerPhone = PhoneCountry.nationalDigits(
      countryCode: _registerCountryCode,
      rawInput: _registerPhoneController.text,
    );
    if (registerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un teléfono válido.')),
      );
      return;
    }
    final ok = await context.read<FirebaseAuthCubit>().registerWithEmailAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          countryCode: _registerCountryCode,
          phoneNational: registerPhone,
          identityDocument: _documentController.text,
          documentType: _documentType,
          city: _cityController.text,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
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
              _showPhoneAuthFailure(context, state.errorMessage!);
              if (_phoneStep == _PhoneStep.migrationSplash ||
                  _phoneStep == _PhoneStep.otp) {
                setState(() {
                  _phoneStep = _PhoneStep.entry;
                  _migrationTimedOut = false;
                });
                _cancelMigrationTimeoutTimer();
              }
            }
            if (state.status == FirebaseAuthStatus.codeSent) {
              setState(() {
                _phoneStep = _PhoneStep.otp;
                _migrationTimedOut = false;
              });
              _cancelMigrationTimeoutTimer();
            }
            if (state.status == FirebaseAuthStatus.phoneVerified) {
              _handlePhoneVerified(context, state);
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
              final keyboardOpen =
                  MediaQuery.viewInsetsOf(context).bottom > 0;
              final compactHeader = keyboardOpen ||
                  _phoneStep == _PhoneStep.otp ||
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
                    TabBar(
                      controller: _tabs,
                      tabs: const [
                        Tab(text: 'Teléfono'),
                        Tab(text: 'Correo'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _phoneTab(context),
                          _emailTab(context),
                        ],
                      ),
                    ),
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
          Text(
            'Ciervo Club',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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

  Widget _phoneTab(BuildContext context) {
    final state = context.watch<FirebaseAuthCubit>().state;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (state.latitude != null && _phoneStep == _PhoneStep.entry)
          CiervoCard(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Ubicación detectada'),
              subtitle: Text(
                'País sugerido: ${state.countryCode.isNotEmpty ? state.countryCode : _phoneCountryCode}',
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (_phoneStep == _PhoneStep.entry) _phoneNumberStep(context, state),
        if (_phoneStep == _PhoneStep.migrationSplash)
          CiervoCard(
            child: MigrationSplashWidget(
              isLoading: state.status == FirebaseAuthStatus.migrating ||
                  state.status == FirebaseAuthStatus.loading,
              showRetry: _migrationTimedOut ||
                  state.status == FirebaseAuthStatus.failure,
              errorMessage: state.status == FirebaseAuthStatus.failure
                  ? state.errorMessage
                  : null,
              onRetry: () {
                setState(() => _migrationTimedOut = false);
                _startMigrationTimeoutTimer();
                _startPhoneSmsFlow(context);
              },
            ),
          ),
        if (_phoneStep == _PhoneStep.otp) _phoneOtpStep(context, state),
        if (_phoneStep == _PhoneStep.profile) _phoneProfileStep(context, state),
      ],
    );
  }

  Widget _phoneNumberStep(BuildContext context, FirebaseAuthState state) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verifica tu teléfono', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const Text('Te enviaremos un código de verificación por SMS.'),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _phoneCountryCode,
            decoration: const InputDecoration(labelText: 'País'),
            items: PhoneCountry.options
                .map(
                  (item) => DropdownMenuItem(
                    value: item.countryCode,
                    child: Text('${item.flag} ${item.label} (${item.dialCode})'),
                  ),
                )
                .toList(),
            onChanged: state.isLoading
                ? null
                : (value) {
                    if (value != null) setState(() => _phoneCountryCode = value);
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Text(
                  PhoneCountry.byCountryCode(_phoneCountryCode).dialCode,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: _phoneLookupLoading
                ? 'Consultando…'
                : state.isLoading
                    ? 'Enviando'
                    : 'Enviar código',
            icon: Icons.sms_outlined,
            state: _phoneLookupLoading || state.isLoading
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _phoneLookupLoading || state.isLoading
                ? null
                : () => _startPhoneSmsFlow(context),
          ),
        ],
      ),
    );
  }

  Widget _phoneOtpStep(BuildContext context, FirebaseAuthState state) {
    final e164 = state.phoneE164 ??
        PhoneCountry.toE164(
          countryCode: _phoneCountryCode,
          nationalNumber: _nationalPhoneDigits(),
        );

    return CiervoCard(
      child: OtpCodeScreen(
        phoneE164: e164,
        controller: _smsController,
        isLoading: state.isLoading,
        onConfirm: (code) =>
            context.read<FirebaseAuthCubit>().confirmPhoneCode(code),
        onResend: () => context.read<FirebaseAuthCubit>().resendPhoneCode(),
      ),
    );
  }

  Widget _phoneProfileStep(BuildContext context, FirebaseAuthState state) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Completa tu perfil', style: Theme.of(context).textTheme.titleLarge),
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
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo (opcional)',
              helperText: 'Si lo ingresas, te enviaremos un código de verificación.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: const InputDecoration(labelText: 'Tipo de documento'),
            items: CountryRegistration.adultDocumentOptions(_phoneCountryCode)
                .map((o) => DropdownMenuItem(value: o.code, child: Text(o.label)))
                .toList(),
            onChanged: (v) => setState(() => _documentType = v ?? _documentType),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _documentController,
            decoration: const InputDecoration(labelText: 'Número de documento'),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: state.isLoading ? 'Creando cuenta' : 'Crear cuenta',
            icon: Icons.check,
            state: state.isLoading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: state.isLoading
                ? null
                : () async {
                    await context.read<FirebaseAuthCubit>().firebaseRegisterProfile(
                          firstName: _firstNameController.text,
                          lastName: _lastNameController.text,
                          email: _emailController.text,
                          identityDocument: _documentController.text,
                          documentType: _documentType,
                          city: _cityController.text,
                        );
                  },
          ),
        ],
      ),
    );
  }

  Widget _emailTab(BuildContext context) {
    final firebaseState = context.watch<FirebaseAuthCubit>().state;
    final authState = context.watch<AuthCubit>().state;
    final loading = _lookupLoading ||
        firebaseState.isLoading ||
        authState.isLoading;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (_emailStep == _EmailStep.enterEmail) _emailEnterStep(context, loading),
        if (_emailStep == _EmailStep.chooseExistingAction)
          _emailExistingAccountStep(context),
        if (firebaseState.status == FirebaseAuthStatus.migrating &&
            _lookup?.resolvedFlow == AuthFlow.legacyMigration)
          CiervoCard(
            child: MigrationSplashWidget(
              title: 'Activando tu cuenta',
              subtitle: 'Estamos preparando tu acceso. Esto tomará unos segundos.',
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
            initialResendCooldown:
                context.read<FirebaseAuthCubit>().emailVerificationResendCooldownSeconds,
            serverError: firebaseState.errorMessage,
            onConfirmed: () => context.read<FirebaseAuthCubit>().completeLegacyEmailMigration(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                ),
            onResend: () =>
                context.read<FirebaseAuthCubit>().resendEmailVerificationWithFeedback(),
            onChangeEmail: _resetEmailFlow,
          )
        else if (_emailStep == _EmailStep.enterPassword)
          _emailPasswordStep(context, loading),
        if (_emailStep == _EmailStep.registerPassword) _emailRegisterPasswordStep(context, loading),
        if (_emailStep == _EmailStep.registerProfile) _emailRegisterProfileStep(context, loading),
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
            onPressed: () => setState(() => _emailStep = _EmailStep.verifyEmail),
            icon: const Icon(Icons.mark_email_unread_outlined),
            label: const Text('Verificar correo'),
          ),
        ],
      ),
    );
  }

  Widget _emailEnterStep(BuildContext context, bool loading) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tu correo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ingresa tu correo. Si no tienes cuenta, te guiaremos para crearla.',
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
            label: loading ? 'Verificando' : 'Continuar',
            icon: Icons.arrow_forward,
            state: loading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: loading ? null : _lookupEmail,
          ),
        ],
      ),
    );
  }

  Widget _emailPasswordStep(BuildContext context, bool loading) {
    final isLegacyMigration =
        _lookup?.resolvedFlow == AuthFlow.legacyMigration;
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
                child: Text('Bienvenido', style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                tooltip: 'Cambiar correo',
                onPressed: _resetEmailFlow,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(_emailController.text.trim(), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: loading
                ? (isLegacyMigration ? 'Activando' : 'Ingresando')
                : (isLegacyMigration ? 'Continuar' : 'Iniciar sesión'),
            icon: Icons.login,
            state: loading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: loading ? null : _submitEmailPassword,
          ),
        ],
      ),
    );
  }

  Widget _emailRegisterPasswordStep(BuildContext context, bool loading) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Crear cuenta', style: Theme.of(context).textTheme.titleLarge),
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
          const Text('Elige una contraseña segura. Te enviaremos verificación al correo.'),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: 'Siguiente',
            icon: Icons.arrow_forward,
            state: loading ? CiervoButtonState.loading : CiervoButtonState.normal,
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
          Text('Tu perfil', style: Theme.of(context).textTheme.titleLarge),
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
                _documentType =
                    CountryRegistration.adultDocumentOptions(value).first.code;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _registerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixText: '${PhoneCountry.byCountryCode(_registerCountryCode).dialCode} ',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: const InputDecoration(labelText: 'Tipo de documento'),
            items: CountryRegistration.adultDocumentOptions(_registerCountryCode)
                .map((o) => DropdownMenuItem(value: o.code, child: Text(o.label)))
                .toList(),
            onChanged: (v) => setState(() => _documentType = v ?? _documentType),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _documentController,
            decoration: const InputDecoration(labelText: 'Número de documento'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Ciudad (opcional)'),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: loading ? 'Creando cuenta' : 'Crear cuenta',
            icon: Icons.check,
            state: loading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: loading ? null : _submitRegisterProfile,
          ),
        ],
      ),
    );
  }
}
