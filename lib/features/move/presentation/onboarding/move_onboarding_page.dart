import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/permissions/permission_kind.dart';
import '../../../../core/permissions/permission_manager.dart';
import '../../../../core/session/auth_token_claims.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/media/move_media_repository.dart';
import '../../domain/onboarding/move_onboarding_draft.dart';
import '../../domain/onboarding/move_onboarding_enums.dart';
import '../../domain/onboarding/move_onboarding_repository.dart';
import '../../domain/onboarding/move_onboarding_requests.dart';
import '../../domain/onboarding/move_onboarding_status.dart';
import '../../domain/onboarding/move_terms_configuration.dart';
import 'move_onboarding_cubit.dart';

enum MoveOnboardingRouteStage {
  identity,
  license,
  vehicle,
  operations,
  review,
  status;

  String get path => '/move/driver/onboarding/$name';

  MoveOnboardingStageType get draftStage => switch (this) {
    identity => MoveOnboardingStageType.identity,
    license => MoveOnboardingStageType.license,
    _ => MoveOnboardingStageType.vehicleAndOperations,
  };
}

class MoveOnboardingPage extends StatelessWidget {
  const MoveOnboardingPage({required this.stage, super.key});

  final MoveOnboardingRouteStage stage;

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: getIt<SessionManager>().accessToken(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final token = snapshot.data;
      final claims = token == null ? null : AuthTokenClaims.fromJwt(token);
      final userId = claims?.userId?.trim();
      final isClient = claims?.isExplicitClient == true;
      final hasUserId = userId != null && userId.isNotEmpty;
      if (!isClient || !hasUserId) {
        final reason = token == null || token.isEmpty
            ? 'No hay sesión activa.'
            : !isClient
            ? 'Tu token no trae rol Client (1); ahora tiene '
                  '${claims?.role ?? 'sin role'}'
                  '${claims?.accountKind == null ? '' : ' / ${claims!.accountKind}'}.'
            : 'Tu token no trae userId (claim nameid/sub).';
        return _SafeBlock(
          message:
              'MOVE Driver requiere sesión Client (rol 1) con userId. '
              '$reason Cierra sesión e inicia de nuevo para renovar el token.',
          onRelogin: () async {
            await getIt<AuthRepository>().logout();
            if (context.mounted) context.go(AppRoutes.login);
          },
        );
      }
      return BlocProvider(
        create: (_) => MoveOnboardingCubit(
          repository: getIt<MoveOnboardingRepository>(),
          draftStore: getIt<MoveOnboardingDraftStore>(),
          termsRepository: getIt<TermsConfigurationRepository>(),
          uploadImage: getIt<MoveMediaRepository>().uploadImage,
          userId: userId,
        )..load(requestedStage: stage.draftStage),
        child: _MoveOnboardingShell(stage: stage),
      );
    },
  );
}

class _MoveOnboardingShell extends StatefulWidget {
  const _MoveOnboardingShell({required this.stage});

  final MoveOnboardingRouteStage stage;

  @override
  State<_MoveOnboardingShell> createState() => _MoveOnboardingShellState();
}

