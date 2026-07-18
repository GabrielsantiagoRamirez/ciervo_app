import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../cubit/move_driver_cubit.dart';
import '../cubit/move_driver_state.dart';

/// Formulario para postularse como conductor MOVE.
class MoveDriverOnboardingPage extends StatefulWidget {
  const MoveDriverOnboardingPage({required this.cubit, super.key});

  final MoveDriverCubit cubit;

  @override
  State<MoveDriverOnboardingPage> createState() =>
      _MoveDriverOnboardingPageState();
}

class _MoveDriverOnboardingPageState extends State<MoveDriverOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  late String _countryCode = CountryRegistration.defaultCountryCode();

  @override
  void initState() {
    super.initState();
    _cityController.text = CountryRegistration.contextForCode(
      _countryCode,
    ).city;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await widget.cubit.apply(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      countryCode: _countryCode,
      city: _cityController.text.trim(),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Ser conductor Ciervo Move')),
        body: BlocConsumer<MoveDriverCubit, MoveDriverState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CiervoCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            'Completa tus datos. Luego registra tu vehículo y '
                            'documentos. Un administrador revisará tu solicitud.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        InputValidators.requiredText(v ?? '', 'tu nombre'),
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        InputValidators.requiredText(v ?? '', 'tu teléfono'),
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _countryCode,
                    decoration: const InputDecoration(
                      labelText: 'País',
                      prefixIcon: Icon(Icons.public_outlined),
                    ),
                    items: CountryRegistration.paymentCountryCodes
                        .map(
                          (code) => DropdownMenuItem(
                            value: code,
                            child: Text(CountryRegistration.countryLabel(code)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _countryCode = value;
                        _cityController.text =
                            CountryRegistration.contextForCode(value).city;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _cityController,
                    validator: (v) =>
                        InputValidators.requiredText(v ?? '', 'tu ciudad'),
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  CiervoButton(
                    label: 'Enviar solicitud',
                    icon: Icons.send_outlined,
                    state: state.actionInProgress
                        ? CiervoButtonState.loading
                        : CiervoButtonState.normal,
                    onPressed: _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
