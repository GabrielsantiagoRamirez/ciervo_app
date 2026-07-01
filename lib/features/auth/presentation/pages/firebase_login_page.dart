import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/phone_country.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/firebase_auth_cubit.dart';
import '../cubit/firebase_auth_state.dart';

class FirebaseLoginPage extends StatefulWidget {
  const FirebaseLoginPage({super.key});

  @override
  State<FirebaseLoginPage> createState() => _FirebaseLoginPageState();
}

class _FirebaseLoginPageState extends State<FirebaseLoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _countryCode = CountryRegistration.defaultCountryCode();
  bool _smsSent = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebaseAuthCubit(
        getIt<AuthRepository>(),
        getIt<FirebaseAuthService>(),
        getIt<LocationService>(),
      ),
      child: BlocConsumer<FirebaseAuthCubit, FirebaseAuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.status == FirebaseAuthStatus.codeSent) {
            setState(() => _smsSent = true);
          }
          if (state.status == FirebaseAuthStatus.phoneVerified && state.shouldFirebaseLogin) {
            context.read<FirebaseAuthCubit>().firebaseLoginExisting().then((ok) {
              if (ok && context.mounted) context.go(AppRoutes.root);
            });
          }
          if (state.status == FirebaseAuthStatus.success) {
            context.go(AppRoutes.root);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Iniciar sesión'),
              bottom: TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Teléfono'),
                  Tab(text: 'Correo'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabs,
              children: [
                _phoneTab(context, state),
                _emailTab(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _phoneTab(BuildContext context, FirebaseAuthState state) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _countryCode,
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
                        if (value != null) setState(() => _countryCode = value);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixText: '${PhoneCountry.byCountryCode(_countryCode).dialCode} ',
                ),
              ),
              if (_smsSent) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _smsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Código SMS'),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: state.isLoading
                    ? 'Procesando'
                    : (_smsSent ? 'Ingresar' : 'Enviar código'),
                icon: Icons.login,
                state: state.isLoading
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: state.isLoading
                    ? null
                    : () {
                        final cubit = context.read<FirebaseAuthCubit>();
                        if (_smsSent) {
                          cubit.confirmPhoneCode(_smsController.text);
                        } else {
                          cubit.sendPhoneCode(
                            countryCode: _countryCode,
                            nationalNumber: _phoneController.text,
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emailTab(BuildContext context, FirebaseAuthState state) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: state.isLoading ? 'Ingresando' : 'Iniciar sesión',
                icon: Icons.login,
                state: state.isLoading
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (InputValidators.email(_emailController.text) != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Correo inválido.')),
                          );
                          return;
                        }
                        context.read<FirebaseAuthCubit>().loginWithEmail(
                              email: _emailController.text,
                              password: _passwordController.text,
                            );
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