class _MoveOnboardingShellState extends State<_MoveOnboardingShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MoveOnboardingCubit>().refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MoveOnboardingCubit, MoveOnboardingState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final text = state.errorMessage ?? state.successMessage;
        if (text != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text)));
        }
      },
      builder: (context, state) {
        if (state.loadState == MoveOnboardingLoadState.loading &&
            state.status == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.isBlocked) {
          return _SafeBlock(
            message: state.blockedMessage!,
            onRetry: context.read<MoveOnboardingCubit>().refreshStatus,
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alta MOVE Driver'),
            actions: [
              IconButton(
                tooltip: 'Actualizar estado',
                onPressed: context.read<MoveOnboardingCubit>().refreshStatus,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            children: [
              _ProgressHeader(stage: widget.stage, state: state),
              Expanded(child: _stageBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _stageBody(BuildContext context, MoveOnboardingState state) {
    return switch (widget.stage) {
      MoveOnboardingRouteStage.identity => const _IdentityForm(),
      MoveOnboardingRouteStage.license => const _LicenseForm(),
      MoveOnboardingRouteStage.vehicle => const _VehicleForm(),
      MoveOnboardingRouteStage.operations => const _OperationsForm(),
      MoveOnboardingRouteStage.review => const _ReviewView(),
      MoveOnboardingRouteStage.status => const _StatusView(),
    };
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.stage, required this.state});

  final MoveOnboardingRouteStage stage;
  final MoveOnboardingState state;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _statusLabel(status?.status),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text('${status?.percentage ?? 0}%'),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: (status?.percentage ?? 0) / 100),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MoveOnboardingRouteStage.values
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_stageLabel(item)),
                          selected: item == stage,
                          onSelected: (_) => _goTo(context, item, status),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityForm extends StatefulWidget {
  const _IdentityForm();

  @override
  State<_IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<_IdentityForm> {
  final _key = GlobalKey<FormState>();
  final _firstNames = TextEditingController();
  final _lastNames = TextEditingController();
  final _documentNumber = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _documentType = 'CC';
  String _country = 'CO';
  DateTime? _birthDate;
  bool _accepted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final saved = context.read<MoveOnboardingCubit>().state.draft.countryCode;
    if (saved == 'CO' || saved == 'CL') _country = saved!;
  }

  @override
  void dispose() {
    _firstNames.dispose();
    _lastNames.dispose();
    _documentNumber.dispose();
    _city.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MoveOnboardingCubit>().state;
    final terms = state.terms;
    return Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PendingWarning(status: state.status),
          _field(_firstNames, 'Nombres', required: true),
          _field(_lastNames, 'Apellidos', required: true),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: const InputDecoration(labelText: 'Tipo de documento'),
            items: const [
              DropdownMenuItem(value: 'CC', child: Text('Cédula')),
              DropdownMenuItem(value: 'CE', child: Text('Extranjería')),
              DropdownMenuItem(value: 'PASSPORT', child: Text('Pasaporte')),
              DropdownMenuItem(value: 'RUT', child: Text('RUT')),
            ],
            onChanged: (value) => _documentType = value ?? _documentType,
          ),
          _field(_documentNumber, 'Número de documento', required: true),
          DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: const InputDecoration(labelText: 'País'),
            items: const [
              DropdownMenuItem(value: 'CO', child: Text('Colombia')),
              DropdownMenuItem(value: 'CL', child: Text('Chile')),
            ],
            onChanged: (value) async {
              if (value == null) return;
              setState(() => _country = value);
              await context.read<MoveOnboardingCubit>().selectCountry(value);
            },
          ),
          _field(_city, 'Ciudad', required: true),
          _field(_email, 'Correo (correo o teléfono requerido)'),
          _field(
            _phone,
            'Teléfono internacional',
            keyboardType: TextInputType.phone,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _birthDate == null
                  ? 'Fecha de nacimiento'
                  : _dateLabel(_birthDate!),
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(1940),
                lastDate: DateTime.now().subtract(
                  const Duration(days: 365 * 18),
                ),
                initialDate: DateTime.now().subtract(
                  const Duration(days: 365 * 25),
                ),
              );
              if (date != null) setState(() => _birthDate = date);
            },
          ),
          _AssetPicker(
            assetKey: 'selfie',
            label: 'Selfie de verificación',
            cameraPreferred: true,
          ),
          if (terms != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Términos MOVE ${terms.version}'),
              children: [
                SelectableText(terms.text),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _accepted,
                  title: const Text('Acepto los términos MOVE'),
                  onChanged: (value) =>
                      setState(() => _accepted = value ?? false),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Guardar identidad',
            onPressed: terms == null
                ? null
                : () async {
                    if (!_key.currentState!.validate()) return;
                    final selfie = state.asset('selfie') ?? 0;
                    final birthDate = _birthDate;
                    if (birthDate == null) {
                      _message(context, 'Selecciona tu fecha de nacimiento.');
                      return;
                    }
                    final ok = await context
                        .read<MoveOnboardingCubit>()
                        .saveIdentity(
                          MoveIdentityOnboardingRequest(
                            firstNames: _firstNames.text.trim(),
                            lastNames: _lastNames.text.trim(),
                            documentType: _documentType,
                            documentNumber: _documentNumber.text.trim(),
                            countryCode: _country,
                            city: _city.text.trim(),
                            email: _nullable(_email.text),
                            phone: _nullable(_phone.text),
                            birthDate: birthDate,
                            selfieMediaAssetId: selfie,
                            acceptMoveTerms: _accepted,
                            termsVersion: terms.version,
                            termsContentHash: terms.contentHash,
                          ),
                        );
                    if (ok && context.mounted) {
                      context.go(MoveOnboardingRouteStage.license.path);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _LicenseForm extends StatefulWidget {
  const _LicenseForm();

  @override
  State<_LicenseForm> createState() => _LicenseFormState();
}

class _LicenseFormState extends State<_LicenseForm> {
  final _key = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _licenseClass = TextEditingController();
  final _experience = TextEditingController();
  DateTime? _expiresAt;

  @override
  void dispose() {
    _number.dispose();
    _licenseClass.dispose();
    _experience.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MoveOnboardingCubit>().state;
    final country = state.draft.countryCode ?? 'CO';
    return Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PendingWarning(status: state.status),
          _field(_number, 'Número de licencia', required: true),
          _field(_licenseClass, 'Clase', required: true),
          _field(
            _experience,
            'Años de experiencia (opcional)',
            keyboardType: TextInputType.number,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _expiresAt == null
                  ? 'Vencimiento'
                  : 'Vence ${_dateLabel(_expiresAt!)}',
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (date != null) setState(() => _expiresAt = date);
            },
          ),
          const _AssetPicker(
            assetKey: 'licenseFront',
            label: 'Licencia frente',
          ),
          if (country == 'CO')
            const _AssetPicker(
              assetKey: 'licenseBack',
              label: 'Licencia reverso',
            ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Guardar licencia',
            onPressed: () async {
              if (!_key.currentState!.validate()) return;
              if (_expiresAt == null) {
                _message(context, 'Selecciona el vencimiento.');
                return;
              }
              final ok = await context.read<MoveOnboardingCubit>().saveLicense(
                MoveLicenseOnboardingRequest(
                  number: _number.text.trim(),
                  licenseClass: _licenseClass.text.trim(),
                  expiresAt: _expiresAt!,
                  frontMediaAssetId: state.asset('licenseFront') ?? 0,
                  backMediaAssetId: state.asset('licenseBack'),
                  experienceYears: int.tryParse(_experience.text.trim()),
                ),
                countryCode: country,
              );
              if (ok && context.mounted) {
                context.go(MoveOnboardingRouteStage.vehicle.path);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm();

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _key = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final _plate = TextEditingController();
  final _capacity = TextEditingController(text: '4');
  final _vin = TextEditingController();
  MovePhysicalVehicleType _physical = MovePhysicalVehicleType.car;
  MoveVehicleCategory _category = MoveVehicleCategory.economy;
  final Map<MoveVehicleDocumentType, DateTime?> _expirations = {};
  bool _confirmsFrontPlate = false;

  @override
  void dispose() {
    for (final controller in [
      _brand,
      _model,
      _year,
      _color,
      _plate,
      _capacity,
      _vin,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MoveOnboardingCubit>().state;
    return Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PendingWarning(status: state.status),
          DropdownButtonFormField<MovePhysicalVehicleType>(
            initialValue: _physical,
            decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
            items: MovePhysicalVehicleType.values
                .where((item) => item != MovePhysicalVehicleType.unknown)
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(_enumName(item.name)),
                  ),
                )
                .toList(),
            onChanged: (value) => _physical = value ?? _physical,
          ),
          DropdownButtonFormField<MoveVehicleCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: MoveVehicleCategory.values
                .where((item) => item != MoveVehicleCategory.unknown)
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(_enumName(item.name)),
                  ),
                )
                .toList(),
            onChanged: (value) => _category = value ?? _category,
          ),
          _field(_brand, 'Marca', required: true),
          _field(_model, 'Modelo', required: true),
          _field(
            _year,
            'Año',
            required: true,
            keyboardType: TextInputType.number,
          ),
          _field(_color, 'Color', required: true),
          _field(_plate, 'Placa', required: true),
          _field(
            _capacity,
            'Capacidad de pasajeros',
            required: true,
            keyboardType: TextInputType.number,
          ),
          _field(_vin, 'VIN (opcional, 17 caracteres)'),
          const Divider(height: 32),
          Text('Documentos', style: Theme.of(context).textTheme.titleMedium),
          const Text(
            'Registro y seguro son obligatorios. La revisión técnica depende '
            'del país y año; autorización taxi solo si prestarás taxi.',
          ),
          for (final type in MoveVehicleDocumentType.values.where(
            (item) => item != MoveVehicleDocumentType.unknown,
          ))
            _DocumentPicker(
              type: type,
              expiration: _expirations[type],
              onExpirationChanged: (date) =>
                  setState(() => _expirations[type] = date),
            ),
          const Divider(height: 32),
          Text(
            'Cinco fotos del vehículo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'La foto frontal debe mostrar el frente del vehículo con la placa '
            'claramente legible (revisión Superadmin).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final type in MoveVehiclePhotoType.values.where(
            (item) => item != MoveVehiclePhotoType.unknown,
          ))
            _AssetPicker(
              assetKey: 'vehiclePhoto.${type.name}',
              label: _vehiclePhotoLabel(type),
              cameraPreferred: true,
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmsFrontPlate,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Confirmo que la foto frontal muestra el frente del vehículo '
              'con la placa legible',
            ),
            onChanged: (value) =>
                setState(() => _confirmsFrontPlate = value ?? false),
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Guardar vehículo',
            onPressed: () async {
              if (!_key.currentState!.validate()) return;
              if (!_confirmsFrontPlate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Debés confirmar que la foto frontal muestra la placa legible.',
                    ),
                  ),
                );
                return;
              }
              final documents = <MoveVehicleDocumentInputV2>[
                for (final type in MoveVehicleDocumentType.values)
                  if (type != MoveVehicleDocumentType.unknown &&
                      state.asset('vehicleDocument.${type.name}') != null)
                    MoveVehicleDocumentInputV2(
                      type: type,
                      mediaAssetId: state.asset(
                        'vehicleDocument.${type.name}',
                      )!,
                      expiresAt: _expirations[type],
                    ),
              ];
              final photos = <MoveVehiclePhotoInput>[
                for (final type in MoveVehiclePhotoType.values)
                  if (type != MoveVehiclePhotoType.unknown)
                    MoveVehiclePhotoInput(
                      type: type,
                      mediaAssetId:
                          state.asset('vehiclePhoto.${type.name}') ?? 0,
                    ),
              ];
              final ok = await context.read<MoveOnboardingCubit>().saveVehicle(
                MoveVehicleOnboardingRequest(
                  physicalType: _physical,
                  serviceCategory: _category,
                  brand: _brand.text.trim(),
                  model: _model.text.trim(),
                  year: int.tryParse(_year.text.trim()) ?? 0,
                  color: _color.text.trim(),
                  plate: _plate.text.trim(),
                  passengerCapacity: int.tryParse(_capacity.text.trim()) ?? 0,
                  vin: _nullable(_vin.text),
                  documents: documents,
                  photos: photos,
                  confirmsFrontShowsReadablePlate: _confirmsFrontPlate,
                ),
                countryCode: state.draft.countryCode ?? 'CO',
                services: const [],
              );
              if (ok && context.mounted) {
                context.go(MoveOnboardingRouteStage.operations.path);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  const _DocumentPicker({
    required this.type,
    required this.expiration,
    required this.onExpirationChanged,
  });

  final MoveVehicleDocumentType type;
  final DateTime? expiration;
  final ValueChanged<DateTime> onExpirationChanged;

  @override
  Widget build(BuildContext context) {
    final requiresExpiration = type != MoveVehicleDocumentType.registration;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _AssetPicker(
              assetKey: 'vehicleDocument.${type.name}',
              label: _enumName(type.name),
            ),
            if (requiresExpiration)
              ListTile(
                title: Text(
                  expiration == null
                      ? 'Seleccionar vencimiento'
                      : 'Vence ${_dateLabel(expiration!)}',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) onExpirationChanged(date);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _OperationsForm extends StatefulWidget {
  const _OperationsForm();

  @override
  State<_OperationsForm> createState() => _OperationsFormState();
}

class _OperationsFormState extends State<_OperationsForm> {
  final _key = GlobalKey<FormState>();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _emergencyRelationship = TextEditingController();
  final _languages = TextEditingController(text: 'Español');
  final _schedule = TextEditingController();
  final _radius = TextEditingController();
  final _maxDistance = TextEditingController();
  final Set<MoveServiceType> _services = {MoveServiceType.economy};
  bool _accessible = false;
  bool _pets = false;
  bool _airConditioning = false;
  bool _luggage = true;
  bool _availableNow = true;

  @override
  void dispose() {
    for (final controller in [
      _emergencyName,
      _emergencyPhone,
      _emergencyRelationship,
      _languages,
      _schedule,
      _radius,
      _maxDistance,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MoveOnboardingCubit>().state;
    return Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PendingWarning(status: state.status),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.account_balance_wallet_outlined),
            title: Text('Liquidación: Wallet CIERVO'),
            subtitle: Text(
              'El alta móvil no solicita cuentas bancarias ni tokens externos.',
            ),
          ),
          _field(_emergencyName, 'Contacto de emergencia', required: true),
          _field(
            _emergencyPhone,
            'Teléfono de emergencia (+...)',
            required: true,
            keyboardType: TextInputType.phone,
          ),
          _field(_emergencyRelationship, 'Relación', required: true),
          _field(_languages, 'Idiomas separados por coma'),
          SwitchListTile(
            value: _accessible,
            title: const Text('Accesibilidad'),
            onChanged: (value) => setState(() => _accessible = value),
          ),
          SwitchListTile(
            value: _pets,
            title: const Text('Acepta mascotas'),
            onChanged: (value) => setState(() => _pets = value),
          ),
          SwitchListTile(
            value: _airConditioning,
            title: const Text('Aire acondicionado'),
            onChanged: (value) => setState(() => _airConditioning = value),
          ),
          SwitchListTile(
            value: _luggage,
            title: const Text('Acepta equipaje'),
            onChanged: (value) => setState(() => _luggage = value),
          ),
          SwitchListTile(
            value: _availableNow,
            title: const Text('Disponible ahora'),
            onChanged: (value) => setState(() => _availableNow = value),
          ),
          _field(
            _schedule,
            'Horario JSON opcional, por ejemplo {"lunes":"8-18"}',
          ),
          _field(
            _radius,
            'Radio km (opcional)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _field(
            _maxDistance,
            'Distancia máxima km (opcional)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          Text('Servicios', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 6,
            children: MoveServiceType.values
                .where((item) => item != MoveServiceType.unknown)
                .map(
                  (item) => FilterChip(
                    label: Text(_enumName(item.name)),
                    selected: _services.contains(item),
                    onSelected: (selected) => setState(() {
                      selected ? _services.add(item) : _services.remove(item);
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Guardar operación',
            onPressed: () async {
              if (!_key.currentState!.validate()) return;
              final ok = await context
                  .read<MoveOnboardingCubit>()
                  .saveOperations(
                    MoveOperationsOnboardingRequest(
                      payoutMethod: MovePayoutMethod.wallet,
                      emergencyName: _emergencyName.text.trim(),
                      emergencyPhone: _emergencyPhone.text.trim(),
                      emergencyRelationship: _emergencyRelationship.text.trim(),
                      languages: _languages.text
                          .split(',')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(),
                      accessible: _accessible,
                      pets: _pets,
                      airConditioning: _airConditioning,
                      luggage: _luggage,
                      isAvailableNow: _availableNow,
                      scheduleJson: _nullable(_schedule.text),
                      radiusKm: double.tryParse(_radius.text.trim()),
                      maxDistanceKm: double.tryParse(_maxDistance.text.trim()),
                      services: _services.toList(growable: false),
                    ),
                  );
              if (ok && context.mounted) {
                context.go(MoveOnboardingRouteStage.review.path);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MoveOnboardingCubit>().state;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MoveOnboardingStatusSummary(status: state.status),
        const SizedBox(height: 18),
        _ActionButton(
          label: 'Enviar a revisión',
          onPressed: state.canSubmit
              ? () async {
                  final ok = await context.read<MoveOnboardingCubit>().submit();
                  if (ok && context.mounted) {
                    context.go(MoveOnboardingRouteStage.status.path);
                  }
                }
              : null,
        ),
        if (state.status?.canSubmit != true)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'El backend habilitará el envío cuando todos los requisitos '
              'estén completos.',
            ),
          ),
      ],
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MoveOnboardingCubit>().state;
    return RefreshIndicator(
      onRefresh: context.read<MoveOnboardingCubit>().refreshStatus,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          MoveOnboardingStatusSummary(status: state.status),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: context.read<MoveOnboardingCubit>().refreshStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar estado'),
          ),
        ],
      ),
    );
  }
}

class MoveOnboardingStatusSummary extends StatelessWidget {
  const MoveOnboardingStatusSummary({required this.status, super.key});

  final MoveDriverOnboardingStatus? status;

  @override
  Widget build(BuildContext context) {
    final value = status;
    if (value == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No se pudo cargar el estado de onboarding.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(value.status),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('Progreso ${value.percentage}%'),
                Text(
                  value.canGoOnline
                      ? 'Habilitado por backend para conectarse'
                      : 'Aún no habilitado para conectarse',
                ),
                if (value.maskedDocument != null)
                  Text('Documento: ${value.maskedDocument}'),
                if (value.maskedLicense != null)
                  Text('Licencia: ${value.maskedLicense}'),
                if (value.maskedPlate != null)
                  Text('Placa: ${value.maskedPlate}'),
                if (value.vehicleBrand != null || value.vehicleModel != null)
                  Text(
                    [
                      if (value.vehicleBrand != null) value.vehicleBrand,
                      if (value.vehicleModel != null) value.vehicleModel,
                      if (value.vehicleYear != null) '${value.vehicleYear}',
                      if (value.vehicleColor != null) value.vehicleColor,
                    ].join(' · '),
                  ),
                if (value.vehiclePhotos.isNotEmpty)
                  Text(
                    'Fotos vehículo: ${value.vehiclePhotos.length}'
                    '${value.vehiclePhotos.any((p) => p.isFrontPlatePhoto) ? ' (incluye frontal+placa)' : ''}',
                  ),
                if (value.vinLast4 != null)
                  Text('VIN termina en ${value.vinLast4}'),
                if (value.payoutLast4 != null)
                  Text('Pago termina en ${value.payoutLast4}'),
              ],
            ),
          ),
        ),
        for (final stage in value.stages)
          Card(
            child: ListTile(
              leading: Icon(
                stage.complete ? Icons.check_circle : Icons.pending_outlined,
              ),
              title: Text(
                stage.name.isEmpty ? _enumName(stage.stage.name) : stage.name,
              ),
              subtitle: Text(
                [
                  '${stage.percentage}%',
                  if (stage.missing.isNotEmpty)
                    'Falta: ${stage.missing.join(', ')}',
                  if (stage.reasons.isNotEmpty)
                    'Motivos: ${stage.reasons.join(', ')}',
                ].join('\n'),
              ),
              isThreeLine: stage.missing.isNotEmpty || stage.reasons.isNotEmpty,
            ),
          ),
        if (value.missing.isNotEmpty)
          _MessageCard(title: 'Pendiente', messages: value.missing),
        if (value.reasons.isNotEmpty)
          _MessageCard(title: 'Motivos', messages: value.reasons),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.messages});

  final String title;
  final List<String> messages;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          for (final message in messages) Text('• $message'),
        ],
      ),
    ),
  );
}

class _PendingWarning extends StatelessWidget {
  const _PendingWarning({required this.status});

  final MoveDriverOnboardingStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status?.status != MoveDriverStatus.pendingReview) {
      return const SizedBox.shrink();
    }
    return const Card(
      color: Color(0xfffff3cd),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Tu solicitud está en revisión. Editar puede reiniciar la revisión '
          'de la sección modificada.',
        ),
      ),
    );
  }
}

