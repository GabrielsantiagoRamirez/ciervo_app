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

class FirebaseRegisterPage extends StatelessWidget {
  const FirebaseRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebaseAuthCubit(
        getIt<AuthRepository>(),
        getIt<FirebaseAuthService>(),
        getIt<LocationService>(),
      )..captureLocation(),
      child: const _FirebaseRegisterView(),
    );
  }
}

class _FirebaseRegisterView extends StatefulWidget {
  const _FirebaseRegisterView();

  @override
  State<_FirebaseRegisterView> createState() => _FirebaseRegisterViewState();
}

class _FirebaseRegisterViewState extends State<_FirebaseRegisterView> {
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _document = TextEditingController();
  final _city = TextEditingController();
  String _countryCode = CountryRegistration.defaultCountryCode();
  String _documentType = 'CC';
  int _step = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _document.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FirebaseAuthCubit, FirebaseAuthState>(
      listener: (context, state) async {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == FirebaseAuthStatus.codeSent && _step < 1) {
          setState(() => _step = 1);
        }
        if (state.status == FirebaseAuthStatus.phoneVerified) {
          if (state.shouldFirebaseLogin) {
            final ok = await context.read<FirebaseAuthCubit>().firebaseLoginExisting();
            if (ok && context.mounted) context.go(AppRoutes.root);
          } else {
            setState(() => _step = 2);
          }
        }
        if (state.status == FirebaseAuthStatus.success && !state.userExists) {
          if (context.mounted) context.go(AppRoutes.root);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Crear cuenta')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (state.latitude != null)
                CiervoCard(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Ubicación detectada'),
                    subtitle: Text(
                      'Usaremos tu GPS para asignar el país (${state.countryCode}).',
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              if (_step == 0) _phoneStep(context, state),
              if (_step == 1) _smsStep(context, state),
              if (_step == 2) _profileStep(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _phoneStep(BuildContext context, FirebaseAuthState state) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verifica tu teléfono', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const Text('Enviaremos un código SMS con Firebase (no usamos SMS del backend).'),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            value: _countryCode,
            decoration: const InputDecoration(
              labelText: 'País',
              prefixIcon: Icon(Icons.public_outlined),
            ),
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
                    if (value == null) return;
                    setState(() {
                      _countryCode = value;
                      _documentType = CountryRegistration.adultDocumentOptions(value).first.code;
                    });
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
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: state.isLoading ? 'Enviando SMS' : 'Enviar código',
            icon: Icons.sms_outlined,
            state: state.isLoading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: state.isLoading
                ? null
                : () => context.read<FirebaseAuthCubit>().sendPhoneCode(
                      countryCode: _countryCode,
                      nationalNumber: _phoneController.text,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _smsStep(BuildContext context, FirebaseAuthState state) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Código SMS', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _smsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Código de 6 dígitos',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: state.isLoading ? 'Verificando' : 'Confirmar código',
            icon: Icons.verified_outlined,
            state: state.isLoading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: state.isLoading
                ? null
                : () => context.read<FirebaseAuthCubit>().confirmPhoneCode(
                      _smsController.text,
                    ),
          ),
          TextButton(
            onPressed: state.isLoading
                ? null
                : () => context.read<FirebaseAuthCubit>().sendPhoneCode(
                      countryCode: _countryCode,
                      nationalNumber: _phoneController.text,
                      resend: true,
                    ),
            child: const Text('Reenviar código'),
          ),
        ],
      ),
    );
  }

  Widget _profileStep(BuildContext context, FirebaseAuthState state) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Completa tu perfil', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'Apellido'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              helperText: 'Te enviaremos verificación por Firebase.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: _documentType,
            decoration: const InputDecoration(labelText: 'Tipo de documento'),
            items: CountryRegistration.adultDocumentOptions(_countryCode)
                .map((o) => DropdownMenuItem(value: o.code, child: Text(o.label)))
                .toList(),
            onChanged: (v) => setState(() => _documentType = v ?? _documentType),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _document,
            decoration: const InputDecoration(labelText: 'Número de documento'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'Ciudad (opcional)'),
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: state.isLoading ? 'Creando cuenta' : 'Crear cuenta',
            icon: Icons.check,
            state: state.isLoading ? CiervoButtonState.loading : CiervoButtonState.normal,
            onPressed: state.isLoading
                ? null
                : () async {
                    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nombre y apellido son requeridos.')),
                      );
                      return;
                    }
                    if (_email.text.trim().isNotEmpty &&
                        InputValidators.email(_email.text) != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Correo inválido.')),
                      );
                      return;
                    }
                    await context.read<FirebaseAuthCubit>().firebaseRegisterProfile(
                          firstName: _firstName.text,
                          lastName: _lastName.text,
                          email: _email.text,
                          identityDocument: _document.text,
                          documentType: _documentType,
                          city: _city.text,
                        );
                  },
          ),
        ],
      ),
    );
  }
}
