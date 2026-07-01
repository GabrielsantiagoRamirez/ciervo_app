import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/country_registration.dart';
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
import '../../data/dtos/account_lookup_dto.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../cubit/firebase_auth_cubit.dart';
import '../cubit/firebase_auth_state.dart';

enum _EmailStep { enterEmail, enterPassword, registerPassword, registerProfile }

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
          create: (_) => FirebaseAuthCubit(
            getIt<AuthRepository>(),
            getIt<FirebaseAuthService>(),
            getIt<LocationService>(),
          )..captureLocation(),
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
  bool _smsSent = false;
  int _phoneStep = 0;

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
  bool _useFirebasePassword = false;
  bool _autoDetectPassword = false;
  String _registerCountryCode = CountryRegistration.defaultCountryCode();
  String _documentType = 'CC';
  bool _lookupLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startEmailRegistration ? 1 : 0,
    );
  }

  @override
  void dispose() {
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

  Future<void> _lookupEmail() async {
    final email = _emailController.text.trim();
    if (InputValidators.email(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido.')),
      );
      return;
    }
    setState(() => _lookupLoading = true);
    final result = await getIt<AuthRepository>().lookupAccount(email: email);
    if (!mounted) return;
    setState(() => _lookupLoading = false);

    result.when(
      success: (lookup) {
        setState(() {
          _lookup = lookup;
          _autoDetectPassword = false;
          if (lookup.isRegister) {
            _emailStep = _EmailStep.registerPassword;
            _useFirebasePassword = true;
          } else if (lookup.isLegacyLogin) {
            _emailStep = _EmailStep.enterPassword;
            _useFirebasePassword = false;
          } else {
            _emailStep = _EmailStep.enterPassword;
            _useFirebasePassword = true;
          }
        });
      },
      failure: (_) {
        setState(() {
          _lookup = null;
          _emailStep = _EmailStep.enterPassword;
          _autoDetectPassword = true;
          _useFirebasePassword = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos verificar el correo. Ingresa tu contraseña o crea una cuenta nueva.',
            ),
          ),
        );
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

    if (_autoDetectPassword) {
      await context.read<AuthCubit>().login(email: email, password: password);
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState.status == AuthSubmissionStatus.success) return;

      final firebaseOk = await context.read<FirebaseAuthCubit>().loginWithEmail(
            email: email,
            password: password,
          );
      if (firebaseOk && mounted) {
        context.go(AppRoutes.root);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No encontramos esa cuenta. ¿Quieres registrarte?'),
          action: SnackBarAction(
            label: 'Crear cuenta',
            onPressed: () => setState(() {
              _emailStep = _EmailStep.registerPassword;
              _useFirebasePassword = true;
            }),
          ),
        ),
      );
      return;
    }

    if (_useFirebasePassword) {
      final ok = await context.read<FirebaseAuthCubit>().loginWithEmail(
            email: email,
            password: password,
          );
      if (ok && mounted) context.go(AppRoutes.root);
    } else {
      await context.read<AuthCubit>().login(email: email, password: password);
    }
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
    final ok = await context.read<FirebaseAuthCubit>().registerWithEmailAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          countryCode: _registerCountryCode,
          phoneNational: _registerPhoneController.text,
          identityDocument: _documentController.text,
          documentType: _documentType,
          city: _cityController.text,
        );
    if (ok && mounted) context.go(AppRoutes.root);
  }

  void _resetEmailFlow() {
    setState(() {
      _emailStep = _EmailStep.enterEmail;
      _lookup = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _autoDetectPassword = false;
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
            if (state.errorMessage != null &&
                state.status != FirebaseAuthStatus.phoneVerified) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            if (state.status == FirebaseAuthStatus.codeSent) {
              setState(() {
                _smsSent = true;
                _phoneStep = 1;
              });
            }
            if (state.status == FirebaseAuthStatus.phoneVerified) {
              if (state.userExists) {
                context.read<FirebaseAuthCubit>().firebaseLoginExisting().then((ok) {
                  if (ok && context.mounted) context.go(AppRoutes.root);
                });
              } else {
                setState(() => _phoneStep = 2);
              }
            }
            if (state.status == FirebaseAuthStatus.success && _tabs.index == 0) {
              context.go(AppRoutes.root);
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: responsivePage(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                const SizedBox(height: AppSpacing.md),
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
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: CiervoButton(
                    label: 'Soy hijo/a',
                    variant: CiervoButtonVariant.secondary,
                    icon: Icons.child_care_outlined,
                    onPressed: () => context.go(AppRoutes.kidLogin),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      children: [
        if (state.latitude != null)
          CiervoCard(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Ubicación detectada'),
              subtitle: Text('País sugerido: ${state.countryCode.isNotEmpty ? state.countryCode : _phoneCountryCode}'),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (_phoneStep == 0) _phoneNumberStep(context, state),
        if (_phoneStep == 1) _phoneSmsStep(context, state),
        if (_phoneStep == 2) _phoneProfileStep(context, state),
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
          const Text('Te enviaremos un código SMS con Firebase.'),
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
              prefixText: '${PhoneCountry.byCountryCode(_phoneCountryCode).dialCode} ',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: state.isLoading
                ? 'Enviando'
                : (_smsSent ? 'Continuar' : 'Enviar código'),
            icon: Icons.sms_outlined,
            state: state.isLoading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: state.isLoading
                ? null
                : () {
                    if (_smsSent) {
                      setState(() => _phoneStep = 1);
                      return;
                    }
                    context.read<FirebaseAuthCubit>().sendPhoneCode(
                          countryCode: _phoneCountryCode,
                          nationalNumber: _phoneController.text,
                        );
                  },
          ),
        ],
      ),
    );
  }

  Widget _phoneSmsStep(BuildContext context, FirebaseAuthState state) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Código SMS', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _smsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: state.isLoading ? 'Verificando' : 'Confirmar',
            icon: Icons.verified_outlined,
            state: state.isLoading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: state.isLoading
                ? null
                : () => context.read<FirebaseAuthCubit>().confirmPhoneCode(
                      _smsController.text,
                    ),
          ),
        ],
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
              helperText: 'Si lo ingresas, te enviaremos verificación por Firebase.',
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
      children: [
        if (_emailStep == _EmailStep.enterEmail) _emailEnterStep(context, loading),
        if (_emailStep == _EmailStep.enterPassword) _emailPasswordStep(context, loading),
        if (_emailStep == _EmailStep.registerPassword) _emailRegisterPasswordStep(context, loading),
        if (_emailStep == _EmailStep.registerProfile) _emailRegisterProfileStep(context, loading),
      ],
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
            'Si no tienes cuenta, te guiaremos para crearla. Si ya estás registrado, ingresa tu contraseña.',
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
    final subtitle = _lookup?.isLegacyLogin == true
        ? 'Cuenta Ciervo: ingresa tu contraseña habitual.'
        : _lookup?.isFirebaseLogin == true
            ? 'Cuenta verificada con Firebase.'
            : 'Ingresa tu contraseña.';

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
            label: loading ? 'Ingresando' : 'Iniciar sesión',
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