class _AssetPicker extends StatelessWidget {
  const _AssetPicker({
    required this.assetKey,
    required this.label,
    this.cameraPreferred = false,
  });

  final String assetKey;
  final String label;
  final bool cameraPreferred;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MoveOnboardingCubit>().state;
    final uploaded = state.asset(assetKey) != null;
    final uploading = state.uploadingAsset == assetKey;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(uploaded ? Icons.check_circle : Icons.add_a_photo_outlined),
      title: Text(label),
      subtitle: Text(
        uploading
            ? 'Procesando y subiendo '
                  '${(state.uploadProgress * 100).round()}%'
            : uploaded
            ? 'Cargada'
            : 'Selecciona cámara o galería',
      ),
      trailing: uploading
          ? IconButton(
              tooltip: 'Cancelar carga',
              onPressed: context.read<MoveOnboardingCubit>().cancelUpload,
              icon: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: state.uploadProgress > 0 ? state.uploadProgress : null,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: state.busy ? null : () => _pickImage(context),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(cameraPreferred ? 'Tomar foto ahora' : 'Cámara'),
              subtitle: const Text(
                'El permiso se solicita únicamente para capturar esta imagen.',
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              subtitle: const Text(
                'El permiso se solicita únicamente para elegir esta imagen.',
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final permission = source == ImageSource.camera
        ? AppPermissionKind.camera
        : AppPermissionKind.photos;
    final allowed = await PermissionManager.instance.ensure(
      context,
      permission,
    );
    if (!allowed) {
      if (context.mounted) {
        _message(
          context,
          'Permiso no concedido. Puedes habilitarlo en configuración.',
        );
      }
      return;
    }
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (image == null || !context.mounted) return;
    await context.read<MoveOnboardingCubit>().uploadImage(
      assetKey: assetKey,
      path: image.path,
      fileName: image.name,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<MoveOnboardingCubit>().state.busy;
    return CiervoButton(
      label: label,
      state: busy ? CiervoButtonState.loading : CiervoButtonState.normal,
      onPressed: onPressed,
    );
  }
}

class _SafeBlock extends StatelessWidget {
  const _SafeBlock({
    required this.message,
    this.onRetry,
    this.onRelogin,
  });

  final String message;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRelogin;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MOVE Driver')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRelogin != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => onRelogin!(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión e iniciar de nuevo'),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool required = false,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) => required && (value == null || value.trim().isEmpty)
          ? 'Campo requerido.'
          : null,
    ),
  );
}

