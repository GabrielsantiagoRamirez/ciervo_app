import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../data/repositories/kid_auth_repository_impl.dart';
import '../../domain/entities/kid_registration.dart';

class KidRegisterFlowPage extends StatefulWidget {
  const KidRegisterFlowPage({super.key});

  @override
  State<KidRegisterFlowPage> createState() => _KidRegisterFlowPageState();
}

class _KidRegisterFlowPageState extends State<KidRegisterFlowPage> {
  final _pageController = PageController();
  final _guardianCode = TextEditingController();
  final _guardianEmail = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _documentNumber = TextEditingController();
  final _username = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();

  GuardianVerifyResult? _verifiedGuardian;
  DateTime? _birthDate;
  String? _documentType;
  bool _loading = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _pageController.dispose();
    _guardianCode.dispose();
    _guardianEmail.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _documentNumber.dispose();
    _username.dispose();
    _pin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _verifyGuardian() async {
    final email = _guardianEmail.text.trim();
    final code = _guardianCode.text.trim();
    if (email.isEmpty || code.isEmpty) {
      _showError('Ingresa el código CIERVO del tutor y su correo.');
      return;
    }
    setState(() => _loading = true);
    final result = await getIt<KidAuthRepository>().verifyGuardian(
      guardianEmail: email,
      guardianCiervoCode: code,
    );
    if (!mounted) return;
    result.when(
      success: (verified) {
        setState(() {
          _loading = false;
          _verifiedGuardian = verified;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
      failure: (error) {
        setState(() => _loading = false);
        _showError(UserErrorMessage.from(error));
      },
    );
  }

  Future<void> _registerKid() async {
    final guardian = _verifiedGuardian;
    if (guardian == null || _birthDate == null || _documentType == null) {
      _showError('Completa todos los campos.');
      return;
    }
    final ageError = CountryRegistration.validateKidsAge(_birthDate!);
    if (ageError != null) {
      _showError(ageError);
      return;
    }
    if (_pin.text.trim() != _confirmPin.text.trim()) {
      _showError('Los PIN no coinciden.');
      return;
    }
    final date = _birthDate!;
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    setState(() => _loading = true);
    final result = await getIt<KidAuthRepository>().registerKid(
      KidSelfRegisterRequest(
        guardianUserId: guardian.guardianUserId,
        guardianEmail: guardian.guardianEmail.isNotEmpty
            ? guardian.guardianEmail
            : _guardianEmail.text.trim(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        birthDate: isoDate,
        documentType: _documentType!,
        documentNumber: _documentNumber.text.trim(),
        username: _username.text.trim(),
        pin: _pin.text.trim(),
      ),
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
        _showError(UserErrorMessage.from(error));
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<KidDocumentOption> get _documentOptions {
    final guardian = _verifiedGuardian;
    final age = _birthDate == null
        ? 12
        : CountryRegistration.ageFromBirthDate(_birthDate!) ?? 12;
    return CountryRegistration.kidDocumentOptions(
      countryCode: guardian?.countryCode.isNotEmpty == true
          ? guardian!.countryCode
          : 'CO',
      age: age,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta Kids')),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildVerifyStep(context),
          _buildRegisterStep(context),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vincular con tu familia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Ingresa el código CIERVO de tu tutor y su correo electrónico.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _guardianCode,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código CIERVO del tutor',
                  hintText: 'CIERVO-12345678',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _guardianEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo del tutor',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: _loading ? 'Verificando' : 'Continuar',
                icon: Icons.arrow_forward,
                state: _loading
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: _loading ? null : _verifyGuardian,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(AppRoutes.kidLogin),
                child: const Text('Ya tengo cuenta'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterStep(BuildContext context) {
    final guardian = _verifiedGuardian;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (guardian != null)
          CiervoCard(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Familia confirmada'),
              subtitle: Text('Te vincularás con la familia de ${guardian.name}'),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tus datos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _firstName,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _lastName,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ??
                        DateTime.now().subtract(const Duration(days: 365 * 12)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 26)),
                    lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                  );
                  if (selected != null) {
                    setState(() {
                      _birthDate = selected;
                      _documentType = null;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Seleccionar'
                        : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: ValueKey('$_birthDate-${guardian?.countryCode}'),
                initialValue: _documentType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: _documentOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.code,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _documentType = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _documentNumber,
                decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.alternate_email),
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
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    icon: Icon(
                      _obscurePin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirmPin,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Confirmar PIN',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: _loading ? 'Creando cuenta' : 'Crear cuenta',
                icon: Icons.check,
                state: _loading
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: _loading ? null : _registerKid,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