Future<void> _goTo(
  BuildContext context,
  MoveOnboardingRouteStage stage,
  MoveDriverOnboardingStatus? status,
) async {
  final editing = {
    MoveOnboardingRouteStage.identity,
    MoveOnboardingRouteStage.license,
    MoveOnboardingRouteStage.vehicle,
    MoveOnboardingRouteStage.operations,
  }.contains(stage);
  if (editing && status?.status == MoveDriverStatus.pendingReview) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar solicitud en revisión'),
        content: const Text(
          'Los cambios pueden reiniciar la revisión de esta sección. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Editar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }
  context.go(stage.path);
}

String _statusLabel(MoveDriverStatus? status) => switch (status) {
  MoveDriverStatus.draft => 'Borrador',
  MoveDriverStatus.pendingReview => 'En revisión',
  MoveDriverStatus.rejected => 'Rechazado',
  MoveDriverStatus.approved => 'Aprobado',
  MoveDriverStatus.suspended => 'Suspendido',
  MoveDriverStatus.blocked => 'Bloqueado',
  _ => 'Estado no disponible',
};

String _stageLabel(MoveOnboardingRouteStage stage) => switch (stage) {
  MoveOnboardingRouteStage.identity => 'Identidad',
  MoveOnboardingRouteStage.license => 'Licencia',
  MoveOnboardingRouteStage.vehicle => 'Vehículo',
  MoveOnboardingRouteStage.operations => 'Operación',
  MoveOnboardingRouteStage.review => 'Revisión',
  MoveOnboardingRouteStage.status => 'Estado',
};

String _vehiclePhotoLabel(MoveVehiclePhotoType type) => switch (type) {
  MoveVehiclePhotoType.front => 'Frontal (placa legible, obligatoria)',
  MoveVehiclePhotoType.rear => 'Trasera',
  MoveVehiclePhotoType.left => 'Lateral izquierdo',
  MoveVehiclePhotoType.right => 'Lateral derecho',
  MoveVehiclePhotoType.interior => 'Interior',
  MoveVehiclePhotoType.unknown => 'Foto',
};

String _enumName(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
